#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Load environment
load_environment() {
    local env_file="${1:-.env}"
    
    if [ -f "$env_file" ]; then
        log_info "Loading environment from $env_file"
        set -a
        source "$env_file"
        set +a
    else
        log_warn "Environment file $env_file not found"
        if [ "$env_file" = ".env" ]; then
            log_info "Creating .env from example"
            cp .env.example .env
            log_warn "Please edit .env file with your configuration"
            exit 1
        fi
    fi
}

# Validate configuration
validate_config() {
    log_info "Validating configuration..."
    
    # Validate Docker Compose configuration
    if ! docker-compose config -q; then
        log_error "Docker Compose configuration is invalid"
        exit 1
    fi
    
    # Check required environment variables
    local required_vars=(
        "POSTGRES_PASSWORD"
        "REDIS_PASSWORD"
        "GRAFANA_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_warn "Environment variable $var is not set"
        fi
    done
    
    log_info "Configuration validation passed"
}

# Backup existing data
backup_existing() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    log_info "Creating backup in $backup_dir..."
    mkdir -p "$backup_dir"
    
    # Backup Docker Compose files
    cp docker-compose.yml docker-compose.prod.yml .env "$backup_dir/" 2>/dev/null || true
    
    # Backup volumes if they exist
    if docker volume ls | grep -q "docker-monitoring-stack"; then
        log_info "Backing up Docker volumes..."
        
        # Create volume backup script
        cat > "$backup_dir/backup-volumes.sh" << 'SCRIPT'
#!/bin/bash
set -e

volumes=(
    "docker-monitoring-stack_postgres-data"
    "docker-monitoring-stack_grafana-data"
    "docker-monitoring-stack_prometheus-data"
    "docker-monitoring-stack_alertmanager-data"
    "docker-monitoring-stack_loki-data"
)

for volume in "${volumes[@]}"; do
    if docker volume inspect "$volume" &> /dev/null; then
        echo "Backing up volume: $volume"
        docker run --rm \
            -v "$volume:/source" \
            -v "$(pwd):/backup" \
            alpine tar -czf "/backup/${volume}.tar.gz" -C /source .
    fi
done
SCRIPT
        
        chmod +x "$backup_dir/backup-volumes.sh"
        cd "$backup_dir" && ./backup-volumes.sh && cd - > /dev/null
    fi
    
    log_info "Backup completed"
}

# Pull latest images
pull_images() {
    log_info "Pulling latest Docker images..."
    docker-compose pull --ignore-pull-failures
}

# Build images
build_images() {
    log_info "Building Docker images..."
    
    # Build with BuildKit for better caching
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    docker-compose build --pull --no-cache --parallel
}

# Stop existing services
stop_services() {
    log_info "Stopping existing services..."
    
    if docker-compose ps --services | grep -q "."; then
        docker-compose down --remove-orphans
        sleep 5
    else
        log_info "No running services found"
    fi
}

# Deploy services
deploy_services() {
    local compose_files=("docker-compose.yml")
    
    # Add production override if exists
    if [ -f "docker-compose.prod.yml" ]; then
        compose_files+=("docker-compose.prod.yml")
    fi
    
    log_info "Deploying services..."
    
    # Build command
    local cmd="docker-compose"
    for file in "${compose_files[@]}"; do
        cmd="$cmd -f $file"
    done
    cmd="$cmd up -d --remove-orphans"
    
    # Execute
    eval "$cmd"
}

# Wait for services to be healthy
wait_for_services() {
    local timeout=300  # 5 minutes
    local start_time=$(date +%s)
    
    log_info "Waiting for services to become healthy..."
    
    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        local all_healthy=true
        
        # Check each service
        for service in $(docker-compose ps --services); do
            local status=$(docker-compose ps -q "$service" | xargs docker inspect -f '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
            
            if [ "$status" = "healthy" ]; then
                log_info "✅ $service is healthy"
            elif [ "$status" = "starting" ]; then
                log_info "⏳ $service is starting..."
                all_healthy=false
            elif [ "$status" = "unhealthy" ]; then
                log_error "❌ $service is unhealthy"
                docker-compose logs "$service" --tail=20
                all_healthy=false
            else
                # Service doesn't have healthcheck
                local running=$(docker-compose ps -q "$service" | xargs docker inspect -f '{{.State.Running}}' 2>/dev/null || echo "false")
                if [ "$running" = "true" ]; then
                    log_info "✅ $service is running (no healthcheck)"
                else
                    log_warn "⏳ $service is not running"
                    all_healthy=false
                fi
            fi
        done
        
        if [ "$all_healthy" = true ]; then
            log_info "All services are healthy!"
            return 0
        fi
        
        sleep 10
    done
    
    log_error "Timeout waiting for services to become healthy"
    return 1
}

# Perform post-deployment checks
post_deployment_checks() {
    log_info "Performing post-deployment checks..."
    
    # Check if frontend is accessible
    local frontend_url="http://localhost:${FRONTEND_PORT:-3000}"
    if curl -s -f --retry 3 --retry-delay 5 "$frontend_url/health" > /dev/null; then
        log_info "✅ Frontend is accessible at $frontend_url"
    else
        log_error "❌ Frontend is not accessible"
        return 1
    fi
    
    # Check if Grafana is accessible
    local grafana_url="http://localhost:${GRAFANA_PORT:-3000}/grafana/api/health"
    if curl -s -f --retry 3 --retry-delay 5 "$grafana_url" > /dev/null; then
        log_info "✅ Grafana is accessible"
    else
        log_warn "⚠️  Grafana is not accessible"
    fi
    
    # Check if Prometheus is scraping
    sleep 30  # Give Prometheus time to start scraping
    if curl -s "http://localhost:${PROMETHEUS_PORT:-9090}/api/v1/targets" | grep -q '"health":"up"'; then
        log_info "✅ Prometheus is scraping metrics"
    else
        log_warn "⚠️  Prometheus is not scraping metrics"
    fi
    
    return 0
}

# Display deployment summary
display_summary() {
    log_info "=== Deployment Summary ==="
    log_info "Environment: ${NODE_ENV:-production}"
    log_info "Services deployed: $(docker-compose ps --services | wc -l)"
    log_info ""
    log_info "Access URLs:"
    log_info "  Dashboard:    http://localhost:${FRONTEND_PORT:-3000}"
    log_info "  Grafana:      http://localhost:${GRAFANA_PORT:-3000}/grafana"
    log_info "  Prometheus:   http://localhost:${PROMETHEUS_PORT:-9090}"
    log_info "  Alertmanager: http://localhost:${ALERTMANAGER_PORT:-9093}"
    log_info ""
    log_info "Grafana credentials:"
    log_info "  Username: admin"
    log_info "  Password: ${GRAFANA_PASSWORD:-check .env file}"
    log_info ""
    log_info "Useful commands:"
    log_info "  View logs:        docker-compose logs -f"
    log_info "  Check health:     docker-compose ps"
    log_info "  Stop services:    docker-compose down"
    log_info "  Backup data:      make backup"
    log_info ""
    log_info "Deployment completed successfully! 🎉"
}

# Main deployment function
main() {
    local environment="${1:-production}"
    local env_file=".env.${environment}"
    
    log_info "Starting deployment to $environment environment..."
    
    # Load environment specific file if exists, otherwise use default
    if [ -f "$env_file" ]; then
        load_environment "$env_file"
    else
        load_environment ".env"
    fi
    
    check_prerequisites
    validate_config
    
    # Ask for confirmation in production
    if [ "$environment" = "production" ]; then
        read -p "Are you sure you want to deploy to production? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    backup_existing
    pull_images
    build_images
    stop_services
    deploy_services
    wait_for_services
    post_deployment_checks
    display_summary
}

# Handle script arguments
case "${1:-}" in
    "production")
        main "production"
        ;;
    "staging")
        main "staging"
        ;;
    "development")
        main "development"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [environment]"
        echo ""
        echo "Environments:"
        echo "  production   Deploy to production (default)"
        echo "  staging      Deploy to staging"
        echo "  development  Deploy to development"
        echo "  help         Show this help message"
        ;;
    *)
        main "production"
        ;;
esac
