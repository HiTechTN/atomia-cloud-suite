import { ArrowDown, Download, Github, Star, GitFork } from 'lucide-react'

const GITHUB_URL = 'https://github.com/HiTechTN/atomia-cloud-suite'
const RELEASE_URL = 'https://github.com/HiTechTN/atomia-cloud-suite/releases/latest'

export default function HeroSection() {
  return (
    <section
      id="hero"
      className="relative min-h-screen flex flex-col items-center justify-center px-4 overflow-hidden bg-grid"
    >
      {/* Background glow orbs */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[500px] rounded-full bg-sky-500/5 blur-[120px] pointer-events-none" />
      <div className="absolute top-2/3 left-1/4 w-[400px] h-[300px] rounded-full bg-blue-600/5 blur-[80px] pointer-events-none" />

      <div className="relative z-10 text-center max-w-5xl mx-auto">

        {/* Badge */}
        <div className="inline-flex items-center gap-2 bg-sky-500/10 border border-sky-500/20 text-sky-300 text-xs font-mono px-4 py-1.5 rounded-full mb-8 animate-fade-up">
          <span className="w-1.5 h-1.5 rounded-full bg-sky-400 animate-pulse" />
          Latest Release — v4.1.0 · March 2026
        </div>

        {/* Headline */}
        <h1 className="font-semibold text-5xl sm:text-6xl md:text-7xl lg:text-8xl text-white leading-[1.08] tracking-tight mb-6 animate-fade-up stagger-1">
          Your Personal
          <br />
          <span className="text-gradient font-serif italic">AI Cloud</span>
          <br />
          <span className="text-white/70">in One Command</span>
        </h1>

        {/* Sub */}
        <p className="text-slate-400 text-lg md:text-xl max-w-2xl mx-auto leading-relaxed mb-10 animate-fade-up stagger-2">
          Self-hosted AI development environment — Ollama GPU backend, persistent RAG chat,
          browser IDE, Gitea, SSO auth, monitoring and automated deployments.
          100% open-source, zero dependencies on cloud providers.
        </p>

        {/* Stats row */}
        <div className="flex flex-wrap justify-center gap-6 mb-10 animate-fade-up stagger-2">
          {[
            { icon: Star, label: '100% Open Source' },
            { icon: GitFork, label: 'MIT License' },
            { icon: Download, label: 'Ready to Install' },
          ].map(({ icon: Icon, label }) => (
            <div key={label} className="flex items-center gap-1.5 text-slate-500 text-sm">
              <Icon className="w-3.5 h-3.5 text-sky-500" />
              {label}
            </div>
          ))}
        </div>

        {/* CTAs */}
        <div className="flex flex-wrap justify-center gap-4 mb-16 animate-fade-up stagger-3">
          <a
            href="#download"
            className="group relative inline-flex items-center gap-2.5 bg-sky-500 hover:bg-sky-400 text-white font-medium px-7 py-3.5 rounded-xl shadow-lg hover:shadow-sky-500/30 transition-all duration-300 hover:-translate-y-0.5"
          >
            <Download className="w-4 h-4" />
            Download v4.1.0
            <span className="absolute -top-2 -right-2 text-[10px] font-mono bg-emerald-500 text-white px-1.5 py-0.5 rounded-full leading-none">NEW</span>
          </a>
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2.5 bg-white/5 hover:bg-white/10 border border-white/10 hover:border-sky-500/40 text-white font-medium px-7 py-3.5 rounded-xl transition-all duration-300 hover:-translate-y-0.5"
          >
            <Github className="w-4 h-4" />
            View on GitHub
          </a>
        </div>

        {/* Quick start terminal */}
        <div className="max-w-2xl mx-auto glass rounded-2xl overflow-hidden animate-fade-up stagger-4 text-left">
          <div className="flex items-center gap-1.5 px-4 py-3 border-b border-white/5 bg-white/3">
            <span className="w-3 h-3 rounded-full bg-red-500/70" />
            <span className="w-3 h-3 rounded-full bg-yellow-500/70" />
            <span className="w-3 h-3 rounded-full bg-green-500/70" />
            <span className="ml-3 text-xs text-slate-500 font-mono">bash</span>
          </div>
          <div className="p-5 space-y-2 font-mono text-sm">
            <p>
              <span className="text-slate-500 select-none">$ </span>
              <span className="text-slate-300">git clone https://github.com/HiTechTN/atomia-cloud-suite</span>
            </p>
            <p>
              <span className="text-slate-500 select-none">$ </span>
              <span className="text-slate-300">cd atomia-cloud-suite && cp .env.example .env</span>
            </p>
            <p>
              <span className="text-slate-500 select-none">$ </span>
              <span className="text-sky-400">./setup.sh</span>
            </p>
            <p className="text-emerald-400 pt-1">✓ Atomia Cloud Suite is running!</p>
          </div>
        </div>
      </div>

      {/* Scroll indicator */}
      <a
        href="#features"
        className="absolute bottom-8 left-1/2 -translate-x-1/2 text-slate-600 hover:text-slate-400 transition-colors animate-bounce"
      >
        <ArrowDown className="w-5 h-5" />
      </a>
    </section>
  )
}
