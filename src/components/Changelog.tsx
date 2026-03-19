import { useState } from 'react'
import { ChevronDown } from 'lucide-react'

interface Release {
  version: string
  date: string
  tag: 'latest' | 'stable' | 'legacy'
  highlights: string[]
  changes: { type: 'feat' | 'fix' | 'perf' | 'break'; text: string }[]
}

const releases: Release[] = [
  {
    version: 'v4.1.0',
    date: 'March 2026',
    tag: 'latest',
    highlights: [
      'Automated deploy pipelines (staging + production)',
      'Gitea SSH key auto-injection into Code Server',
      'Custom GGUF model upload script',
      'Project RAG indexer (rag-index.sh)',
      'Remote debug ports for Node, Python, Go',
    ],
    changes: [
      { type: 'feat', text: 'deploy/deploy.sh — 5-step pipeline (pull → build → test → compose → healthcheck)' },
      { type: 'feat', text: '.gitea/workflows/auto-deploy.yml — branch-based staging/production dispatch' },
      { type: 'feat', text: 'code-server-init.sh — Gitea SSH key injection and SSH alias atomia-git' },
      { type: 'feat', text: 'continue/config.json — qwen2.5-coder:7b primary, starcoder2:3b tab autocomplete' },
      { type: 'feat', text: 'models/custom-model-upload.sh — upload GGUF with code/chat/general Modelfile templates' },
      { type: 'feat', text: 'rag/rag-index.sh — chunk + embed entire project into Qdrant collection' },
      { type: 'feat', text: 'debug-templates/launch.json — Node/Python/Go/Chrome remote debug configs' },
      { type: 'feat', text: 'docker-compose.yml — ports 9229/5678/2345 + all new scripts mounted' },
      { type: 'perf', text: 'Improved Prometheus alert rules with per-container thresholds' },
    ],
  },
  {
    version: 'v4.0.0',
    date: 'March 2026',
    tag: 'stable',
    highlights: [
      'Authelia SSO & MFA authentication gateway',
      'Persistent RAG with Qdrant vector store',
      'NVIDIA GPU auto-detection with CPU fallback',
      'Grafana auto-provisioned with Prometheus datasource',
      'AES-256 encrypted backup with rclone off-site sync',
    ],
    changes: [
      { type: 'feat', text: 'authelia/ — full SSO gateway with user DB and argon2id password hashing' },
      { type: 'feat', text: 'Open WebUI auth enforced; Qdrant now persists chat embeddings' },
      { type: 'feat', text: 'Ollama GPU auto-detection with configurable VRAM/CPU limits in .env' },
      { type: 'feat', text: 'monitoring/alerts.yml — ContainerDown, HighCPU, HighMem, DiskLow rules' },
      { type: 'feat', text: 'Grafana auto-provisioned datasource (no manual setup)' },
      { type: 'feat', text: 'backup.sh v2 — encryption, rclone off-site, rotation, manifest log' },
      { type: 'feat', text: 'setup.sh v4 — GPU check, model downloads, all dirs created' },
      { type: 'feat', text: 'continue/config.json — deepseek-coder:1.3b tab autocomplete + embeddings' },
      { type: 'perf', text: 'Reduced Ollama startup time via healthcheck tuning' },
    ],
  },
  {
    version: 'v3.1.0',
    date: 'February 2026',
    tag: 'legacy',
    highlights: [
      'Monitoring stack (Prometheus + Grafana + cAdvisor)',
      'Custom VS Code extension auto-install from URLs',
      'Continue.dev integration for AI tab completion',
      'backup.sh v1 with daily rotation',
    ],
    changes: [
      { type: 'feat', text: 'Added Prometheus, Grafana, and cAdvisor monitoring services' },
      { type: 'feat', text: 'code-server-init.sh — EXTENSION_URLS env var for remote .vsix install' },
      { type: 'feat', text: 'continue/config.json — deepseek-coder + codellama models configured' },
      { type: 'feat', text: 'backup.sh — 7-day retention with tar.gz compression' },
      { type: 'fix', text: 'Fixed Ollama container startup ordering with healthcheck conditions' },
      { type: 'fix', text: 'Resolved Docker bind-mount permission issues on macOS' },
    ],
  },
  {
    version: 'v2.0.0',
    date: 'January 2026',
    tag: 'legacy',
    highlights: [
      'Gitea self-hosted Git with CI/CD Actions',
      'Email SMTP notifications',
      'Qdrant vector database for RAG',
      'Nginx Proxy Manager with Let\'s Encrypt',
    ],
    changes: [
      { type: 'feat', text: 'Gitea + Act Runner for CI/CD pipelines' },
      { type: 'feat', text: 'SMTP email configuration for Gitea notifications' },
      { type: 'feat', text: 'Qdrant added as vector store for Open WebUI RAG' },
      { type: 'feat', text: 'Nginx Proxy Manager with SSL termination' },
      { type: 'break', text: 'Removed Portainer in favour of Grafana monitoring' },
    ],
  },
]

const typeColors = {
  feat:  'bg-sky-500/10 text-sky-400 border-sky-500/20',
  fix:   'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  perf:  'bg-amber-500/10 text-amber-400 border-amber-500/20',
  break: 'bg-red-500/10 text-red-400 border-red-500/20',
}

const tagColors = {
  latest: 'bg-sky-500/20 text-sky-300 border-sky-500/30',
  stable: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
  legacy: 'bg-slate-500/20 text-slate-400 border-slate-500/30',
}

export default function Changelog() {
  const [open, setOpen] = useState<string>(releases[0].version)

  return (
    <section id="changelog" className="py-24 px-4">
      <div className="max-w-4xl mx-auto">

        {/* Header */}
        <div className="text-center mb-12">
          <p className="text-sky-400 text-sm font-mono uppercase tracking-widest mb-3">Release history</p>
          <h2 className="text-4xl md:text-5xl font-semibold text-white tracking-tight mb-4">
            What's <span className="text-gradient">changed</span>
          </h2>
          <p className="text-slate-400 text-lg">
            Full changelog of every Atomia release with migration notes.
          </p>
        </div>

        {/* Accordion */}
        <div className="space-y-3">
          {releases.map(r => (
            <div
              key={r.version}
              className={`glass rounded-2xl overflow-hidden border transition-all duration-300 ${
                open === r.version ? 'border-sky-500/25' : 'border-transparent'
              }`}
            >
              {/* Header */}
              <button
                onClick={() => setOpen(open === r.version ? '' : r.version)}
                className="w-full flex items-center justify-between px-6 py-4 text-left group"
              >
                <div className="flex items-center gap-3 flex-wrap">
                  <span className="font-mono font-bold text-white text-lg">{r.version}</span>
                  <span className={`text-xs border px-2.5 py-0.5 rounded-full font-medium ${tagColors[r.tag]}`}>
                    {r.tag}
                  </span>
                  <span className="text-slate-500 text-sm">{r.date}</span>
                </div>
                <ChevronDown
                  className={`w-4 h-4 text-slate-400 flex-shrink-0 transition-transform duration-200 ${
                    open === r.version ? 'rotate-180 text-sky-400' : ''
                  }`}
                />
              </button>

              {/* Body */}
              {open === r.version && (
                <div className="px-6 pb-6">
                  {/* Highlights */}
                  <div className="mb-5">
                    <p className="text-slate-500 text-xs font-mono uppercase tracking-wider mb-3">Highlights</p>
                    <ul className="space-y-1.5">
                      {r.highlights.map(h => (
                        <li key={h} className="flex items-start gap-2 text-slate-300 text-sm">
                          <span className="text-sky-400 mt-0.5">→</span>
                          {h}
                        </li>
                      ))}
                    </ul>
                  </div>

                  {/* Commits */}
                  <div>
                    <p className="text-slate-500 text-xs font-mono uppercase tracking-wider mb-3">All changes</p>
                    <div className="space-y-2">
                      {r.changes.map((c, i) => (
                        <div key={i} className="flex items-start gap-2.5">
                          <span className={`text-[11px] font-mono font-medium border px-1.5 py-0.5 rounded flex-shrink-0 mt-0.5 ${typeColors[c.type]}`}>
                            {c.type}
                          </span>
                          <span className="text-slate-400 text-sm">{c.text}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        <p className="text-center text-slate-600 text-sm mt-6">
          Full commit history on{' '}
          <a
            href="https://github.com/HiTechTN/atomia-cloud-suite/commits/main"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sky-500 hover:text-sky-400 transition-colors"
          >
            GitHub →
          </a>
        </p>
      </div>
    </section>
  )
}
