#!/usr/bin/env python3
"""
Compila os 8 templates MJML para HTML preview com dados de exemplo
de uma academia fictícia (Academia Movimento - Unidade Centro).

Uso: python3 compile_previews.py
"""
import os
import re
import subprocess
import sys
from pathlib import Path

LIBRARY_DIR = Path(__file__).parent
PREVIEW_DIR = LIBRARY_DIR / "preview"
MJML_BIN = LIBRARY_DIR / "node_modules" / ".bin" / "mjml"

# Sample data — academia fictícia "Academia Movimento" (Cleiton pode ajustar)
SAMPLE_DATA = {
    "first_name": "Carlos",
    "last_name": "Silva",
    "name": "Carlos Silva",
    "unidade": "Unidade Centro",
    "branch_name": "Unidade Centro",
    "brand.name": "Academia Movimento",
    "brand.color_primary": "#F97316",
    "brand.color_dark": "#0C4A6E",
    "brand.logo_url": "https://placehold.co/240x80/0C4A6E/FFFFFF/png?text=ACADEMIA+MOVIMENTO",
    "brand.address": "Rua das Palmeiras, 123 — Centro, São Paulo/SP",
    "brand.cnpj": "12.345.678/0001-90",
    "brand.whatsapp_url": "https://wa.me/5511999990000",
    "brand.privacy_url": "#",
    "brand.instagram_url": "#",
    "brand.facebook_url": "#",
    "link_agendamento": "#",
    "link_unsubscribe": "#",
    "link_evento": "#",
    "link_oferta": "#",
    "link_indicacao": "#",
    "link_avaliacao": "#",
    "data_evento": "10 de maio, sábado",
    "horario_evento": "09h às 12h",
    "preco_promocional": "R$ 89/mês",
    "preco_normal": "R$ 149/mês",
    "data_limite": "30 de abril",
    "dias_inativo": "45",
    "aniversariante_nome": "Carlos",
    "mes_referencia": "abril/2026",
}


def render_liquid(content: str, data: dict) -> str:
    """Replace Liquid {{ var }} and {{ var | default: 'X' }} with sample data."""
    # Handle {{ var | default: 'value' }} or {{ var | default: "value" }}
    def replace_with_default(match):
        var_name = match.group(1).strip()
        default_val = match.group(2)
        return data.get(var_name, default_val)

    content = re.sub(
        r"\{\{\s*([a-zA-Z0-9_.]+)\s*\|\s*default:\s*['\"]([^'\"]*)['\"]\s*\}\}",
        replace_with_default,
        content,
    )

    # Handle {{ var | upcase }}
    def replace_with_upcase(match):
        var_name = match.group(1).strip()
        return str(data.get(var_name, var_name)).upper()

    content = re.sub(
        r"\{\{\s*([a-zA-Z0-9_.]+)\s*\|\s*upcase\s*\}\}",
        replace_with_upcase,
        content,
    )

    # Handle simple {{ var }}
    def replace_simple(match):
        var_name = match.group(1).strip()
        return str(data.get(var_name, f"[{var_name}]"))

    content = re.sub(
        r"\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}",
        replace_simple,
        content,
    )

    return content


def compile_mjml(mjml_content: str) -> str:
    """Compile MJML string to HTML using local mjml binary."""
    proc = subprocess.run(
        [str(MJML_BIN), "-i", "-s"],
        input=mjml_content,
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"MJML compile failed: {proc.stderr}")
    return proc.stdout


def main():
    PREVIEW_DIR.mkdir(exist_ok=True)
    mjml_files = sorted(LIBRARY_DIR.glob("*.mjml"))

    if not mjml_files:
        print("Nenhum .mjml encontrado.", file=sys.stderr)
        sys.exit(1)

    print(f"Compilando {len(mjml_files)} templates...")
    for mjml_path in mjml_files:
        name = mjml_path.stem
        print(f"  - {name}")
        with open(mjml_path, "r", encoding="utf-8") as f:
            mjml_raw = f.read()

        rendered = render_liquid(mjml_raw, SAMPLE_DATA)
        html = compile_mjml(rendered)

        out_path = PREVIEW_DIR / f"{name}.html"
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(html)

    print(f"OK -> {PREVIEW_DIR}")


if __name__ == "__main__":
    main()
