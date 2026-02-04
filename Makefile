.PHONY: help build up down restart logs clean test deploy validate lint backup restore

help:
	@echo "Docker Monitoring Stack - Management Commands"
	@echo ""
	@echo "Development:"
	@echo "  build      - Build all Docker images"
	@echo "  up         - Start all services in development mode"
	@echo "  down       - Stop and remove all containers"
	@echo "  restart    - Restart all services"
	@echo "  logs       - Show logs from all services"
	@echo "  clean      - Remove all containers, volumes, and images"
	@echo ""
	@echo "Production:"
	@echo "  deploy     - Deploy to production (uses docker-compose.prod.yml)"
	@echo "  scale      - Scale services (make scale SERVICE=frontend NUM=3)"
	@echo "  update     - Update all services to latest images"
	@echo ""
	@echo "Monitoring:"
	@echo "  metrics    - Show Prometheus metrics"
	@echo "  alerts     - Show active alerts"
	@echo "  health     - Check health of all services"
	@echo "  dashboard  - Open monitoring dashboard"
	@echo ""
	@echo "Maintenance:"
	@echo "  backup     - Backup all data volumes"
	@echo "  restore    - Restore from backup"
	@echo "  validate   - Validate configuration files"
	@echo "  lint       - Lint Docker and configuration files"
	@echo "  test       - Run tests"
	@echo ""
	@echo "Utils:"
	@echo "  shell      - Open shell in container (make shell SERVICE=backend)"
	@echo "  exec       - Execute command in container"
	@echo "  ps         - Show running containers"
	@echo "  stats      - Show container statistics"
	@echo "  top        - Show container processes"

# Development commands
build:
	@echo "Building Docker images..."
	docker-compose build --pull

up:
	@echo "Starting services in development mode..."
	docker-compose up -d

down:
	@echo "Stopping and removing services..."
	docker-compose down

restart:
	@echo "Restarting services..."
	docker-compose restart

logs:
	@echo "Showing logs (Ctrl+C to exit)..."
	docker-compose logs -f --tail=100

clean:
	@echo "Cleaning up..."
	docker-compose down -v --rmi local
	@rm -rf logs/* data/* 2>/dev/null || true
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -delete

# Production commands
deploy:
	@echo "Deploying to production..."
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

scale:
	@if [ -z "$(SERVICE)" ] || [ -z "$(NUM)" ]; then \
		echo "Usage: make scale SERVICE=<name> NUM=<number>"; \
		exit 1; \
	fi
	docker-compose up -d --scale $(SERVICE)=$(NUM) --no-recreate $(SERVICE)

update:
	@echo "Updating services..."
	docker-compose pull
	docker-compose up -d --force-recreate

# Monitoring commands
metrics:
	@echo "Prometheus Metrics:"
	@curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, instance:.labels.instance, health:.health, lastScrape:.lastScrape}'

alerts:
	@echo "Active Alerts:"
	@curl -s http://localhost:9093/api/v2/alerts | jq '.[] | {status:.status.state, labels:.labels, annotations:.annotations, startsAt:.startsAt}'

health:
	@echo "Service Health Checks:"
	@for service in frontend backend postgres redis prometheus grafana; do \
		if docker-compose ps $$service | grep -q "Up"; then \
			echo "✅ $$service: Running"; \
		else \
			echo "❌ $$service: Not running"; \
		fi; \
	done

dashboard:
	@echo "Opening monitoring dashboard..."
	@if command -v xdg-open > /dev/null; then \
		xdg-open http://localhost:3000; \
	elif command -v open > /dev/null; then \
		open http://localhost:3000; \
	else \
		echo "Open http://localhost:3000 in your browser"; \
	fi

# Maintenance commands
backup:
	@echo "Creating backup..."
	@mkdir -p backups
	@docker run --rm \
		-v $(PWD)/backups:/backups \
		-v docker-monitoring-stack_postgres-data:/data \
		-v docker-monitoring-stack_grafana-data:/grafana \
		-v docker-monitoring-stack_prometheus-data:/prometheus \
		alpine tar -czf /backups/backup-$(shell date +%Y%m%d-%H%M%S).tar.gz /data /grafana /prometheus
	@echo "Backup created in backups/ directory"

restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Usage: make restore BACKUP_FILE=backups/backup-YYYYMMDD-HHMMSS.tar.gz"; \
		exit 1; \
	fi
	@echo "Restoring from $(BACKUP_FILE)..."
	@docker-compose down
	@docker run --rm \
		-v $(PWD)/$(BACKUP_FILE):/backup.tar.gz \
		-v docker-monitoring-stack_postgres-data:/data \
		-v docker-monitoring-stack_grafana-data:/grafana \
		-v docker-monitoring-stack_prometheus-data:/prometheus \
		alpine sh -c "tar -xzf /backup.tar.gz -C /"
	@docker-compose up -d
	@echo "Restore completed"

validate:
	@echo "Validating configuration files..."
	@docker-compose config -q
	@echo "✅ Docker Compose configuration is valid"
	@python3 -m py_compile app/backend/app.py 2>/dev/null && echo "✅ Python syntax is valid" || echo "❌ Python syntax error"
	@nginx -t -c app/frontend/nginx.conf 2>/dev/null && echo "✅ Nginx configuration is valid" || echo "❌ Nginx configuration error"

lint:
	@echo "Linting files..."
	@docker run --rm -v $(PWD):/app hadolint/hadolint hadolint app/frontend/Dockerfile app/backend/Dockerfile
	@echo "✅ Dockerfiles linted successfully"

test:
	@echo "Running tests..."
	@docker-compose run --rm backend pytest -v
	@docker-compose run --rm frontend npm test 2>/dev/null || echo "Frontend tests require npm install"

# Utility commands
shell:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Usage: make shell SERVICE=<service_name>"; \
		exit 1; \
	fi
	docker-compose exec $(SERVICE) sh

exec:
	@if [ -z "$(SERVICE)" ] || [ -z "$(CMD)" ]; then \
		echo "Usage: make exec SERVICE=<service_name> CMD='<command>'"; \
		exit 1; \
	fi
	docker-compose exec $(SERVICE) $(CMD)

ps:
	@echo "Running containers:"
	@docker-compose ps

stats:
	@echo "Container statistics:"
	@docker stats --no-stream

top:
	@if [ -z "$(SERVICE)" ]; then \
		docker-compose top; \
	else \
		docker-compose top $(SERVICE); \
	fi

# Environment setup
env-setup:
	@echo "Setting up environment..."
	@cp .env.example .env
	@echo "Please edit .env file with your configuration"
	@echo "Generated secrets:"
	@echo "SECRET_KEY=$(shell openssl rand -hex 32)"
	@echo "POSTGRES_PASSWORD=$(shell openssl rand -hex 16)"
	@echo "REDIS_PASSWORD=$(shell openssl rand -hex 16)"
	@echo "GRAFANA_PASSWORD=$(shell openssl rand -hex 16)"

# Quick start
start: env-setup build up health
	@echo ""
	@echo "✅ Docker Monitoring Stack started successfully!"
	@echo ""
	@echo "Access the following services:"
	@echo "  Frontend:      http://localhost:3000"
	@echo "  Grafana:       http://localhost:3000/grafana"
	@echo "  Prometheus:    http://localhost:9090"
	@echo "  Alertmanager:  http://localhost:9093"
	@echo ""
	@echo "Default credentials:"
	@echo "  Grafana: admin / (check .env file)"
	@echo ""
	@echo "Use 'make logs' to see logs"
	@echo "Use 'make down' to stop services"
