# Atomia Cloud Suite v4.1

A fully self-hosted AI-powered development cloud — Git, IDE, SSO, AI chat, monitoring, automated pipelines, and backups in a single `docker compose up`.

---

## Quick Start

```bash
git clone https://github.com/HiTechTN/atomia-cloud-suite.git
cd atomia-cloud-suite

cp .env.example .env         # edit passwords first!
chmod +x setup.sh
./setup.sh
```

---

## Service Map

| Service | URL | Purpose |
|---------|-----|---------|
| **Open WebUI** | http://localhost:8080 | AI chat + RAG |
| **Code Server** | http://localhost:8443 | Browser IDE (VS Code) |
| **Gitea** | http://localhost:3000 | Self-hosted Git |
| **Authelia** | http://localhost:9091 | SSO & MFA portal |
| **Grafana** | http://localhost:3001 | Dashboards & alerts |
| **Prometheus** | http://localhost:9090 | Raw metrics |
| **Ollama API** | http://localhost:11434 | Local LLM inference |
| **Nginx Proxy Mgr** | http://localhost:81 | Reverse proxy + SSL |
| **Qdrant** | http://localhost:6333 | Vector store (RAG) |

---

## Automated Deployment Pipelines

Atomia includes a universal deploy script that integrates with Gitea Actions to push code to **staging** or **production** automatically on every commit.

### How It Works

```
git push → Gitea → Actions Runner → deploy.sh → docker compose up
```

A pre-built workflow lives at `.gitea/workflows/auto-deploy.yml`:

| Branch | Target |
|--------|--------|
| `develop` | Staging (port 8082) |
| `staging` | Staging (port 8082) |
| `main` | Production (port 8080) |

### Manual Deploy

```bash
chmod +x deploy/deploy.sh

# Deploy to staging
./deploy/deploy.sh staging http://localhost:3000/user/myapp.git develop /projects/myapp

# Deploy to production
./deploy/deploy.sh production http://localhost:3000/user/myapp.git main /projects/myapp
```

### Per-environment Config

- `deploy/docker-compose.staging.yml` — port overrides for staging
- `deploy/.staging.env` — (create yourself) staging-only env vars

### Deploy Script Steps

1. `git pull` — sync latest code
2. `docker build` — build image from Dockerfile (if present)
3. Run tests — npm test / pytest (staging only)
4. `docker compose up -d` — rolling deploy
5. Health check — polls `HEALTH_CHECK_URL` until live

---

## Gitea Integration

Code Server is pre-wired to your Gitea instance at startup via `code-server-init.sh`.

### What's Auto-Configured

- A dedicated `id_gitea` SSH key is generated for the `coder` user
- An SSH config alias `atomia-git` maps to Gitea's SSH port
- `git config --global` is set from `GIT_USER_NAME` and `GIT_USER_EMAIL` in `.env`
- `git clone atomia-git:user/repo` works without any manual setup

### Add SSH Key to Gitea

On first start, the init script prints your public key in the container logs:

```bash
docker compose logs code-server | grep -A3 "Add this SSH public key"
```

Paste it at: **Gitea → User Settings → SSH / GPG Keys → Add Key**

### Clone a Repo

In the Code Server terminal:

```bash
git clone ssh://git@atomia-git/your-username/your-repo
# or via HTTPS
git clone http://localhost:3000/your-username/your-repo
```

---

## Advanced AI Code Completion

### Models

| Role | Model | Characteristics |
|------|-------|-----------------|
| **Primary chat** | `qwen2.5-coder:7b` | 32K context, best code quality |
| **Tab autocomplete** | `starcoder2:3b` | 4K context, ~100ms latency |
| **Fallback chat** | `deepseek-coder:6.7b` | 16K context |
| **Embeddings** | `nomic-embed-text` | RAG & codebase search |
| **Custom** | User-defined | See Custom Models section |

### Tab Autocomplete

Starcoder2 is configured as the tab completion model with:
- `debounceDelay: 300ms` — fires 300ms after you stop typing
- `multilineCompletions: auto` — completes whole function bodies when confident
- `prefixPercentage: 0.85` — 85% prefix context, 15% suffix

### Context Providers

In Continue chat, type `@` to use:

| Provider | Usage | Description |
|----------|-------|-------------|
| `@codebase` | `@codebase how is auth handled?` | Searches full indexed project |
| `@file` | `@file src/auth.ts` | Includes a specific file |
| `@folder` | `@folder src/api` | Includes all files in a folder |
| `@tree` | `@tree` | Project file structure (4 levels) |
| `@diff` | `@diff` | Current git diff |
| `@url` | `@url https://docs.example.com` | Scrapes external documentation |

### Custom Slash Commands

| Command | Description |
|---------|-------------|
| `/review` | Security + bug + style review |
| `/docstring` | Generate complete docstring |
| `/migrate` | Refactor/migration plan |
| `/debug` | Debug strategy + root cause |

---

## Custom AI Models

Upload any `.gguf` model file and register it in Ollama.

```bash
chmod +x models/custom-model-upload.sh

# General purpose model
./models/custom-model-upload.sh ./my-model.gguf

# Code-specialised
./models/custom-model-upload.sh ./code-llm.gguf my-coder code

# Chat model
./models/custom-model-upload.sh ./chat-llm.gguf support-bot chat
```

### Templates

| Template | System prompt | Temperature | Best for |
|----------|--------------|-------------|---------|
| `code` | Expert software engineer | 0.1 | Code gen, review |
| `chat` | Helpful assistant | 0.7 | Q&A, support |
| `general` | Knowledgeable assistant | 0.5 | Mixed tasks |

After upload, the script prints the JSON snippet to add to `continue/config.json`.

### List Installed Models

```bash
docker exec atomia-ollama ollama list
```

---

## RAG — Code-Context Aware Indexing

The `rag-index.sh` script chunks your entire project and loads it into Qdrant so AI completions have full context of your codebase.

### Index a Project

```bash
chmod +x rag/rag-index.sh

# Index /projects (default)
./rag/rag-index.sh

# Index a specific project
./rag/rag-index.sh /projects/my-api my-api-collection
```

Or from inside Code Server's terminal:

```bash
rag-index                           # indexes /projects
rag-index /projects/my-api myapi   # indexes specific path
```

### What Gets Indexed

All source code and docs (excluding `node_modules`, `.git`, `dist`, `build`):

`.ts .tsx .js .jsx .py .go .rs .java .sh .md .json .yaml .sql .graphql .html .css` and more.

### Chunk Settings (`.env`)

```bash
RAG_CHUNK_SIZE=512      # tokens per chunk
RAG_CHUNK_OVERLAP=64    # overlap between consecutive chunks
RAG_EMBEDDING_MODEL=nomic-embed-text
```

### Use in Chat

After indexing, reference your project in Continue:

```
@codebase where is the JWT validation logic?
@codebase add error handling to the payment service
```

---

## Remote Debugging

Code Server exposes three debug ports on the host:

| Port | Protocol | For |
|------|----------|-----|
| `9229` | Chrome DevTools (DAP) | Node.js / TypeScript |
| `5678` | DAP | Python (debugpy) |
| `2345` | DAP | Go (delve) |

### VS Code Debug Configs

`debug-templates/launch.json` is automatically seeded into `/projects/.vscode/launch.json` on first start. It includes ready-to-use configurations for:

- **Node.js** — attach to running inspector / launch with debugger
- **Python** — attach to debugpy / launch script
- **Go** — attach to dlv / launch package
- **Docker** — attach to Node running inside any container
- **Chrome** — browser frontend debugging
- **Compound** — Node.js + Chrome simultaneously

### Node.js Example

Start your app with the inspector enabled:

```bash
# In Code Server terminal
node --inspect=0.0.0.0:9229 src/index.js
```

Then in the Debug panel, select **"Node.js: Attach (remote 9229)"** and press F5.

### Python Example

```python
# Add to top of your script
import debugpy
debugpy.listen(("0.0.0.0", 5678))
debugpy.wait_for_client()  # optional: block until VS Code attaches
```

Then select **"Python: Attach (remote 5678)"** and press F5.

### Go Example

```bash
# In Code Server terminal
dlv debug --headless --listen=:2345 --api-version=2 ./cmd/main.go
```

Then select **"Go: Attach (remote 2345)"** and press F5.

---

## Authentication (Authelia SSO)

### Default Users

| Username | Password | Groups |
|----------|----------|--------|
| `admin` | `atomia-admin` | admins, developers |
| `developer` | `developer123` | developers |

**Change these immediately:**

```bash
# Generate new hash
docker run --rm authelia/authelia:latest \
  authelia crypto hash generate argon2 --password 'YOUR_NEW_PASSWORD'
```

Edit `authelia/users_database.yml`, restart: `docker compose restart authelia`

### Access Policies

| Policy | Services | Auth Required |
|--------|---------|--------------|
| `bypass` | Internal network | None |
| `one_factor` | Open WebUI, Code Server | Password |
| `two_factor` | Grafana, Prometheus | Password + TOTP |

---

## GPU Configuration

```bash
# .env
NVIDIA_VISIBLE_DEVICES=all      # all GPUs; or "0,1" or "none" (CPU)
OLLAMA_MAX_LOADED_MODELS=2      # reduce on <12GB VRAM
OLLAMA_MEM_LIMIT=16G
```

Install NVIDIA Container Toolkit:

```bash
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" \
  | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

## Monitoring

- **Grafana** (http://localhost:3001) — pre-wired to Prometheus, import dashboard ID `14282` for container metrics
- **Alerts** — `monitoring/alerts.yml`: ContainerDown, HighCPU (>85%), HighMem (>90%), DiskLow (<20%)

---

## Automated Backups

```bash
chmod +x backup.sh
./backup.sh                        # manual run
BACKUP_PASSPHRASE=secret ./backup.sh   # with AES-256 encryption
```

Add a cron job for daily 3 AM runs:

```
0 3 * * * /path/to/atomia-cloud-suite/backup.sh
```

Off-site sync: set `RCLONE_REMOTE=s3:my-bucket` in `.env`.

---

## File Structure

```
.
├── docker-compose.yml          Core orchestration
├── setup.sh                    First-run installer
├── backup.sh                   Volume backup + rotation
├── code-server-init.sh         Code Server startup script
├── ssh-setup.sh                SSH key helper
│
├── authelia/                   SSO configuration
│   ├── configuration.yml
│   └── users_database.yml
│
├── continue/
│   └── config.json             AI models + context providers
│
├── deploy/                     Deployment pipelines
│   ├── deploy.sh               Universal deploy script
│   └── docker-compose.staging.yml
│
├── debug-templates/
│   └── launch.json             VS Code debug configs (Node/Python/Go)
│
├── models/
│   └── custom-model-upload.sh  Upload custom GGUF models
│
├── rag/
│   └── rag-index.sh            Project RAG indexer → Qdrant
│
├── monitoring/
│   ├── prometheus.yml
│   ├── alerts.yml
│   ├── grafana-datasources.yml
│   └── grafana-dashboards.yml
│
├── .gitea/workflows/
│   ├── auto-deploy.yml         Staging + production pipelines
│   ├── ci-pipeline.yml         Node.js CI
│   └── python-ci.yml           Python CI
│
└── data/                       All persistent volumes (git-ignored)
    ├── ollama/                 AI model weights
    ├── openwebui/              Chat history, users
    ├── qdrant/                 Vector embeddings
    ├── authelia/               Sessions, TOTP
    ├── gitea/                  Repos, issues, wiki
    └── grafana/                Dashboards
```

---

## Useful Commands

```bash
# Services
docker compose up -d
docker compose down
docker compose logs -f code-server

# AI Models
docker exec atomia-ollama ollama list
docker exec atomia-ollama ollama pull llama3.2
./models/custom-model-upload.sh my-model.gguf my-model code

# RAG Index
./rag/rag-index.sh /projects/my-app my-app

# Deploy
./deploy/deploy.sh staging http://localhost:3000/user/repo.git develop /projects/repo
./deploy/deploy.sh production http://localhost:3000/user/repo.git main /projects/repo

# Backup
./backup.sh

# Auth — regenerate password hash
docker run --rm authelia/authelia:latest \
  authelia crypto hash generate argon2 --password 'NEW_PASSWORD'

# Monitoring
open http://localhost:3001   # Grafana
open http://localhost:9090   # Prometheus
```

---

## License

MIT — free to use, modify, and self-host.
