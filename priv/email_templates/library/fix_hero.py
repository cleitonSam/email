#!/usr/bin/env python3
"""
Substitui o padrão hero buggy:
  <mj-section background-url="X" background-size="cover" ...>
    <mj-column>
      <mj-spacer height="80px" /> x3
    </mj-column>
  </mj-section>

Por uma mj-image fluid que renderiza em qualquer client.
"""
import re
from pathlib import Path

LIB = Path(__file__).parent

# Pattern: encontra mj-section com background-url + 3 spacers
# Captura: a URL do background-url
PATTERN = re.compile(
    r'<mj-section\s+background-url="([^"]+)"[^>]*>\s*'
    r'<mj-column>\s*'
    r'(?:<mj-spacer\s+height="80px"\s*/>\s*){3}'
    r'</mj-column>\s*'
    r'</mj-section>',
    re.MULTILINE | re.DOTALL
)

REPLACEMENT = (
    '<mj-section padding="0">\n'
    '      <mj-column>\n'
    '        <mj-image src="\\1" alt="" padding="0" fluid-on-mobile="true" />\n'
    '      </mj-column>\n'
    '    </mj-section>'
)


def main():
    fixed = 0
    for mjml in sorted(LIB.glob("0[1-8]-*.mjml")):
        content = mjml.read_text(encoding="utf-8")
        new_content, count = PATTERN.subn(REPLACEMENT, content)
        if count > 0:
            mjml.write_text(new_content, encoding="utf-8")
            print(f"  ✓ {mjml.name}: {count} hero(s) substituído(s)")
            fixed += count
        else:
            print(f"  - {mjml.name}: sem mudança")
    print(f"\nTotal: {fixed} hero(s) corrigido(s)")


if __name__ == "__main__":
    main()
