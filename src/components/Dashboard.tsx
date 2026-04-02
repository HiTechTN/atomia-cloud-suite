import { LayoutDashboard, MessageSquare, Code, Github, BarChart3, Settings, ShieldCheck, Cpu } from 'lucide-react'

const services = [
  {
    name: 'AI Chat',
    url: '/chat',
    icon: <MessageSquare className="w-6 h-6" />,
    color: 'bg-sky-500/20 text-sky-400 border-sky-500/30',
    desc: 'Local LLM with RAG support'
  },
  {
    name: 'VS Code IDE',
    url: '/ide',
    icon: <Code className="w-6 h-6" />,
    color: 'bg-violet-500/20 text-violet-400 border-violet-500/30',
    desc: 'Full browser-based development'
  },
  {
    name: 'Git Server',
    url: '/git',
    icon: <Github className="w-6 h-6" />,
    color: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
    desc: 'Self-hosted repositories & CI/CD'
  },
  {
    name: 'Monitoring',
    url: '/monitoring',
    icon: <BarChart3 className="w-6 h-6" />,
    color: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
    desc: 'System metrics & alerts'
  },
  {
    name: 'SSO Portal',
    url: '/sso',
    icon: <ShieldCheck className="w-6 h-6" />,
    color: 'bg-rose-500/20 text-rose-400 border-rose-500/30',
    desc: 'Auth & MFA Management'
  },
  {
    name: 'System',
    url: '/settings',
    icon: <Settings className="w-6 h-6" />,
    color: 'bg-slate-500/20 text-slate-400 border-slate-500/30',
    desc: 'Environment configuration'
  }
]

export default function Dashboard() {
  return (
    <div className="min-h-screen bg-[#020B18] p-4 md:p-8 animate-fade-in">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-white flex items-center gap-2">
              <Cpu className="text-sky-400" />
              Atomia Suite
            </h1>
            <p className="text-slate-400 text-sm">Personal Cloud Control Panel</p>
          </div>
          <div className="w-10 h-10 rounded-full bg-sky-500/10 border border-sky-500/20 flex items-center justify-center">
            <span className="text-sky-400 font-bold text-xs">AD</span>
          </div>
        </div>

        {/* Quick Stats (Mock) */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-8">
          {[
            { label: 'Ollama', value: 'Online', color: 'text-emerald-400' },
            { label: 'GPU', value: 'Ready', color: 'text-sky-400' },
            { label: 'Uptime', value: '99.9%', color: 'text-violet-400' },
            { label: 'Backups', value: 'Daily', color: 'text-amber-400' },
          ].map(stat => (
            <div key={stat.label} className="glass rounded-xl p-3 text-center">
              <p className="text-slate-500 text-[10px] uppercase tracking-wider">{stat.label}</p>
              <p className={`font-mono text-sm font-semibold ${stat.color}`}>{stat.value}</p>
            </div>
          ))}
        </div>

        {/* Services Grid */}
        <h2 className="text-white text-sm font-semibold mb-4 flex items-center gap-2">
          <LayoutDashboard className="w-4 h-4 text-sky-400" />
          Active Services
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {services.map(s => (
            <a
              key={s.name}
              href={s.url}
              className={`group flex items-center gap-4 p-4 rounded-2xl border transition-all duration-200 hover:scale-[1.02] active:scale-[0.98] ${s.color}`}
            >
              <div className="flex-shrink-0 w-12 h-12 rounded-xl bg-white/5 flex items-center justify-center group-hover:bg-white/10 transition-colors">
                {s.icon}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="text-white font-semibold text-base">{s.name}</h3>
                <p className="text-slate-400 text-xs truncate">{s.desc}</p>
              </div>
            </a>
          ))}
        </div>

        {/* Info Box */}
        <div className="mt-8 p-4 rounded-2xl bg-sky-500/5 border border-sky-500/10">
          <p className="text-xs text-slate-400 leading-relaxed text-center">
            Accessing from Android? Rotate your device or use <code className="text-sky-400 bg-sky-500/10 px-1 rounded">Desktop View</code> for the best IDE experience.
          </p>
        </div>
      </div>
    </div>
  )
}
