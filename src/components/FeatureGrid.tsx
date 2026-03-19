import {
  Brain, GitBranch, Code2, BarChart3, ShieldCheck,
  Zap, Database, Globe, RefreshCw
} from 'lucide-react'

const features = [
  {
    icon: Brain,
    color: 'from-sky-500 to-blue-600',
    glow: 'group-hover:shadow-sky-500/20',
    title: 'Local AI Models',
    desc: 'Ollama GPU backend with qwen2.5-coder, starcoder2, deepseek-coder and any custom GGUF model you upload.',
  },
  {
    icon: Code2,
    color: 'from-violet-500 to-purple-600',
    glow: 'group-hover:shadow-violet-500/20',
    title: 'Browser IDE',
    desc: 'Full VS Code Server with SSH, AI tab completion, remote debugging (Node/Python/Go) and auto-installed extensions.',
  },
  {
    icon: GitBranch,
    color: 'from-emerald-500 to-teal-600',
    glow: 'group-hover:shadow-emerald-500/20',
    title: 'Self-hosted Git',
    desc: 'Gitea with CI/CD Actions runner, auto-deploy pipelines, SSH key injection, and branch-based staging/production.',
  },
  {
    icon: Database,
    color: 'from-amber-500 to-orange-600',
    glow: 'group-hover:shadow-amber-500/20',
    title: 'Persistent RAG',
    desc: 'Qdrant vector store + nomic-embed-text indexes your entire codebase so AI answers reference your actual project.',
  },
  {
    icon: ShieldCheck,
    color: 'from-rose-500 to-pink-600',
    glow: 'group-hover:shadow-rose-500/20',
    title: 'SSO Authentication',
    desc: 'Authelia gateway with MFA, per-route policies, argon2id user DB, and TOTP support for all services.',
  },
  {
    icon: BarChart3,
    color: 'from-cyan-500 to-sky-600',
    glow: 'group-hover:shadow-cyan-500/20',
    title: 'Full Monitoring',
    desc: 'Prometheus + Grafana + cAdvisor with pre-built dashboards and alerts for CPU, RAM, disk, and container health.',
  },
  {
    icon: Zap,
    color: 'from-yellow-500 to-amber-600',
    glow: 'group-hover:shadow-yellow-500/20',
    title: 'GPU Acceleration',
    desc: 'Automatic NVIDIA GPU detection with graceful CPU fallback. Tune VRAM limits and loaded models via .env.',
  },
  {
    icon: RefreshCw,
    color: 'from-indigo-500 to-blue-600',
    glow: 'group-hover:shadow-indigo-500/20',
    title: 'Automated Backups',
    desc: 'Daily AES-256 encrypted volume backups with 7-day rotation, rclone off-site sync, and restore manifests.',
  },
  {
    icon: Globe,
    color: 'from-teal-500 to-emerald-600',
    glow: 'group-hover:shadow-teal-500/20',
    title: 'Reverse Proxy + SSL',
    desc: 'Nginx Proxy Manager with Let\'s Encrypt certificates, custom domains, and HTTP→HTTPS auto-redirect.',
  },
]

export default function FeatureGrid() {
  return (
    <section id="features" className="py-24 px-4">
      <div className="max-w-7xl mx-auto">

        {/* Header */}
        <div className="text-center mb-16">
          <p className="text-sky-400 text-sm font-mono uppercase tracking-widest mb-3">Everything included</p>
          <h2 className="text-4xl md:text-5xl font-semibold text-white tracking-tight mb-4">
            A complete cloud in <span className="text-gradient">one stack</span>
          </h2>
          <p className="text-slate-400 text-lg max-w-2xl mx-auto">
            No subscriptions. No vendor lock-in. Every service runs on your hardware,
            behind your firewall, under your control.
          </p>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {features.map((f, i) => {
            const Icon = f.icon
            return (
              <div
                key={f.title}
                className={`group glass glass-hover rounded-2xl p-6 animate-fade-up stagger-${Math.min(i + 1, 6)}`}
              >
                <div className={`w-11 h-11 rounded-xl bg-gradient-to-br ${f.color} flex items-center justify-center mb-4 shadow-lg group-hover:scale-110 transition-transform duration-300 group-hover:shadow-xl ${f.glow}`}>
                  <Icon className="w-5 h-5 text-white" />
                </div>
                <h3 className="text-white font-semibold text-[15px] mb-2">{f.title}</h3>
                <p className="text-slate-400 text-sm leading-relaxed">{f.desc}</p>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
