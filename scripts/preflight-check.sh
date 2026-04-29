#!/bin/bash

################################################################################
# Fluxo Email MKT - Pre-Deployment Verification Script
#
# This script verifies that all requirements are met before deploying
# to production. Run this before ./deploy.sh
#
# Usage: ./scripts/preflight-check.sh
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env.production"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

check_command() {
    if command -v "$1" &> /dev/null; then
        local version
        version=$("$1" --version 2>/dev/null | head -n1 || echo "unknown")
        check_pass "Command found: $1 ($version)"
    else
        check_fail "Command not found: $1 (install it and try again)"
    fi
}

check_file() {
    if [ -f "$1" ]; then
        check_pass "File exists: $1"
    else
        check_fail "File missing: $1"
    fi
}

check_env_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"

    if [ -z "$var_value" ]; then
        check_fail "Environment variable not set: $var_name"
        return 1
    elif [ "$var_value" = "CHANGE_ME_TO_A_RANDOM_64_CHAR_STRING" ] || \
         [ "$var_value" = "CHANGE_ME_SMTP_HOST" ] || \
         [ "$var_value" = "CHANGE_ME_SMTP_USER" ] || \
         [ "$var_value" = "CHANGE_ME_SMTP_PASSWORD" ]; then
        check_fail "Environment variable not configured: $var_name (still has placeholder value)"
        return 1
    else
        check_pass "Environment variable configured: $var_name"
        return 0
    fi
}

################################################################################
# Preflight Checks
################################################################################

main() {
    print_header "Fluxo Email MKT - Pre-Deployment Verification"

    # 1. System Requirements
    print_header "1. System Requirements"
    check_command "docker"
    check_command "docker-compose"
    check_command "psql"

    # 2. Project Files
    print_header "2. Project Files"
    check_file "$PROJECT_DIR/ops/Dockerfile"
    check_file "$PROJECT_DIR/docker-compose.prod.yml"
    check_file "$PROJECT_DIR/scripts/deploy.sh"
    check_file "$ENV_FILE"

    # 3. Environment Configuration
    print_header "3. Environment Configuration"
    if [ ! -f "$ENV_FILE" ]; then
        check_fail "Configuration file not found: $ENV_FILE"
    else
        check_pass "Configuration file exists: $ENV_FILE"

        # Source the environment file
        set -a
        source "$ENV_FILE"
        set +a

        # Check critical variables
        check_env_var "SECRET_KEY_BASE"
        check_env_var "DB_URL"
        check_env_var "REDIS_URL"
        check_env_var "URL_HOST"
        check_env_var "MAILER_SMTP_HOST"
        check_env_var "MAILER_SMTP_USER"
        check_env_var "MAILER_SMTP_PASSWORD"
        check_env_var "MAILER_SMTP_FROM_EMAIL"

        # Check secret key base length
        if [ ${#SECRET_KEY_BASE} -lt 32 ]; then
            check_fail "SECRET_KEY_BASE is too short (minimum 32 characters)"
        else
            check_pass "SECRET_KEY_BASE has sufficient length (${#SECRET_KEY_BASE} chars)"
        fi
    fi

    # 4. Database Connectivity
    print_header "4. Database Connectivity"
    if [ -n "${DB_URL:-}" ]; then
        # Extract DB connection details from URL
        if [[ $DB_URL =~ postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/([^?]+) ]]; then
            db_user="${BASH_REMATCH[1]}"
            db_pass="${BASH_REMATCH[2]}"
            db_host="${BASH_REMATCH[3]}"
            db_port="${BASH_REMATCH[4]}"
            db_name="${BASH_REMATCH[5]}"

            # Test connection
            if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" \
                    -d postgres -c "SELECT 1" &>/dev/null; then
                check_pass "PostgreSQL connection successful ($db_host:$db_port)"
            else
                check_fail "Cannot connect to PostgreSQL at $db_host:$db_port"
            fi

            # Check if database exists
            if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" \
                    -tc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" | grep -q 1; then
                check_pass "Database '$db_name' exists"
            else
                check_warn "Database '$db_name' does not exist (will be created by deploy script)"
            fi
        else
            check_fail "Invalid DB_URL format: $DB_URL"
        fi
    else
        check_fail "DB_URL not configured"
    fi

    # 5. Redis Connectivity
    print_header "5. Redis Connectivity"
    if [ -n "${REDIS_URL:-}" ]; then
        if command -v redis-cli &> /dev/null; then
            if redis-cli -u "$REDIS_URL" ping &>/dev/null; then
                check_pass "Redis connection successful"
            else
                check_fail "Cannot connect to Redis at $REDIS_URL"
            fi
        else
            check_warn "redis-cli not installed (skipping Redis connectivity check)"
        fi
    else
        check_fail "REDIS_URL not configured"
    fi

    # 6. SMTP Configuration
    print_header "6. SMTP Configuration"
    if [ -z "${MAILER_SMTP_HOST:-}" ]; then
        check_fail "MAILER_SMTP_HOST not configured"
    else
        check_pass "MAILER_SMTP_HOST configured: ${MAILER_SMTP_HOST}"
    fi

    if [ -z "${MAILER_SMTP_USER:-}" ]; then
        check_fail "MAILER_SMTP_USER not configured"
    else
        check_pass "MAILER_SMTP_USER configured"
    fi

    if [ -z "${MAILER_SMTP_PASSWORD:-}" ]; then
        check_fail "MAILER_SMTP_PASSWORD not configured"
    else
        check_pass "MAILER_SMTP_PASSWORD configured"
    fi

    if [ -z "${MAILER_SMTP_FROM_EMAIL:-}" ]; then
        check_fail "MAILER_SMTP_FROM_EMAIL not configured"
    else
        check_pass "MAILER_SMTP_FROM_EMAIL configured: ${MAILER_SMTP_FROM_EMAIL}"
    fi

    # 7. URL Configuration
    print_header "7. URL Configuration"
    if [ -z "${URL_HOST:-}" ]; then
        check_fail "URL_HOST not configured"
    else
        check_pass "URL_HOST configured: ${URL_HOST}"

        # Check if DNS resolves
        if command -v dig &> /dev/null; then
            if dig +short "${URL_HOST}" | grep -q .; then
                check_pass "DNS resolves for ${URL_HOST}"
            else
                check_warn "DNS does not resolve for ${URL_HOST} (may not be registered yet)"
            fi
        else
            check_warn "dig not installed (skipping DNS check)"
        fi
    fi

    # 8. Docker Configuration
    print_header "8. Docker Configuration"

    if docker ps &>/dev/null; then
        check_pass "Docker daemon is running"
    else
        check_fail "Cannot connect to Docker daemon"
    fi

    if docker-compose version &>/dev/null; then
        local dc_version
        dc_version=$(docker-compose version | grep -oP '\d+\.\d+' | head -1)
        check_pass "Docker Compose is available (version $dc_version)"
    else
        check_fail "Docker Compose not available"
    fi

    # Check if required images can be pulled
    if docker pull --quiet elixir:1.18-alpine 2>/dev/null; then
        check_pass "Can pull base images from registry"
    else
        check_warn "Cannot pre-pull base images (build will try on deploy)"
    fi

    # 9. Disk Space
    print_header "9. Disk Space"
    local available_space
    available_space=$(df "$PROJECT_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -gt 5242880 ]; then  # 5GB in KB
        check_pass "Sufficient disk space available ($(numfmt --to=iec $((available_space * 1024)) 2>/dev/null || echo "${available_space}KB"))"
    else
        check_warn "Low disk space available (only $(numfmt --to=iec $((available_space * 1024)) 2>/dev/null || echo "${available_space}KB"))"
    fi

    # 10. Network Configuration
    print_header "10. Network Configuration"

    # Check if port 4001 is available
    if ! netstat -tuln 2>/dev/null | grep -q ':4001'; then
        check_pass "Port 4001 is available"
    else
        check_warn "Port 4001 is already in use (may conflict with Docker)"
    fi

    # Check internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        check_pass "Internet connectivity confirmed"
    else
        check_warn "Cannot reach internet (may affect Docker image pulls)"
    fi

    # Summary
    print_header "Summary"
    local total_checks=$((CHECKS_PASSED + CHECKS_FAILED))

    echo "Checks Passed: ${GREEN}$CHECKS_PASSED${NC}"
    echo "Checks Failed: ${RED}$CHECKS_FAILED${NC}"
    echo "Warnings: ${YELLOW}$WARNINGS${NC}"

    if [ $CHECKS_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ All preflight checks passed!${NC}"
        echo ""
        echo "You can now run: ${BLUE}./scripts/deploy.sh${NC}"
        echo ""
        return 0
    else
        echo ""
        echo -e "${RED}✗ Some checks failed. Please fix the issues above before deploying.${NC}"
        echo ""
        echo "For help, see: ${BLUE}DEPLOYMENT.md${NC}"
        echo ""
        return 1
    fi
}

# Run main function
main
