# Docker Monitoring Stack 🐳📊

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)

**Production-ready Docker Compose stack with comprehensive monitoring, logging, and observability tools.**  
A complete solution for deploying and monitoring containerized applications with best practices.

## 🚀 Features

### **📊 Comprehensive Monitoring**
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards and visualization
- **Node Exporter**: System metrics
- **cAdvisor**: Container metrics
- **Alertmanager**: Alert routing and management
- **Loki & Promtail**: Log aggregation

### **🌐 Application Stack**
- **Nginx Frontend**: Modern web interface with real-time dashboard
- **Python Backend**: REST API with health checks
- **PostgreSQL**: Relational database with monitoring
- **Redis**: Caching and session storage
- **Traefik**: Reverse proxy with automatic SSL

### **🛡️ Production Ready**
- **High Availability**: Multi-replica deployments
- **Auto-scaling**: Horizontal pod autoscaling
- **Health Checks**: Comprehensive service monitoring
- **Backup/Restore**: Automated data backup
- **Security**: HTTPS, secrets management, security headers

### **⚙️ DevOps Automation**
- **CI/CD Pipeline**: GitHub Actions automation
- **Infrastructure as Code**: Terraform deployment
- **Makefile**: Simplified management commands
- **Monitoring Scripts**: Automated health checks
- **Alerting**: Proactive alert configuration

## 📋 Quick Start

### **Prerequisites**
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- Linux/macOS/Windows WSL2

### **1. Clone and Setup**
```bash
git clone https://github.com/strizhenko/docker-monitoring-stack.git
cd docker-monitoring-stack
2. Configure Environment
bash
# Copy environment file
cp .env.example .env

# Edit with your configuration
nano .env

# Generate secure passwords
make env-setup
3. Start the Stack
bash
# Start all services
make start

# Or manually
docker-compose up -d
4. Access Services
Dashboard: http://localhost:3000

Grafana: http://localhost:3000/grafana (admin/password-from-.env)

Prometheus: http://localhost:9090

Alertmanager: http://localhost:9093

Traefik Dashboard: http://localhost:8080

🏗️ Architecture
/home/olek/Downloads/docker-monitoring-stack.png


📁 Project Structure
text
docker-monitoring-stack/
├── docker-compose.yml              # Main Docker Compose file
├── docker-compose.override.yml     # Development overrides
├── docker-compose.prod.yml         # Production configuration
├── .env.example                    # Environment variables template
├── Makefile                        # Management commands
├── .github/workflows/              # CI/CD pipelines
│   ├── ci.yml                      # Continuous integration
│   ├── cd.yml                      # Continuous deployment
│   └── security.yml                # Security scanning
├── app/                            # Application code
│   ├── frontend/                   # Nginx web interface
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   ├── index.html
│   │   └── health-check.sh
│   └── backend/                    # Python REST API
│       ├── Dockerfile
│       ├── requirements.txt
│       ├── app.py
│       └── tests/
├── monitoring/                     # Monitoring configuration
│   ├── prometheus.yml             # Prometheus config
│   ├── alert.rules.yml            # Alert rules
│   ├── grafana-dashboards.yml     # Grafana dashboards
│   ├── alertmanager.yml           # Alertmanager config
│   ├── loki-config.yaml           # Loki config
│   ├── promtail-config.yml        # Promtail config
│   └── dashboards/                # Grafana dashboard JSONs
├── configs/                       # Service configurations
│   ├── nginx/                     # Nginx templates
│   ├── traefik/                   # Traefik config
│   ├── postgres/                  # PostgreSQL config
│   └── redis/                     # Redis config
├── scripts/                       # Utility scripts
│   ├── deploy.sh                  # Deployment script
│   ├── backup.sh                  # Backup script
│   ├── monitoring.sh              # Monitoring utilities
│   └── healthcheck.sh             # Health check script
├── terraform/                     # Infrastructure as Code
│   ├── main.tf                    # Main Terraform config
│   ├── variables.tf               # Terraform variables
│   └── outputs.tf                 # Terraform outputs
├── ansible/                       # Configuration management
│   ├── site.yml                   # Main playbook
│   └── inventory.yml              # Ansible inventory
├── docs/                          # Documentation
│   ├── architecture.md            # Architecture details
│   ├── deployment.md              # Deployment guide
│   └── monitoring.md              # Monitoring guide
├── tests/                         # Test files
├── logs/                          # Application logs
├── data/                          # Persistent data
└── backups/                       # Backup files
⚙️ Configuration
Environment Variables
Key variables in .env:

bash
# Application
DOMAIN=your-domain.com
SECRET_KEY=your-secure-secret-key

# Database
POSTGRES_PASSWORD=strong-password-here
REDIS_PASSWORD=another-strong-password

# Monitoring
GRAFANA_PASSWORD=grafana-admin-password
PROMETHEUS_RETENTION=30d

# Email (for alerts)
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=app-specific-password
Service Configuration
Each service has its configuration in the configs/ directory:

Nginx: configs/nginx/ - Web server configuration

PostgreSQL: configs/postgres/ - Database tuning

Redis: configs/redis/ - Cache configuration

Traefik: configs/traefik/ - Reverse proxy rules

🔧 Management Commands
Using Makefile
bash
# Start development environment
make start

# View logs
make logs

# Check service health
make health

# Open Grafana dashboard
make dashboard

# Backup data
make backup

# Scale services
make scale SERVICE=frontend NUM=3

# Clean up everything
make clean
Using Docker Compose Directly
bash
# Start services
docker-compose up -d

# View logs for specific service
docker-compose logs -f frontend

# Execute command in container
docker-compose exec backend python manage.py migrate

# Scale services
docker-compose up -d --scale frontend=3 --no-recreate frontend
📊 Monitoring Dashboard
The stack includes a modern web dashboard accessible at http://localhost:3000:

https://via.placeholder.com/800x400/667eea/ffffff?text=Docker+Monitoring+Dashboard

Features:

Real-time system metrics

Service health status

Active alerts display

Quick access to monitoring tools

Beautiful, responsive design

🚨 Alerting
Pre-configured Alerts
System: High CPU, memory, disk usage

Containers: Container restarts, resource limits

Services: Service downtime, high error rates

Database: Connection limits, slow queries

Business: High request rates, application errors

Alert Channels
Email notifications

Slack webhooks

PagerDuty integration

Webhook endpoints

🔒 Security
Built-in Security Features
HTTPS: Automatic SSL with Let's Encrypt

Secrets Management: Environment variables and Docker secrets

Network Isolation: Separate networks for app and monitoring

Firewall Rules: Traefik middleware for security headers

Authentication: Basic auth for monitoring endpoints

Security Best Practices
Non-root container users

Read-only filesystems where possible

Resource limits and constraints

Regular security updates

Secret rotation procedures

🧪 Testing
Test Suite
bash
# Run all tests
make test

# Run backend tests only
docker-compose run --rm backend pytest

# Run integration tests
./scripts/healthcheck.sh
CI/CD Pipeline
The GitHub Actions pipeline includes:

Docker image security scanning

Configuration validation

Unit and integration tests

Image building and publishing

Deployment previews for PRs

📈 Performance
Resource Optimization
Multi-stage Docker builds for smaller images

Resource limits to prevent runaway containers

Connection pooling for database efficiency

Caching layers for faster deployments

Optimized Prometheus scraping intervals

Scaling
bash
# Scale frontend to 3 instances
make scale SERVICE=frontend NUM=3

# Scale backend to 5 instances
make scale SERVICE=backend NUM=5
🤝 Contributing
Fork the repository

Create feature branch: git checkout -b feature/amazing-feature

Commit changes: git commit -m 'Add amazing feature'

Push to branch: git push origin feature/amazing-feature

Open a Pull Request

Development Setup
bash
# Clone and setup
git clone https://github.com/your-username/docker-monitoring-stack.git
cd docker-monitoring-stack

# Install pre-commit hooks
pre-commit install

# Start development environment
make start
📄 License
This project is licensed under the MIT License - see LICENSE file for details.

👤 Author
Oleksandr Stryzhenko - Infrastructure/Cloud Engineer

GitHub: @strizhenko

LinkedIn: oleksandr-stryzhenko

Email: strizhenkoalexander@gmail.com

🙏 Acknowledgments
Prometheus - Monitoring system

Grafana - Visualization platform

Traefik - Reverse proxy

Docker - Container platform

GitHub Actions - CI/CD platform

📈 Project Status
https://img.shields.io/github/last-commit/strizhenko/docker-monitoring-stack
https://img.shields.io/github/repo-size/strizhenko/docker-monitoring-stack
https://img.shields.io/github/license/strizhenko/docker-monitoring-stack
https://img.shields.io/github/issues/strizhenko/docker-monitoring-stack

Version: 1.0.0
Docker: >= 20.10
Docker Compose: >= 2.0
Platform: Linux, macOS, Windows WSL2

Part of DevOps portfolio. Check out my other projects for complete infrastructure automation solutions.
