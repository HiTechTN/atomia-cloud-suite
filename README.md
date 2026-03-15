# Atomia Cloud Suite v4.0

A fully self-hosted, AI-powered personal development cloud — Git, IDE, AI chat, authentication, monitoring, and automated backups in a single `docker compose up`.

---

## Quick Start

```bash
git clone https://github.com/HiTechTN/atomia-cloud-suite.git
cd atomia-cloud-suite

cp .env.example .env        # edit passwords first!
chmod +x setup.sh
./setup.sh
```

---

## Services & URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Open WebUI** | http://localhost:8080 | AI chat with RAG |
| **Code Server** | http://localhost:8443 | Browser IDE (VS Code) |
| **Gitea** | http://localhost:3000 | Self-hosted Git |
| **Authelia** | http://localhost:9091 | SSO & MFA portal |
| **Grafana** | http://localhost:3001 | Container dashboards |
| **Prometheus** | http://localhost:9090 | Raw metrics |
| **Ollama API** | http://localhost:11434 | Local LLM inference |
| **Nginx Proxy Mgr** | http://localhost:81 | Reverse proxy + SSL |
| **Qdrant** | http://localhost:6333 | Vector store for RAG |

---

## Authentication (Authelia SSO)

All services are protected by [Authelia](https://www.authelia.com/), an open-source SSO and MFA gateway.

### Default Users

| Username | Password | Groups |
|----------|----------|--------|
| `admin` | `atomia-admin` | admins, developers |
| `developer` | `developer123` | developers |

> **Change these immediately.** See below for how.

### Change / Add Users

1. Generate a new password hash:
   ```bash
   docker run --rm authelia/authelia:latest \
     authelia crypto hash generate argon2 --password 'YOUR_NEW_PASSWORD'
   ```
2. Edit `authelia/users_database.yml` and replace the `password:` field.
3. Restart Authelia: `docker compose restart authelia`

### Access Control Levels

| Level | Applies To | Requires |
|-------|-----------|---------|
| `bypass` | Internal network | Nothing |
| `one_factor` | Open WebUI, Code Server | Username + password |
| `two_factor` | Grafana, Prometheus | Password + TOTP |

Edit `authelia/configuration.yml` to adjust rules.

### Generate Secrets

```bash
# In .env, replace the AUTHELIA_* values with these outputs:
openssl rand -hex 32   # AUTHELIA_JWT_SECRET
openssl rand -hex 32   # AUTHELIA_SESSION_SECRET
openssl rand -hex 32   # AUTHELIA_STORAGE_KEY
```

---

## RAG — Retrieval-Augmented Generation

Open WebUI uses [Qdrant](https://qdrant.tech/) as its persistent vector store. Uploaded documents and chat context are chunked, embedded (via `nomic-embed-text` on Ollama), and stored permanently.

### Add a Knowledge Base

1. Open http://localhost:8080 → **Settings → Knowledge**
2. Click **New Knowledge Base**
3. Upload documents (PDF, TXT, MD, DOCX, CSV)
4. In chat, reference it with `@knowledge-base-name`

### Chat History Persistence

All conversations are stored in the Open WebUI SQLite database at `./data/openwebui/`. Semantic search across past chats is powered by Qdrant.

### RAG Embedding Model

The default model is `all-MiniLM-L6-v2` (sentence-transformers). To switch:
```bash
# .env
RAG_EMBEDDING_MODEL=nomic-embed-text
```
Then restart Open WebUI: `docker compose restart open-webui`.

---

## GPU Configuration (Ollama)

Ollama auto-detects NVIDIA GPUs via the NVIDIA Container Toolkit. CPU fallback is automatic when no GPU is present.

### Enable GPU

```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" \
  | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Tune Resources (`.env`)

```bash
NVIDIA_VISIBLE_DEVICES=all      # or 0,1 for specific GPUs; none for CPU-only
OLLAMA_MAX_LOADED_MODELS=2      # reduce on low VRAM (e.g. 1 for 8GB cards)
OLLAMA_MEM_LIMIT=16G            # container memory cap
OLLAMA_CPU_LIMIT=4.0            # CPU cores
```

### Default Model Download Path

All models are persisted to `./data/ollama` and survive container recreation.

```bash
# Pull additional models at any time
docker exec atomia-ollama ollama pull llama3
docker exec atomia-ollama ollama list
```

---

## AI Code Completion (Continue.dev)

Continue.dev is pre-configured in `continue/config.json` with:

| Feature | Model | Notes |
|---------|-------|-------|
| **Chat / Edit** | `deepseek-coder` | Full context, code review |
| **Tab Autocomplete** | `deepseek-coder:1.3b` | Fast, low-latency ghost text |
| **Embeddings / RAG** | `nomic-embed-text` | Codebase search |

### Auto-install VS Code Extensions

Set `EXTENSION_URLS` in `.env` (comma-separated `.vsix` URLs):
```bash
EXTENSION_URLS=https://github.com/owner/repo/releases/download/v1.0/ext.vsix
```
Extensions are installed on every container start via `code-server-init.sh`.

---

## Monitoring (Prometheus + Grafana)

### Access

- **Grafana**: http://localhost:3001 — login with `admin` / `$GRAFANA_PASSWORD`
- **Prometheus**: http://localhost:9090 — raw metrics & query interface

Grafana is pre-configured with Prometheus as a data source (via `monitoring/grafana-datasources.yml`).

### Recommended Dashboards

Import these by ID from the Grafana marketplace (Dashboards → Import):

| Dashboard | ID | What it shows |
|-----------|-----|---------------|
| **cAdvisor** | `14282` | Per-container CPU/RAM/disk |
| **Node Exporter** | `1860` | Host system metrics |
| **Docker overview** | `893` | Docker daemon stats |

### Alerts

`monitoring/alerts.yml` contains pre-built rules for:

| Alert | Condition |
|-------|-----------|
| `ContainerDown` | Any `atomia-*` container absent for >1 min |
| `HighCPUUsage` | Container CPU > 85% for 5 min |
| `HighMemoryUsage` | Container memory > 90% of limit |
| `DiskSpaceLow` | Root FS < 20% free |

---

## Automated Backups

```bash
chmod +x backup.sh
./backup.sh
```

### What Gets Backed Up

| Volume | Contents |
|--------|---------|
| `data/ollama` | AI model weights |
| `data/openwebui` | Chats, users, uploads |
| `data/qdrant` | Vector embeddings |
| `data/authelia` | User sessions, TOTP secrets |
| `data/gitea` | Git repos, issues, wiki |
| `data/grafana` | Dashboards, alerts |
| `projects/` | Your source code |

### Encryption

```bash
# .env
BACKUP_PASSPHRASE=my_strong_passphrase
```
When set, each `.tar.gz` is encrypted with AES-256-CBC via OpenSSL before saving.

### Off-site Sync (rclone)

```bash
# .env — examples
RCLONE_REMOTE=s3:my-bucket/atomia-backups
# RCLONE_REMOTE=gdrive:Backups/Atomia
```

Install rclone and configure a remote: https://rclone.org/install/

### Automated Schedule (cron)

```bash
crontab -e
# Add: daily at 03:00
0 3 * * * /path/to/atomia-cloud-suite/backup.sh >> /var/log/atomia-backup.log 2>&1
```

### Retention

Default: **7 days**. Change via `.env`:
```bash
RETENTION_DAYS=14
```

---

## CI/CD with Gitea Actions

### Register a Runner

1. Go to http://localhost:3000 → Site Administration → Actions → Runners
2. Click **Register Runner** — copy the token
3. Set in `.env`: `GITEA_RUNNER_TOKEN=<token>`
4. Restart runner: `docker compose restart gitea-runner`

### Workflow Examples

Pre-built workflows in `.gitea/workflows/`:

| File | Language | Steps |
|------|----------|-------|
| `ci-pipeline.yml` | Node.js | lint → test → build → Docker |
| `python-ci.yml` | Python | flake8 → pytest → build |

---

## HTTPS with Nginx Proxy Manager

1. Open http://localhost:81 → login `admin@example.com` / `changeme`
2. **Proxy Hosts → Add Proxy Host**
3. Set domain, forward to the service container name + port
4. **SSL tab** → Request Let's Encrypt certificate

| Service | Forward to | Port |
|---------|-----------|------|
| Gitea | `gitea` | 3000 |
| Open WebUI | `open-webui` | 8080 |
| Code Server | `code-server` | 8080 |
| Grafana | `grafana` | 3000 |
| Authelia | `authelia` | 9091 |

---

## Persistent Storage Layout

```
data/
├── ollama/          # AI model weights (10–50 GB)
├── openwebui/       # Chat history, users, uploads
├── qdrant/          # Vector embeddings for RAG
├── authelia/        # Sessions, TOTP secrets, SQLite
├── code-server/     # IDE config, extensions
├── code-server-ssh/ # SSH keys
├── gitea/           # Git repos, database, attachments
├── gitea-ssh/       # Git SSH keys
├── gitea-runner/    # CI/CD runner data
├── prometheus/      # Metrics TSDB (30-day retention)
└── grafana/         # Dashboards, alert rules
projects/            # Your source code repos
backups/             # Dated archives (auto-rotated)
```

**Restore a backup:**
```bash
tar -xzf backups/2026-03-15_03-00-00/data_gitea.tar.gz
```

---

## Useful Commands

```bash
# Start / stop everything
docker compose up -d
docker compose down

# Live logs for a service
docker compose logs -f ollama
docker compose logs -f authelia

# Pull latest images & recreate
docker compose pull && docker compose up -d

# List loaded AI models
docker exec atomia-ollama ollama list

# Add a new AI model
docker exec atomia-ollama ollama pull llama3.1

# Manual backup
./backup.sh

# Regenerate Authelia password hash
docker run --rm authelia/authelia:latest \
  authelia crypto hash generate argon2 --password 'NEW_PASSWORD'
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    ATOMIA CLOUD SUITE v4.0                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌────────┐ │
│  │   OLLAMA   │◄─►│ OPEN WEBUI │   │CODE SERVER │   │ GITEA  │ │
│  │ (GPU/CPU)  │   │ + RAG Chat │   │+ SSH + Ext │   │+CI/CD  │ │
│  └─────┬──────┘   └─────┬──────┘   └────────────┘   └───┬────┘ │
│        │                │                               │      │
│        ▼                ▼                               ▼      │
│  ┌────────────┐   ┌────────────┐   ┌────────────────────────┐  │
│  │   QDRANT   │   │  AUTHELIA  │   │    GITEA RUNNER (CI)   │  │
│  │ (Vectors)  │   │ (SSO/MFA)  │   └────────────────────────┘  │
│  └────────────┘   └─────┬──────┘                               │
│                          │                                      │
│  ┌───────────────────────▼──────────────────────────────────┐  │
│  │              NGINX PROXY MANAGER (SSL + Routes)          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐              │
│  │ PROMETHEUS │──►│  GRAFANA   │   │  CADVISOR  │              │
│  │ (Metrics)  │   │(Dashboards)│   │(Container) │              │
│  └────────────┘   └────────────┘   └────────────┘              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          BIND-MOUNTED VOLUMES  ./data/...                │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## License

MIT — free to use, modify, and self-host.
