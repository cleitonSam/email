# Production Deployment - Quick Reference

This directory contains production-ready deployment configurations for **Fluxo Email MKT** (Keila email marketing platform).

## Files Overview

### `docker-compose.prod.yml`
Production-ready Docker Compose configuration with:
- Single application container (uses external PostgreSQL & Redis)
- Health checks with 30-second intervals
- Auto-restart policy
- Volume persistence for uploads
- Local Redis for sessions/queues
- Environment variable templating
- Isolated docker network

**Key Features:**
- Port mapping: 4001 (host) → 4000 (container)
- No embedded PostgreSQL (uses external server at `server.fluxodigitaltech.com.br:5440`)
- Redis connection to external server at `server.fluxodigitaltech.com.br:6379`
- Automatic health checks every 30 seconds

### `.env.production`
Complete environment configuration template with:
- All required variables pre-filled with actual values where available
- Placeholders for secrets that need to be generated
- Comprehensive comments explaining each setting
- Database, Redis, SMTP, and URL configurations
- Security and feature flag settings

**Critical values to update:**
```bash
SECRET_KEY_BASE=CHANGE_ME_TO_A_RANDOM_64_CHAR_STRING
MAILER_SMTP_HOST=your-smtp-server.com
MAILER_SMTP_USER=your-smtp-user
MAILER_SMTP_PASSWORD=your-smtp-password
```

Generate a secure `SECRET_KEY_BASE`:
```bash
openssl rand -base64 32
```

### `scripts/deploy.sh`
Automated deployment script supporting:
- `./scripts/deploy.sh` - Full deployment (validate, create DB, build, start, migrate)
- `./scripts/deploy.sh up` - Deploy and start
- `./scripts/deploy.sh down` - Stop and remove
- `./scripts/deploy.sh restart` - Restart containers
- `./scripts/deploy.sh logs` - View logs (follow)
- `./scripts/deploy.sh migrate` - Run migrations only
- `./scripts/deploy.sh status` - Show status
- `./scripts/deploy.sh help` - Show help

**Features:**
- Validates environment before deployment
- Creates PostgreSQL database automatically if needed
- Builds Docker images
- Runs database migrations
- Color-coded output for clarity
- Health check monitoring
- Error handling with helpful messages

### `DEPLOYMENT.md`
Complete deployment guide covering:
- System and infrastructure requirements
- Step-by-step deployment instructions
- Configuration details and architecture
- Common operations (logs, restart, migrations)
- Reverse proxy setup (Nginx, Caddy)
- Backup and recovery procedures
- Monitoring and maintenance
- Troubleshooting guide
- Security considerations
- Deployment checklist

## Quick Start (5 minutes)

```bash
# 1. Configure environment
nano .env.production
# Update: SECRET_KEY_BASE, MAILER_SMTP_*, and other critical values

# 2. Deploy
./scripts/deploy.sh

# 3. Access
# https://emailmkt.fluxodigitaltech.com.br
```

## Infrastructure Overview

```
External Services (shared):
├── PostgreSQL: server.fluxodigitaltech.com.br:5440
├── Redis: server.fluxodigitaltech.com.br:6379
└── SMTP: Your email provider

Docker Containers (this deployment):
├── fluxo-emailmkt (Keila app on port 4000)
├── redis (local session/queue cache)
└── volumes:
    ├── fluxo_emailmkt_uploads
    └── fluxo_emailmkt_redis

Host/Reverse Proxy:
└── Port 4001 → Docker (then 80/443 via nginx/caddy)
```

## Key Configuration Notes

### Database
- **URL**: `postgres://postgres:o2026Secure99x@server.fluxodigitaltech.com.br:5440/fluxo_emailmkt`
- **SSL**: Disabled by default (`DB_ENABLE_SSL=false`)
- **Database**: `fluxo_emailmkt` (must be created before first deploy)

Create the database on PostgreSQL server:
```bash
psql -h server.fluxodigitaltech.com.br -p 5440 -U postgres
postgres=# CREATE DATABASE fluxo_emailmkt;
postgres=# \q
```

### Redis
- **URL**: `redis://default:a0b5ce3da557ad432a2f@server.fluxodigitaltech.com.br:6379`
- **Purpose**: Session storage, background job queue
- **Note**: External Redis is used; internal Redis is for local caching only

### Domain & URLs
- **Primary Domain**: `emailmkt.fluxodigitaltech.com.br`
- **Port**: 443 (HTTPS)
- **Scheme**: https
- **Access**: Configure reverse proxy (nginx/Caddy) to forward to localhost:4001

### Email (SMTP)
Configure these variables with your email provider:
```bash
MAILER_SMTP_HOST=your-smtp-server
MAILER_SMTP_PORT=587
MAILER_SMTP_USER=your-username
MAILER_SMTP_PASSWORD=your-password
MAILER_SMTP_FROM_EMAIL=noreply@emailmkt.fluxodigitaltech.com.br
```

## Port Mapping

- **Host Port 4001** ← Used by the application
- **Container Port 4000** ← Internal Keila service
- **HTTPS Port 443** ← Your reverse proxy (nginx/Caddy)
- **HTTP Port 80** ← Your reverse proxy (redirect to 443)

For local testing without reverse proxy:
```bash
curl http://localhost:4001/health
```

## Health Checks

The application includes automated health checks:

```bash
# Check via Docker
docker inspect fluxo-emailmkt-app --format='{{.State.Health.Status}}'

# Check via HTTP
curl http://localhost:4001/health
```

Status values: `healthy`, `unhealthy`, `starting`

## Logging & Monitoring

View real-time logs:
```bash
./scripts/deploy.sh logs
```

Monitor resource usage:
```bash
docker stats fluxo-emailmkt-app
```

Check specific errors:
```bash
docker-compose -f docker-compose.prod.yml logs fluxo-emailmkt | grep -i error
```

## Common Tasks

### Update Application
```bash
git pull
./scripts/deploy.sh
```

### Migrate Database
```bash
./scripts/deploy.sh migrate
```

### Backup Database
```bash
PGPASSWORD=o2026Secure99x pg_dump \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  fluxo_emailmkt | gzip > backup_$(date +%Y%m%d).sql.gz
```

### View Latest 100 Log Lines
```bash
docker-compose -f docker-compose.prod.yml logs --tail 100 fluxo-emailmkt
```

## Security Checklist

Before going live:

- [ ] `.env.production` has unique `SECRET_KEY_BASE` (32+ chars)
- [ ] SMTP credentials are correct and secure
- [ ] Database password is strong and updated
- [ ] Redis password is set in `.env.production`
- [ ] `USER_CONTENT_BASE_URL` is configured (separate domain for uploads)
- [ ] HTTPS is enabled on reverse proxy
- [ ] SSL certificate is valid and auto-renewing
- [ ] Firewall restricts database/Redis access
- [ ] Backups are automated and tested
- [ ] Monitoring and alerts are configured
- [ ] Team knows the deployment process

## Troubleshooting

### Container won't start?
```bash
docker-compose -f docker-compose.prod.yml logs fluxo-emailmkt
# Look for database or configuration errors
```

### Can't connect to database?
```bash
# Test connection
PGPASSWORD=o2026Secure99x psql \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  -d fluxo_emailmkt \
  -c "SELECT 1"
```

### SMTP/Email not working?
```bash
# Check logs for SMTP errors
./scripts/deploy.sh logs | grep -i smtp

# Verify credentials in .env.production
grep MAILER .env.production
```

### Health check failing?
```bash
# Check application logs
docker-compose -f docker-compose.prod.yml logs --tail 50 fluxo-emailmkt

# Test health endpoint
curl -v http://localhost:4001/health
```

## Environment Variables Reference

See `.env.production` for all variables with descriptions. Key groups:

**Core** (required)
- `SECRET_KEY_BASE`
- `DB_URL`
- `REDIS_URL`

**URL** (required)
- `URL_HOST`
- `URL_PORT`
- `URL_SCHEMA`

**SMTP** (required)
- `MAILER_SMTP_HOST`
- `MAILER_SMTP_USER`
- `MAILER_SMTP_PASSWORD`
- `MAILER_SMTP_FROM_EMAIL`

**Optional**
- File storage, quotas, registration, logging

## Next Steps

1. **Read** `DEPLOYMENT.md` for detailed instructions
2. **Update** `.env.production` with your actual values
3. **Run** `./scripts/deploy.sh` to deploy
4. **Configure** your reverse proxy (nginx/Caddy)
5. **Test** the application at your domain
6. **Set up** automated backups
7. **Monitor** the application (logs, health, resources)

## Support

- Keila Docs: https://docs.keila.io
- Issues: Check application logs with `./scripts/deploy.sh logs`
- Deployment issues: See DEPLOYMENT.md troubleshooting section

---

**Production Deployment Kit** for Fluxo Email MKT  
Version 1.0 | April 2026
