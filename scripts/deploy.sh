#!/bin/bash

################################################################################
# Fluxo Email MKT - Production Deployment Script
#
# This script handles deployment of the Keila/Fluxo Email Marketing Platform
# to a VPS with the following steps:
#   1. Validates .env.production exists
#   2. Creates the database if it doesn't exist
#   3. Builds and starts Docker containers
#   4. Runs database migrations
#   5. Shows application logs
#
# Usage: ./scripts/deploy.sh [up|down|logs|migrate|restart]
# Default action: up (deploy and start)
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env.production"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.prod.yml"
CONTAINER_NAME="fluxo-emailmkt-app"
SERVICE_NAME="fluxo-emailmkt"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================================================${NC}\n"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command not found: $1"
        exit 1
    fi
}

################################################################################
# Validation Functions
################################################################################

validate_environment() {
    print_header "Validating Environment"

    # Check required commands
    log_info "Checking required commands..."
    check_command "docker"
    check_command "docker-compose"
    check_command "psql"
    log_success "All required commands found"

    # Check .env.production exists
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env.production not found at $ENV_FILE"
        log_info "Please create the file and configure it with your actual values"
        exit 1
    fi
    log_success "Configuration file found: $ENV_FILE"

    # Check docker-compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "docker-compose.prod.yml not found at $COMPOSE_FILE"
        exit 1
    fi
    log_success "Docker Compose file found: $COMPOSE_FILE"

    # Load environment variables
    log_info "Loading environment variables..."
    set -a
    source "$ENV_FILE"
    set +a

    # Validate critical variables
    log_info "Validating critical configuration..."
    if [ -z "${DB_URL:-}" ]; then
        log_error "DB_URL not set in .env.production"
        exit 1
    fi
    if [ -z "${URL_HOST:-}" ]; then
        log_error "URL_HOST not set in .env.production"
        exit 1
    fi
    if [ -z "${SECRET_KEY_BASE:-}" ] || [ "${SECRET_KEY_BASE}" = "CHANGE_ME_TO_A_RANDOM_64_CHAR_STRING" ]; then
        log_error "SECRET_KEY_BASE is not properly configured"
        exit 1
    fi
    log_success "Configuration validation passed"
}

################################################################################
# Database Functions
################################################################################

create_database() {
    print_header "Setting up Database"

    log_info "Extracting database connection details..."

    # Parse PostgreSQL connection string
    # Format: postgres://user:password@host:port/database
    if [[ $DB_URL =~ postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/([^?]+) ]]; then
        db_user="${BASH_REMATCH[1]}"
        db_password="${BASH_REMATCH[2]}"
        db_host="${BASH_REMATCH[3]}"
        db_port="${BASH_REMATCH[4]}"
        db_name="${BASH_REMATCH[5]}"
    else
        log_error "Invalid DB_URL format. Expected: postgres://user:password@host:port/database"
        exit 1
    fi

    log_info "Database connection details:"
    log_info "  Host: $db_host"
    log_info "  Port: $db_port"
    log_info "  User: $db_user"
    log_info "  Database: $db_name"

    log_info "Attempting to create database '$db_name' if it doesn't exist..."

    # Create database if it doesn't exist
    PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" \
        -tc "SELECT 1 FROM pg_database WHERE datname = '$db_name'" | grep -q 1 || \
        PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" \
        -c "CREATE DATABASE $db_name;"

    if [ $? -eq 0 ]; then
        log_success "Database '$db_name' is ready"
    else
        log_warn "Could not verify database creation. Continuing anyway..."
    fi
}

################################################################################
# Docker Functions
################################################################################

build_images() {
    print_header "Building Docker Images"

    log_info "Building Fluxo Email MKT image..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build --no-cache

    if [ $? -eq 0 ]; then
        log_success "Docker images built successfully"
    else
        log_error "Failed to build Docker images"
        exit 1
    fi
}

start_containers() {
    print_header "Starting Docker Containers"

    log_info "Starting services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

    if [ $? -eq 0 ]; then
        log_success "Containers started successfully"
    else
        log_error "Failed to start containers"
        exit 1
    fi

    # Wait for application to be healthy
    log_info "Waiting for application to be healthy (up to 60 seconds)..."
    sleep 5

    local attempt=0
    local max_attempts=12

    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "$CONTAINER_NAME"; then
            local health_status=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
            if [ "$health_status" = "healthy" ]; then
                log_success "Application is healthy"
                break
            fi
        fi
        attempt=$((attempt + 1))
        if [ $attempt -lt $max_attempts ]; then
            echo -n "."
            sleep 5
        fi
    done

    if [ $attempt -eq $max_attempts ]; then
        log_warn "Health check timed out or failed, but continuing..."
    fi
}

stop_containers() {
    print_header "Stopping Docker Containers"

    log_info "Stopping services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down

    if [ $? -eq 0 ]; then
        log_success "Containers stopped successfully"
    else
        log_error "Failed to stop containers"
        exit 1
    fi
}

restart_containers() {
    print_header "Restarting Docker Containers"

    log_info "Restarting services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" restart

    if [ $? -eq 0 ]; then
        log_success "Containers restarted successfully"
    else
        log_error "Failed to restart containers"
        exit 1
    fi
}

################################################################################
# Migration Functions
################################################################################

run_migrations() {
    print_header "Running Database Migrations"

    log_info "Waiting for database connection (up to 30 seconds)..."
    sleep 3

    log_info "Running Ecto migrations..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T "$SERVICE_NAME" \
        /opt/app/bin/keila eval "Keila.Release.migrate()"

    if [ $? -eq 0 ]; then
        log_success "Database migrations completed successfully"
    else
        log_error "Database migrations failed"
        exit 1
    fi
}

################################################################################
# Logging Functions
################################################################################

show_logs() {
    print_header "Application Logs (Follow Mode)"
    log_info "Press Ctrl+C to exit"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$SERVICE_NAME"
}

show_status() {
    print_header "Container Status"
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
}

################################################################################
# Main Deployment Function
################################################################################

deploy() {
    validate_environment
    create_database
    build_images
    start_containers
    run_migrations
    show_status

    print_header "Deployment Complete!"
    log_success "Fluxo Email MKT is running at: https://${URL_HOST}"
    log_info "View logs with: ./scripts/deploy.sh logs"
    log_info "Restart with: ./scripts/deploy.sh restart"
    log_info "Stop with: ./scripts/deploy.sh down"
}

################################################################################
# Command Router
################################################################################

main() {
    local action="${1:-up}"

    case "$action" in
        up)
            deploy
            ;;
        down)
            validate_environment
            stop_containers
            ;;
        restart)
            validate_environment
            restart_containers
            ;;
        logs)
            validate_environment
            show_logs
            ;;
        migrate)
            validate_environment
            run_migrations
            ;;
        status)
            validate_environment
            show_status
            ;;
        help)
            cat << EOF
Fluxo Email MKT Deployment Script

Usage: ./scripts/deploy.sh [COMMAND]

Commands:
  up          Deploy and start the application (default)
  down        Stop and remove containers
  restart     Restart running containers
  logs        Show application logs (follow mode)
  migrate     Run database migrations
  status      Show container status
  help        Display this help message

Examples:
  ./scripts/deploy.sh              # Deploy and start
  ./scripts/deploy.sh logs         # View logs
  ./scripts/deploy.sh restart      # Restart the app
  ./scripts/deploy.sh down         # Stop the app

Configuration:
  Edit .env.production before running deploy

Requirements:
  - Docker and Docker Compose
  - PostgreSQL client tools (psql)
  - Network access to external PostgreSQL and Redis servers

EOF
            ;;
        *)
            log_error "Unknown command: $action"
            echo "Run './scripts/deploy.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
