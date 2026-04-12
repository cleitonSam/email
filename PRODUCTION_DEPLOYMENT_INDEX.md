# Fluxo Email MKT - Production Deployment Package

## Overview

This package contains production-ready deployment files for **Fluxo Email MKT** (Keila email marketing platform) using Docker Compose with external PostgreSQL and Redis databases.

**Package Created:** April 12, 2026  
**For:** Deployment to VPS with existing infrastructure at `server.fluxodigitaltech.com.br`

---

## Quick Navigation

### For Operations Teams
1. **Start here:** [`PRODUCTION_README.md`](./PRODUCTION_README.md) - Quick reference (5 min read)
2. **Deploy:** Run `./scripts/preflight-check.sh` then `./scripts/deploy.sh`
3. **Troubleshoot:** See PRODUCTION_README.md troubleshooting section

### For Engineers
1. **Full guide:** [`DEPLOYMENT.md`](./DEPLOYMENT.md) - Complete documentation
2. **Configure:** Edit `.env.production` with your SMTP and secrets
3. **Understand:** Network architecture and configuration details

### For DevOps
1. **Architecture:** See network diagram in DEPLOYMENT.md
2. **Scripts:** Review `scripts/deploy.sh` and `scripts/preflight-check.sh`
3. **Infrastructure:** Database/Redis already configured, see config notes below

---

## Files in This Package

### Docker Configuration
- **`docker-compose.prod.yml`** (2.9 KB)
  - Production Docker Compose configuration
  - Uses external PostgreSQL and Redis
  - Includes health checks, auto-restart, volume persistence
  - Port mapping: 4001 (host) → 4000 (container)

### Environment Configuration
- **`.env.production`** (4.6 KB)
  - Complete environment template with all required variables
  - Pre-filled with database/Redis credentials
  - Requires configuration: SECRET_KEY_BASE, SMTP settings
  - Comprehensive inline documentation

### Deployment Scripts
- **`scripts/deploy.sh`** (11 KB)
  - Automated deployment orchestration
  - Commands: `up`, `down`, `restart`, `logs`, `migrate`, `status`, `help`
  - Validates environment, creates database, builds images, runs migrations
  - Color-coded output, error handling

- **`scripts/preflight-check.sh`** (11 KB)
  - Pre-deployment verification
  - Checks system requirements, connectivity, configuration
  - Must run before deploy.sh
  - Prevents deployment errors

### Documentation
- **`PRODUCTION_README.md`** (8 KB)
  - Quick reference for production deployment
  - Files overview, quick start, common tasks
  - Security checklist, troubleshooting tips

- **`DEPLOYMENT.md`** (14 KB)
  - Complete deployment guide and reference
  - Prerequisites, step-by-step instructions
  - Network architecture, reverse proxy setup
  - Backup/recovery, monitoring, security

- **`PRODUCTION_SETUP_SUMMARY.txt`** (20 KB)
  - Detailed summary of all components
  - Infrastructure overview, configuration reference
  - Common operations, troubleshooting quick reference

---

## Infrastructure Overview

```
External Services (Shared)
├── PostgreSQL: server.fluxodigitaltech.com.br:5440
│   └── Database: fluxo_emailmkt (create before deploy)
├── Redis: server.fluxodigitaltech.com.br:6379
├── SMTP: Your email provider

Docker Containers (This Deployment)
├── fluxo-emailmkt (Keila app, port 4001)
├── redis (local cache, port 6379 internal)
├── volumes:
│   ├── fluxo_emailmkt_uploads
│   └── fluxo_emailmkt_redis
└── network: fluxo_emailmkt_network

Host/Reverse Proxy
└── Port 80/443 (nginx/caddy) → Port 4001 (app)
```

---

## Getting Started (5 Steps)

### Step 1: Pre-Flight Checks
```bash
./scripts/preflight-check.sh
```
Verifies all requirements are met before deployment.

### Step 2: Configure Environment
```bash
nano .env.production
```
**Update these values:**
- `SECRET_KEY_BASE=<generate: openssl rand -base64 32>`
- `MAILER_SMTP_HOST=your-smtp-server`
- `MAILER_SMTP_USER=your-username`
- `MAILER_SMTP_PASSWORD=your-password`
- `MAILER_SMTP_FROM_EMAIL=noreply@emailmkt.fluxodigitaltech.com.br`

### Step 3: Create Database
```bash
psql -h server.fluxodigitaltech.com.br -p 5440 -U postgres
postgres=# CREATE DATABASE fluxo_emailmkt;
postgres=# \q
```

### Step 4: Deploy
```bash
./scripts/deploy.sh
```
The script will:
1. Validate configuration
2. Build Docker images
3. Start containers
4. Run migrations
5. Show status

### Step 5: Configure Reverse Proxy
Point your domain (emailmkt.fluxodigitaltech.com.br) to `localhost:4001` with HTTPS.

See DEPLOYMENT.md for Nginx/Caddy examples.

---

## Pre-Configured Values

Database (PostgreSQL):
```
Host: server.fluxodigitaltech.com.br
Port: 5440
User: postgres
Password: o2026Secure99x
Database: fluxo_emailmkt (needs creation)
```

Redis Cache:
```
Host: server.fluxodigitaltech.com.br
Port: 6379
Password: a0b5ce3da557ad432a2f
```

---

## Configuration Checklist

Before deploying:

- [ ] `.env.production` is configured with SMTP details
- [ ] `SECRET_KEY_BASE` is generated and unique
- [ ] Database `fluxo_emailmkt` is created on PostgreSQL
- [ ] Network connectivity verified (preflight-check.sh)
- [ ] Reverse proxy will be configured to port 4001
- [ ] HTTPS certificate is ready
- [ ] Backups are planned

---

## Common Commands

### Deployment
```bash
./scripts/deploy.sh              # Full deployment
./scripts/deploy.sh down         # Stop containers
./scripts/deploy.sh restart      # Restart services
./scripts/deploy.sh logs         # View logs
./scripts/deploy.sh migrate      # Run migrations
./scripts/deploy.sh status       # Show status
```

### Manual Docker
```bash
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f fluxo-emailmkt
docker-compose -f docker-compose.prod.yml restart fluxo-emailmkt
```

### Database
```bash
# Backup
PGPASSWORD=o2026Secure99x pg_dump \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  fluxo_emailmkt | gzip > backup.sql.gz

# Connect
PGPASSWORD=o2026Secure99x psql \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  -d fluxo_emailmkt
```

---

## Port Mapping

| Service | Port (Host) | Port (Container) | Access |
|---------|------------|-----------------|--------|
| Reverse Proxy | 80 | - | HTTP → HTTPS |
| Reverse Proxy | 443 | - | HTTPS |
| Keila App | 4001 | 4000 | Local |
| Redis | - | 6379 | Internal only |
| PostgreSQL | - (external) | 5440 | Remote |

---

## Security Notes

1. **Secrets**: Never commit `.env.production` to git
   ```bash
   echo ".env.production" >> .gitignore
   ```

2. **SECRET_KEY_BASE**: Generate with openssl
   ```bash
   openssl rand -base64 32
   ```

3. **HTTPS**: Configure reverse proxy with valid SSL certificate
4. **Backups**: Automate daily database backups
5. **Monitoring**: Setup log aggregation and alerts
6. **Network**: Restrict database access via firewall

---

## Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Container won't start | See PRODUCTION_README.md line "Container won't start?" |
| Database error | Run `psql $DB_URL -c "SELECT 1"` to test connection |
| SMTP not working | Check logs: `./scripts/deploy.sh logs \| grep -i smtp` |
| Health check failing | Run `curl http://localhost:4001/health` |
| Port 4001 in use | Check `netstat -tuln \| grep 4001` |

See DEPLOYMENT.md for comprehensive troubleshooting.

---

## Support & Resources

### Documentation
- **PRODUCTION_README.md** - Quick reference
- **DEPLOYMENT.md** - Complete guide
- **PRODUCTION_SETUP_SUMMARY.txt** - Detailed reference

### External Resources
- Keila Docs: https://docs.keila.io
- Docker Docs: https://docs.docker.com
- PostgreSQL Docs: https://www.postgresql.org/docs

### Getting Help
1. Check PRODUCTION_README.md troubleshooting section
2. Review DEPLOYMENT.md for detailed guidance
3. Run `./scripts/deploy.sh help` for command info
4. Check application logs: `./scripts/deploy.sh logs`

---

## Next Steps

1. **Read:** PRODUCTION_README.md (5-10 minutes)
2. **Prepare:** Configure .env.production
3. **Verify:** Run ./scripts/preflight-check.sh
4. **Deploy:** Run ./scripts/deploy.sh
5. **Configure:** Setup reverse proxy
6. **Monitor:** Review logs and setup alerts
7. **Backup:** Setup automated database backups
8. **Document:** Create your operations runbook

---

## Version Information

- Setup Version: 1.0
- Created: April 12, 2026
- Keila Version: Latest (from ops/Dockerfile)
- Elixir: 1.18-alpine
- PostgreSQL: 12+ (external)
- Redis: 7-alpine (internal) + 6+ (external)
- Docker: 20.10+
- Docker Compose: 2.0+

---

## Quick Reference Card

```
DEPLOYMENT CHECKLIST:
[ ] Read PRODUCTION_README.md
[ ] Run ./scripts/preflight-check.sh
[ ] Configure .env.production
[ ] Create fluxo_emailmkt database
[ ] Run ./scripts/deploy.sh
[ ] Configure reverse proxy (Nginx/Caddy)
[ ] Test https://emailmkt.fluxodigitaltech.com.br
[ ] Setup monitoring and alerts
[ ] Setup daily backups
[ ] Document operations procedures

QUICK COMMANDS:
preflight-check.sh    - Verify requirements
deploy.sh up          - Deploy and start
deploy.sh logs        - View logs
deploy.sh restart     - Restart services
deploy.sh down        - Stop services
deploy.sh migrate     - Run migrations
deploy.sh help        - Show help

TROUBLESHOOTING:
logs:     ./scripts/deploy.sh logs
status:   ./scripts/deploy.sh status
db-test:  psql $DB_URL -c "SELECT 1"
health:   curl http://localhost:4001/health
```

---

**Ready to deploy?** Start with:
```bash
./scripts/preflight-check.sh
```

For detailed instructions, see **PRODUCTION_README.md** or **DEPLOYMENT.md**
