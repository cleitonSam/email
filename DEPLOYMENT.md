# Fluxo Email MKT - Production Deployment Guide

This guide covers the production deployment of the Keila email marketing platform (rebranded as "Fluxo Email MKT") to a VPS using Docker Compose.

## Prerequisites

### System Requirements
- Docker 20.10+ installed
- Docker Compose 2.0+ installed
- PostgreSQL client tools (`psql`) installed
- Network access to:
  - External PostgreSQL server at `server.fluxodigitaltech.com.br:5440`
  - External Redis server at `server.fluxodigitaltech.com.br:6379`
  - SMTP server for sending emails
  - Your domain DNS records

### Infrastructure Requirements
- External PostgreSQL 12+ database server
- External Redis 6+ server
- A domain name (e.g., `emailmkt.fluxodigitaltech.com.br`)
- SSL/TLS certificate for HTTPS (handled by reverse proxy)
- SMTP credentials for email sending

## Quick Start

### 1. Prepare the Database

On the PostgreSQL server, create the database for the application:

```bash
psql -h server.fluxodigitaltech.com.br -p 5440 -U postgres
postgres=# CREATE DATABASE fluxo_emailmkt;
postgres=# \q
```

### 2. Configure Environment

Copy the template and customize it:

```bash
cd /path/to/fluxo/email
cp .env.production.example .env.production
```

Edit `.env.production` and update the following critical values:

```bash
# Generate a secure SECRET_KEY_BASE
SECRET_KEY_BASE=$(openssl rand -base64 32)
echo $SECRET_KEY_BASE

# Update the file with this value and other required settings
nano .env.production
```

**Required changes:**
- `SECRET_KEY_BASE`: Generate with `openssl rand -base64 32`
- `MAILER_SMTP_HOST`: Your SMTP server hostname
- `MAILER_SMTP_USER`: SMTP username
- `MAILER_SMTP_PASSWORD`: SMTP password
- `MAILER_SMTP_FROM_EMAIL`: Sender email address
- `URL_HOST`: Your domain (e.g., `emailmkt.fluxodigitaltech.com.br`)

### 3. Deploy the Application

```bash
# Make the deploy script executable
chmod +x scripts/deploy.sh

# Run the deployment
./scripts/deploy.sh

# Or just deploy without migrations
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d
```

The script will:
1. Validate your environment configuration
2. Create the database (if needed)
3. Build Docker images
4. Start containers
5. Run database migrations
6. Show application status

### 4. Access the Application

Once deployed, access the application at:
```
https://emailmkt.fluxodigitaltech.com.br
```

The application runs on port 4001 internally (mapped from container port 4000).

## Configuration Details

### Docker Compose Services

#### `fluxo-emailmkt`
- **Image**: `fluxo/emailmkt:latest`
- **Port**: 4001 (exposed) → 4000 (internal)
- **Volumes**: `/opt/app/uploads` for user uploads
- **Health Check**: HTTP GET `/health` every 30 seconds
- **Restart**: Unless stopped (`unless-stopped`)
- **Dependencies**: Redis

#### `redis`
- **Image**: `redis:7-alpine`
- **Port**: 6379 (internal only, not exposed)
- **Volume**: `/data` for persistence
- **Purpose**: Session storage and background job queue

### Network Architecture

```
┌─────────────────────────────────────────┐
│         External Services               │
├─────────────────────────────────────────┤
│  PostgreSQL: server.fluxodigitaltech... │
│  Redis: server.fluxodigitaltech...      │
│  SMTP: Your mail provider               │
└─────────────────────────────────────────┘
           ↑
           │ (Network connections)
           │
┌─────────────────────────────────────────┐
│    Docker Container Network             │
├─────────────────────────────────────────┤
│ fluxo_emailmkt_network (bridge)         │
│  ├─ fluxo-emailmkt (port 4000)          │
│  └─ redis (port 6379, local only)       │
└─────────────────────────────────────────┘
           ↑
           │ (Port 4001)
           │
┌─────────────────────────────────────────┐
│      Host / Reverse Proxy                │
│      (nginx, Caddy, etc.)               │
│      Port 80/443                        │
└─────────────────────────────────────────┘
           ↑
           │ HTTPS
           │
┌─────────────────────────────────────────┐
│            Internet / Users              │
└─────────────────────────────────────────┘
```

### Environment Variables

#### Core Configuration
- `SECRET_KEY_BASE`: Session encryption key (required, 32+ chars)
- `MIX_ENV`: Should be `prod` in production

#### Database
- `DB_URL`: PostgreSQL connection string (required)
- `DB_ENABLE_SSL`: Enable SSL for database (default: false)
- `DB_VERIFY_SSL_HOST`: Verify SSL certificate (default: TRUE)

#### Redis
- `REDIS_URL`: Redis connection string
- `REDIS_PASSWORD`: Redis password (if auth enabled)

#### Application URLs
- `URL_HOST`: Domain name (required)
- `URL_PORT`: Port (default: 443)
- `URL_SCHEMA`: Protocol scheme (default: https)
- `URL_PATH`: URL path prefix (default: /)

#### SMTP Configuration
- `MAILER_SMTP_HOST`: SMTP server hostname (required)
- `MAILER_SMTP_PORT`: SMTP port (default: 587)
- `MAILER_SMTP_USER`: SMTP username
- `MAILER_SMTP_PASSWORD`: SMTP password
- `MAILER_SMTP_FROM_EMAIL`: Sender email (required)
- `MAILER_ENABLE_SSL`: Enable SSL/TLS (default: false)
- `MAILER_ENABLE_STARTTLS`: Enable STARTTLS (default: true)

#### File Storage
- `USER_CONTENT_DIR`: Upload directory (default: /opt/app/uploads)
- `USER_CONTENT_BASE_URL`: CDN URL for user uploads (recommended for security)

#### Security & Features
- `DISABLE_REGISTRATION`: Disable self-registration (default: false)
- `DISABLE_SENDER_CREATION`: Disable custom senders (default: false)
- `ENABLE_QUOTAS`: Enable sending quotas (default: false)
- `DISABLE_UPDATE_CHECKS`: Disable update checks (default: false)

#### Logging
- `LOG_LEVEL`: Log level: debug, info, error (default: info)

## Common Operations

### View Logs
```bash
./scripts/deploy.sh logs
# or
docker-compose -f docker-compose.prod.yml logs -f fluxo-emailmkt
```

### Restart the Application
```bash
./scripts/deploy.sh restart
# or
docker-compose -f docker-compose.prod.yml restart fluxo-emailmkt
```

### Stop the Application
```bash
./scripts/deploy.sh down
# or
docker-compose -f docker-compose.prod.yml down
```

### Run Database Migrations
```bash
./scripts/deploy.sh migrate
# or
docker-compose -f docker-compose.prod.yml exec fluxo-emailmkt \
  /opt/app/bin/keila eval "Keila.Release.migrate()"
```

### Execute a Command in the Container
```bash
docker-compose -f docker-compose.prod.yml exec fluxo-emailmkt \
  /bin/sh -c "your command here"
```

### Rebuild and Redeploy
```bash
# Pull latest code and rebuild
docker-compose -f docker-compose.prod.yml --env-file .env.production build --no-cache
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d
```

## Health Checks

The application includes built-in health checks:

```bash
# Check container health
docker inspect fluxo-emailmkt-app --format='{{.State.Health.Status}}'

# Or via HTTP
curl http://localhost:4001/health
```

Health check configuration:
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3 attempts
- **Start Period**: 40 seconds before first check

## Reverse Proxy Configuration

### Nginx Example
```nginx
upstream fluxo_emailmkt {
    server localhost:4001;
}

server {
    listen 80;
    server_name emailmkt.fluxodigitaltech.com.br;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name emailmkt.fluxodigitaltech.com.br;

    ssl_certificate /etc/ssl/certs/emailmkt.crt;
    ssl_certificate_key /etc/ssl/private/emailmkt.key;

    # Additional SSL configuration...
    
    location / {
        proxy_pass http://fluxo_emailmkt;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }
}
```

### Caddy Example
```caddyfile
emailmkt.fluxodigitaltech.com.br {
    reverse_proxy localhost:4001 {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Real-IP {remote_ip}
        flush_interval 1s
    }
}
```

## Backup & Recovery

### Database Backup
```bash
# Backup PostgreSQL database
PGPASSWORD=o2026Secure99x pg_dump \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  fluxo_emailmkt > fluxo_emailmkt_backup.sql

# Restore from backup
PGPASSWORD=o2026Secure99x psql \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  fluxo_emailmkt < fluxo_emailmkt_backup.sql
```

### Volume Backup
```bash
# Backup uploads volume
docker run --rm -v fluxo_emailmkt_uploads:/data \
  -v /backup:/backup \
  alpine tar czf /backup/uploads.tar.gz -C /data .

# Restore uploads
docker run --rm -v fluxo_emailmkt_uploads:/data \
  -v /backup:/backup \
  alpine tar xzf /backup/uploads.tar.gz -C /data
```

### Full System Backup
```bash
#!/bin/bash
BACKUP_DIR="/backups/fluxo-emailmkt"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Database backup
PGPASSWORD=o2026Secure99x pg_dump \
  -h server.fluxodigitaltech.com.br \
  -p 5440 \
  -U postgres \
  fluxo_emailmkt | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Volumes backup
docker run --rm -v fluxo_emailmkt_uploads:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf "/backup/uploads_$DATE.tar.gz" -C /data .

# Keep only last 7 days of backups
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR"
```

## Monitoring & Maintenance

### Check Service Status
```bash
./scripts/deploy.sh status
```

### Monitor Container Resource Usage
```bash
docker stats fluxo-emailmkt-app redis
```

### View System Events
```bash
docker events --filter 'container=fluxo-emailmkt-app'
```

### Update Application
```bash
# Pull latest changes from git
git pull

# Rebuild and redeploy
./scripts/deploy.sh up
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs fluxo-emailmkt

# Verify configuration
cat .env.production | grep -E "^[A-Z]"

# Test database connectivity
docker-compose -f docker-compose.prod.yml exec -T fluxo-emailmkt \
  psql $DB_URL -c "SELECT 1"
```

### High Memory Usage
```bash
# Check container memory
docker stats fluxo-emailmkt-app --no-stream

# Restart to clear memory
./scripts/deploy.sh restart
```

### Database Connection Issues
```bash
# Test database from VPS
psql -h server.fluxodigitaltech.com.br -p 5440 -U postgres -d fluxo_emailmkt -c "SELECT 1"

# Check DB_URL format in .env.production
cat .env.production | grep DB_URL
```

### Redis Connection Issues
```bash
# Test Redis connectivity
docker-compose -f docker-compose.prod.yml exec -T fluxo-emailmkt \
  redis-cli -u "$REDIS_URL" ping
```

### SMTP/Email Not Working
```bash
# Verify SMTP settings in logs
./scripts/deploy.sh logs | grep -i smtp

# Test SMTP manually
telnet your.smtp.server 587
```

## Security Considerations

1. **Secrets Management**
   - Never commit `.env.production` to version control
   - Use `.gitignore` to exclude environment files
   - Store secrets in a secure vault (HashiCorp Vault, AWS Secrets Manager, etc.)

2. **Network Security**
   - Keep external databases in a private network
   - Use VPN or SSH tunnels if accessing from untrusted networks
   - Enable SSL/TLS for all external connections
   - Use strong passwords for database and Redis

3. **Application Security**
   - Keep Docker images updated: `docker pull` regularly
   - Update application dependencies: rebuild periodically
   - Monitor logs for security issues
   - Configure firewall rules to restrict access

4. **Data Protection**
   - Regular automated backups (daily)
   - Secure backup storage (encrypted, off-site)
   - Test backup restoration procedures
   - Implement GDPR/privacy compliance measures

5. **SSL/TLS Configuration**
   - Use Let's Encrypt for free certificates
   - Enable HSTS headers
   - Redirect HTTP to HTTPS
   - Use strong cipher suites

## Support & Resources

- **Keila Documentation**: https://docs.keila.io
- **Docker Documentation**: https://docs.docker.com
- **PostgreSQL Documentation**: https://www.postgresql.org/docs
- **Redis Documentation**: https://redis.io/documentation

## Deployment Checklist

Before going live, verify:

- [ ] `.env.production` is created and properly configured
- [ ] Database credentials are correct
- [ ] Redis connection works
- [ ] SMTP credentials are valid
- [ ] Domain DNS is configured
- [ ] SSL certificate is valid
- [ ] Reverse proxy is configured
- [ ] Firewall rules are appropriate
- [ ] Backups are automated
- [ ] Monitoring is in place
- [ ] Team knows the deployment process
- [ ] Rollback plan is documented

## Version History

- **v1.0** (2026-04-12): Initial production deployment setup
  - Docker Compose configuration for external databases
  - Automated deployment script
  - Environment template with all required variables
  - Health checks and auto-restart policies
