import { Github, Terminal } from 'lucide-react'

const GITHUB = 'https://github.com/HiTechTN/atomia-cloud-suite'

export default function Footer() {
  const links = [
    { label: 'GitHub', href: GITHUB },
    { label: 'Releases', href: `${GITHUB}/releases` },
    { label: 'Issues', href: `${GITHUB}/issues` },
    { label: 'Wiki', href: `${GITHUB}/wiki` },
    { label: 'License', href: `${GITHUB}/blob/main/LICENSE` },
  ]

  return (
    <footer className="border-t border-white/5 py-12 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">

          {/* Brand */}
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-sky-400 to-blue-600 flex items-center justify-center">
              <Terminal className="w-4 h-4 text-white" />
            </div>
            <div>
              <p className="text-white font-semibold text-[15px] leading-none">Atomia Cloud Suite</p>
              <p className="text-slate-500 text-xs mt-0.5">v4.1.0 · MIT License</p>
            </div>
          </div>

          {/* Links */}
          <nav className="flex flex-wrap justify-center gap-x-6 gap-y-2">
            {links.map(l => (
              <a
                key={l.label}
                href={l.href}
                target="_blank"
                rel="noopener noreferrer"
                className="text-slate-500 hover:text-slate-300 text-sm transition-colors"
              >
                {l.label}
              </a>
            ))}
          </nav>

          {/* GitHub */}
          <a
            href={GITHUB}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors text-sm"
          >
            <Github className="w-4 h-4" />
            HiTechTN/atomia-cloud-suite
          </a>
        </div>

        <p className="text-center text-slate-700 text-xs mt-8">
          Built with Docker, Ollama, Gitea, Authelia, Prometheus and love. 100% self-hosted, zero cloud dependencies.
        </p>
      </div>
    </footer>
  )
}
