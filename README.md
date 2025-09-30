# IP Monitoring System

IP address availability monitoring system with RTT statistics and packet loss calculation.

## Features

- IP address registration and management (IPv4 and IPv6)
- Periodic ping checks with configurable interval
- Database-level statistics calculation
- RESTful API for management
- Web interface for monitoring
- Docker Compose for easy deployment

## Quick Start

### With Docker Compose (recommended)

```bash
# Clone repository
git clone <repository-url>
cd test-monitoring

# Setup environment variables
make setup-env

# Start with Docker Compose
docker-compose up -d

# Open web interface
open http://localhost:4567
```

### Local Development

```bash
# Install dependencies
make install

# Setup environment variables
make setup-env

# Setup database
createdb ip_monitoring
make migrate

# Start application
make run

# Open web interface
open http://localhost:4567
```

## API Endpoints

| Method | Path | Description |
|-------|------|-------------|
| `GET` | `/` | Web interface |
| `GET` | `/health` | Health check |
| `GET` | `/ips` | List all IP addresses |
| `POST` | `/ips` | Add IP address |
| `POST` | `/ips/:id/enable` | Enable monitoring |
| `POST` | `/ips/:id/disable` | Disable monitoring |
| `GET` | `/ips/:id/stats` | Get statistics |
| `DELETE` | `/ips/:id` | Delete IP address |

## Usage Examples

### Add IP Address

```bash
curl -X POST http://localhost:4567/ips \
  -H "Content-Type: application/json" \
  -d '{"ip": "8.8.8.8", "enabled": true}'
```

### Get Statistics

```bash
curl "http://localhost:4567/ips/1/stats?time_from=2024-01-01T00:00:00Z&time_to=2024-01-02T00:00:00Z"
```

## Configuration

Environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection URL | `postgres://postgres:password@localhost:5432/ip_monitoring` |
| `PORT` | Application port | `4567` |
| `PING_INTERVAL` | Ping check interval (seconds) | `60` |
| `PING_TIMEOUT` | Ping timeout (seconds) | `1` |

## Requirements

- Ruby 3.2+
- PostgreSQL 12+
- Docker and Docker Compose (for containerization)

## Available Commands

```bash
make install       # Install dependencies
make test          # Run tests
make run           # Start application
make migrate       # Run database migrations
make setup-env     # Setup environment variables
make docker-up     # Start with Docker Compose
make docker-down   # Stop Docker Compose
```
