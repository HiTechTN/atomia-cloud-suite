import { useState } from 'react'
import { Download, Copy, Check, ExternalLink } from 'lucide-react'

const GITHUB = 'https://github.com/HiTechTN/atomia-cloud-suite'
const VERSION = 'v4.1.0'

interface Platform {
  id: string
  label: string
  icon: string
  badge: string
  badgeColor: string
  requirements: string[]
  installCmd: string
  downloadLabel: string
  downloadUrl: string
  note?: string
}

const platforms: Platform[] = [
  {
    id: 'linux',
    label: 'Linux',
    icon: '🐧',
    badge: 'Recommended',
    badgeColor: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
    requirements: ['Docker Engine 24+', 'Docker Compose v2', '8 GB RAM minimum', 'NVIDIA drivers (optional GPU)'],
    installCmd: `curl -fsSL https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/setup.sh | bash`,
    downloadLabel: 'Download for Linux',
    downloadUrl: `${GITHUB}/releases/download/${VERSION}/atomia-cloud-suite-${VERSION}.tar.gz`,
  },
  {
    id: 'macos',
    label: 'macOS',
    icon: '🍎',
    badge: 'Apple Silicon & Intel',
    badgeColor: 'bg-sky-500/20 text-sky-400 border-sky-500/30',
    requirements: ['Docker Desktop 4.x+', 'macOS 13 Ventura+', '16 GB RAM recommended', 'Apple Silicon or Intel x86_64'],
    installCmd: `brew install docker docker-compose git && \\
git clone https://github.com/HiTechTN/atomia-cloud-suite && \\
cd atomia-cloud-suite && cp .env.example .env && ./setup.sh`,
    downloadLabel: 'Download for macOS',
    downloadUrl: `${GITHUB}/releases/download/${VERSION}/atomia-cloud-suite-${VERSION}.tar.gz`,
    note: 'GPU acceleration not available on macOS — Ollama runs in CPU mode.',
  },
  {
    id: 'windows',
    label: 'Windows',
    icon: '🪟',
    badge: 'WSL2 Required',
    badgeColor: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    requirements: ['Windows 11 / Windows 10 (21H2+)', 'WSL2 with Ubuntu 22.04', 'Docker Desktop + WSL2 backend', 'NVIDIA drivers + CUDA (optional GPU)'],
    installCmd: `# Run inside WSL2 Ubuntu terminal
curl -fsSL https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/setup.sh | bash`,
    downloadLabel: 'Download for Windows',
    downloadUrl: `${GITHUB}/releases/download/${VERSION}/atomia-cloud-suite-${VERSION}.zip`,
    note: 'Enable WSL2: wsl --install -d Ubuntu in PowerShell as Administrator.',
  },
  {
    id: 'zimaos',
    label: 'ZimaOS / CasaOS',
    icon: '🧊',
    badge: 'NAS / Home Server',
    badgeColor: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
    requirements: ['ZimaCube, ZimaBoard or Any x86 NAS', 'ZimaOS 1.1+ or CasaOS installed', 'Storage: 100GB+ recommended', 'Admin access to WebUI'],
    installCmd: `curl -fsSL https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/setup.sh | bash`,
    downloadLabel: 'Download Compose YAML',
    downloadUrl: `${GITHUB}/blob/main/docker-compose.yml`,
    note: 'You can also install by clicking "Custom Install" in the App Store and pasting the Docker Compose content.',
  },
  {
    id: 'glfos',
    label: 'GLF-OS / NixOS',
    icon: '❄️',
    badge: 'Declarative OS',
    badgeColor: 'bg-blue-400/20 text-blue-300 border-blue-400/30',
    requirements: ['GLF-OS or NixOS stable/unstable', 'Docker or Podman enabled', 'Nix Flakes enabled', 'NVIDIA Container Toolkit (for GPU)'],
    installCmd: `nix run github:HiTechTN/atomia-cloud-suite`,
    downloadLabel: 'View Nix Flake',
    downloadUrl: `${GITHUB}/blob/main/flake.nix`,
    note: 'GLF-OS provides a declarative environment. Use the provided Nix module for the most integrated experience.',
  },
  {
    id: 'android',
    label: 'Android',
    icon: '📱',
    badge: 'Termux / Proot',
    badgeColor: 'bg-green-500/20 text-green-400 border-green-500/30',
    requirements: ['Android 10+', 'Termux (F-Droid version)', '10GB+ Free Storage', 'High-end SoC (8 Gen 1+)'],
    installCmd: `pkg update && pkg install curl -y && curl -fsSL https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/setup.sh | bash`,
    downloadLabel: 'Download Termux',
    downloadUrl: `https://f-droid.org/en/packages/com.termux/`,
    note: 'Docker on Android requires Proot-distro or a rooted device. Heavy AI models may be slow.',
  },
  {
    id: 'docker',
    label: 'Docker Only',
    icon: '🐳',
    badge: 'Any Platform',
    badgeColor: 'bg-violet-500/20 text-violet-400 border-violet-500/30',
    requirements: ['Docker Engine or Docker Desktop', 'Docker Compose v2', 'Git', '4 GB RAM minimum'],
    installCmd: `git clone https://github.com/HiTechTN/atomia-cloud-suite
cd atomia-cloud-suite
cp .env.example .env
# Edit .env with your passwords
docker compose up -d`,
    downloadLabel: 'Clone Repository',
    downloadUrl: GITHUB,
    note: 'Use this if you already have Docker installed and want manual control over setup.',
  },
]

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)
  const copy = async () => {
    await navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }
  return (
    <button
      onClick={copy}
      className="flex-shrink-0 p-2 rounded-lg bg-white/5 hover:bg-sky-500/20 border border-white/10 hover:border-sky-500/30 text-slate-400 hover:text-sky-400 transition-all duration-200"
      title="Copy command"
    >
      {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
    </button>
  )
}

export default function DownloadSection() {
  const [active, setActive] = useState('linux')
  const platform = platforms.find(p => p.id === active)!

  return (
    <section id="download" className="py-24 px-4">
      <div className="max-w-5xl mx-auto">

        {/* Header */}
        <div className="text-center mb-12">
          <p className="text-sky-400 text-sm font-mono uppercase tracking-widest mb-3">One command install</p>
          <h2 className="text-4xl md:text-5xl font-semibold text-white tracking-tight mb-4">
            Choose your <span className="text-gradient">platform</span>
          </h2>
          <p className="text-slate-400 text-lg">
            Atomia runs anywhere Docker runs. Pick your OS and follow the instructions below.
          </p>
        </div>

        {/* Platform tabs */}
        <div className="flex flex-wrap justify-center gap-2 mb-8">
          {platforms.map(p => (
            <button
              key={p.id}
              onClick={() => setActive(p.id)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium border transition-all duration-200 ${
                active === p.id
                  ? 'bg-sky-500/20 border-sky-500/40 text-sky-300'
                  : 'bg-white/3 border-white/8 text-slate-400 hover:text-white hover:border-white/20'
              }`}
            >
              <span>{p.icon}</span>
              {p.label}
            </button>
          ))}
        </div>

        {/* Content card */}
        <div className="glass rounded-2xl overflow-hidden animate-fade-in">

          {/* Card header */}
          <div className="px-6 py-4 border-b border-white/5 flex flex-wrap items-center gap-3">
            <span className="text-2xl">{platform.icon}</span>
            <span className="text-lg font-semibold text-white">{platform.label}</span>
            <span className={`text-xs font-medium border px-2.5 py-0.5 rounded-full ${platform.badgeColor}`}>
              {platform.badge}
            </span>
            <div className="ml-auto">
              <a
                href={platform.downloadUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 bg-sky-500 hover:bg-sky-400 text-white text-sm font-medium px-4 py-2 rounded-lg transition-all duration-200 hover:shadow-lg hover:shadow-sky-500/25 hover:-translate-y-0.5"
              >
                <Download className="w-3.5 h-3.5" />
                {platform.downloadLabel}
                <ExternalLink className="w-3 h-3 opacity-70" />
              </a>
            </div>
          </div>

          <div className="p-6 grid md:grid-cols-2 gap-6">

            {/* Requirements */}
            <div>
              <h4 className="text-white text-sm font-semibold mb-3 flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
                Requirements
              </h4>
              <ul className="space-y-2">
                {platform.requirements.map(r => (
                  <li key={r} className="flex items-center gap-2 text-slate-400 text-sm">
                    <Check className="w-3.5 h-3.5 text-emerald-400 flex-shrink-0" />
                    {r}
                  </li>
                ))}
              </ul>
            </div>

            {/* Install command */}
            <div>
              <h4 className="text-white text-sm font-semibold mb-3 flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
                Install Command
              </h4>
              <div className="bg-[#010810] rounded-xl border border-white/8 overflow-hidden">
                <div className="flex items-center justify-between px-3 py-2 border-b border-white/5">
                  <div className="flex gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-red-500/60" />
                    <span className="w-2.5 h-2.5 rounded-full bg-yellow-500/60" />
                    <span className="w-2.5 h-2.5 rounded-full bg-green-500/60" />
                  </div>
                  <CopyButton text={platform.installCmd} />
                </div>
                <pre className="p-4 text-[13px] text-sky-300 font-mono overflow-x-auto whitespace-pre-wrap leading-relaxed">
                  {platform.installCmd}
                </pre>
              </div>
              {platform.note && (
                <p className="mt-3 text-xs text-amber-400/80 bg-amber-500/5 border border-amber-500/15 rounded-lg px-3 py-2">
                  ⚠ {platform.note}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* After install */}
        <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { port: '8080', label: 'AI Chat', color: 'text-sky-400' },
            { port: '8443', label: 'Code IDE', color: 'text-violet-400' },
            { port: '3000', label: 'Git Server', color: 'text-emerald-400' },
            { port: '3001', label: 'Monitoring', color: 'text-amber-400' },
          ].map(s => (
            <div key={s.port} className="glass rounded-xl px-4 py-3 text-center">
              <p className={`font-mono text-sm font-semibold ${s.color}`}>:{s.port}</p>
              <p className="text-slate-500 text-xs mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
