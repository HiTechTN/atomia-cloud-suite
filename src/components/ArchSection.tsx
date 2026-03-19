export default function ArchSection() {
  const arch = `
┌─────────────────────────────────────────────────────────────────────┐
│                    ATOMIA CLOUD SUITE v4.1                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────┐  ┌──────────────────┐  ┌────────────────────┐   │
│  │    OLLAMA     │◄─│  OPEN WEBUI      │  │  CODE SERVER       │   │
│  │  GPU / CPU    │  │  RAG + Chat      │  │  IDE + Debug       │   │
│  │  qwen2.5-coder│  │  ENABLE_AUTH     │  │  SSH + Extensions  │   │
│  │  starcoder2   │  │  ENABLE_RAG      │  │  Continue.dev AI   │   │
│  └───────┬───────┘  └────────┬─────────┘  └────────────────────┘   │
│          │                   │                                      │
│          ▼                   ▼                                      │
│  ┌───────────────┐  ┌──────────────────┐  ┌────────────────────┐   │
│  │    QDRANT     │  │    AUTHELIA      │  │  GITEA + RUNNER    │   │
│  │  Vector Store │  │  SSO / MFA       │  │  Git + CI/CD       │   │
│  │  RAG Embeddings│  │  argon2id users │  │  Auto-deploy       │   │
│  └───────────────┘  └────────┬─────────┘  └────────────────────┘   │
│                               │                                     │
│  ┌────────────────────────────▼───────────────────────────────┐    │
│  │          NGINX PROXY MANAGER  (SSL + Routes)               │    │
│  └───────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────┐  ┌────────────────┐  ┌──────────────────────┐    │
│  │  PROMETHEUS │──│    GRAFANA     │  │    CADVISOR          │    │
│  │  Metrics DB │  │  Dashboards    │  │  Container Metrics   │    │
│  └─────────────┘  └────────────────┘  └──────────────────────┘    │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │         BIND-MOUNTED VOLUMES  ./data/...                  │     │
│  │  ollama/ qdrant/ openwebui/ authelia/ gitea/ grafana/     │     │
│  └───────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘`

  const services = [
    { color: 'bg-sky-500', label: 'AI Stack', items: ['Ollama', 'Open WebUI', 'Qdrant', 'Continue.dev'] },
    { color: 'bg-violet-500', label: 'Dev Tools', items: ['Code Server', 'Gitea', 'Act Runner', 'SSH'] },
    { color: 'bg-emerald-500', label: 'Platform', items: ['Authelia', 'Nginx PM', 'Prometheus', 'Grafana'] },
  ]

  return (
    <section className="py-24 px-4">
      <div className="max-w-5xl mx-auto">

        <div className="text-center mb-12">
          <p className="text-sky-400 text-sm font-mono uppercase tracking-widest mb-3">How it fits together</p>
          <h2 className="text-4xl md:text-5xl font-semibold text-white tracking-tight mb-4">
            Architecture <span className="text-gradient">overview</span>
          </h2>
        </div>

        {/* ASCII diagram */}
        <div className="glass rounded-2xl overflow-hidden mb-8">
          <div className="flex items-center gap-1.5 px-4 py-3 border-b border-white/5">
            <span className="w-3 h-3 rounded-full bg-red-500/70" />
            <span className="w-3 h-3 rounded-full bg-yellow-500/70" />
            <span className="w-3 h-3 rounded-full bg-green-500/70" />
            <span className="ml-3 text-xs text-slate-500 font-mono">architecture</span>
          </div>
          <pre className="p-4 md:p-6 text-[11px] sm:text-[12px] text-sky-300/80 font-mono overflow-x-auto leading-[1.5]">
            {arch}
          </pre>
        </div>

        {/* Service legend */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {services.map(s => (
            <div key={s.label} className="glass rounded-xl p-4">
              <div className="flex items-center gap-2 mb-3">
                <div className={`w-2.5 h-2.5 rounded-full ${s.color}`} />
                <span className="text-white text-sm font-semibold">{s.label}</span>
              </div>
              <ul className="space-y-1">
                {s.items.map(item => (
                  <li key={item} className="text-slate-400 text-sm">{item}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
