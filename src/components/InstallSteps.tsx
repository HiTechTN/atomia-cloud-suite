import { useState } from 'react'
import { Check, Copy } from 'lucide-react'

function CodeBlock({ code, lang = 'bash' }: { code: string; lang?: string }) {
  const [copied, setCopied] = useState(false)
  const copy = async () => {
    await navigator.clipboard.writeText(code)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }
  return (
    <div className="mt-3 bg-[#010810] rounded-xl border border-white/8 overflow-hidden">
      <div className="flex items-center justify-between px-3 py-2 border-b border-white/5">
        <span className="text-xs text-slate-500 font-mono">{lang}</span>
        <button
          onClick={copy}
          className="flex items-center gap-1.5 text-xs text-slate-500 hover:text-sky-400 transition-colors"
        >
          {copied ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
          {copied ? 'Copied!' : 'Copy'}
        </button>
      </div>
      <pre className="p-4 text-[13px] text-slate-300 font-mono overflow-x-auto whitespace-pre-wrap leading-relaxed">
        {code}
      </pre>
    </div>
  )
}

const platforms = [
  {
    id: 'linux',
    label: '🐧 Linux',
    steps: [
      {
        n: 1,
        title: 'Install Docker',
        desc: 'Install Docker Engine and the Compose plugin on your Linux machine.',
        code: `curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
newgrp docker`,
      },
      {
        n: 2,
        title: 'Clone the repository',
        desc: 'Clone Atomia and copy the environment file.',
        code: `git clone https://github.com/HiTechTN/atomia-cloud-suite
cd atomia-cloud-suite
cp .env.example .env`,
      },
      {
        n: 3,
        title: 'Configure .env',
        desc: 'Edit the .env file and change all default passwords.',
        code: `# Required — change these
CODER_PASSWORD=your_strong_password
WEBUI_SECRET_KEY=change_this_secure_key_32chars_min
AUTHELIA_JWT_SECRET=$(openssl rand -hex 32)
AUTHELIA_SESSION_SECRET=$(openssl rand -hex 32)
AUTHELIA_STORAGE_KEY=$(openssl rand -hex 32)`,
        lang: 'env',
      },
      {
        n: 4,
        title: 'Run setup',
        desc: 'Run the automated setup script — it installs all images and downloads AI models.',
        code: `chmod +x setup.sh && ./setup.sh`,
      },
      {
        n: 5,
        title: 'Access your cloud',
        desc: 'Open your browser and navigate to any of the services.',
        code: `# Chat + AI    → http://localhost:8080
# Code IDE      → http://localhost:8443
# Git Server    → http://localhost:3000
# SSO Portal    → http://localhost:9091
# Monitoring    → http://localhost:3001`,
        lang: 'text',
      },
    ],
  },
  {
    id: 'macos',
    label: '🍎 macOS',
    steps: [
      {
        n: 1,
        title: 'Install Docker Desktop',
        desc: 'Download and install Docker Desktop for Mac (Apple Silicon or Intel).',
        code: `brew install --cask docker
# Then open Docker Desktop from Applications`,
      },
      {
        n: 2,
        title: 'Clone and configure',
        desc: 'Clone the repository and set up your environment variables.',
        code: `git clone https://github.com/HiTechTN/atomia-cloud-suite
cd atomia-cloud-suite
cp .env.example .env
# Edit .env with nano or your preferred editor
nano .env`,
      },
      {
        n: 3,
        title: 'Allocate resources',
        desc: 'In Docker Desktop → Settings → Resources, allocate at least 8 GB RAM and 4 CPUs.',
        code: `# Recommended Docker Desktop settings (Settings → Resources):
# Memory: 12 GB
# CPUs: 4
# Disk image size: 100 GB`,
        lang: 'text',
      },
      {
        n: 4,
        title: 'Run setup',
        code: `chmod +x setup.sh && ./setup.sh`,
        desc: 'The setup script pulls all images and downloads AI models into ./data/ollama.',
      },
    ],
  },
  {
    id: 'windows',
    label: '🪟 Windows',
    steps: [
      {
        n: 1,
        title: 'Enable WSL2',
        desc: 'Open PowerShell as Administrator and install WSL2 with Ubuntu.',
        code: `wsl --install -d Ubuntu
# Restart your computer when prompted`,
        lang: 'powershell',
      },
      {
        n: 2,
        title: 'Install Docker Desktop',
        desc: 'Download Docker Desktop and enable WSL2 integration in Settings → Resources → WSL Integration.',
        code: `# In PowerShell (as admin):
winget install Docker.DockerDesktop
# Open Docker Desktop → Settings → Resources → WSL Integration
# Enable for Ubuntu`,
        lang: 'powershell',
      },
      {
        n: 3,
        title: 'Clone inside WSL2',
        desc: 'All following commands run inside the WSL2 Ubuntu terminal.',
        code: `# Open Windows Terminal → Ubuntu
git clone https://github.com/HiTechTN/atomia-cloud-suite
cd atomia-cloud-suite
cp .env.example .env && nano .env`,
      },
      {
        n: 4,
        title: 'Run setup in WSL2',
        code: `chmod +x setup.sh && ./setup.sh`,
        desc: 'The setup script runs inside WSL2 and connects to Docker Desktop automatically.',
      },
      {
        n: 5,
        title: 'NVIDIA GPU (optional)',
        desc: 'Install CUDA and the NVIDIA Container Toolkit inside WSL2 for GPU acceleration.',
        code: `# Inside WSL2:
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L "https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list" \\
  | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo service docker restart`,
      },
    ],
  },
  {
    id: 'zimaos',
    label: '🧊 ZimaOS / CasaOS',
    steps: [
      {
        n: 1,
        title: 'Open Web Terminal',
        desc: 'Log in to your ZimaOS or CasaOS dashboard and open the Terminal / SSH.',
        code: `ssh admin@zimaos.local
# Or use the built-in terminal in the dashboard`,
      },
      {
        n: 2,
        title: 'Run One-Command Setup',
        desc: 'Run the Atomia setup script. It will automatically detect your NAS architecture and install everything.',
        code: `curl -fsSL https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/setup.sh | bash`,
      },
      {
        n: 3,
        title: 'Alternative: Custom App Install',
        desc: 'If you prefer the GUI, go to the App Store → Custom Install and paste the Docker Compose file.',
        code: `# 1. Go to App Store -> Custom Install
# 2. Select "Import"
# 3. Paste content from:
https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/docker-compose.yml`,
        lang: 'text',
      },
      {
        n: 4,
        title: 'Configure External Access',
        desc: 'If you want to access your IDE from outside your home network, configure the Nginx Proxy Manager included.',
        code: `# Open NPM: http://your-nas-ip:81
# Default login: admin@example.com / changeme`,
        lang: 'text',
      },
    ],
  },
  {
    id: 'glfos',
    label: '❄️ GLF-OS / NixOS',
    steps: [
      {
        n: 1,
        title: 'Enable Docker in Configuration',
        desc: 'Ensure Docker is enabled in your configuration.nix or via GLF-OS settings.',
        code: `virtualisation.docker.enable = true;
users.users.\${username}.extraGroups = [ "docker" ];`,
        lang: 'nix',
      },
      {
        n: 2,
        title: 'Run via Nix Flake (One-Shot)',
        desc: 'You can run the Atomia setup directly using Nix without cloning the repository.',
        code: `nix run github:HiTechTN/atomia-cloud-suite`,
      },
      {
        n: 3,
        title: 'Declarative Deployment (Module)',
        desc: 'For a permanent declarative setup, import the Atomia NixOS module into your system configuration.',
        code: `# flake.nix
inputs.atomia.url = "github:HiTechTN/atomia-cloud-suite";

# In your NixOS configuration
imports = [ inputs.atomia.nixosModules.default ];

services.atomia-cloud = {
  enable = true;
  domain = "atomia.local";
  gpuSupport = true;
};`,
        lang: 'nix',
      },
      {
        n: 4,
        title: 'Apply and Switch',
        desc: 'Rebuild your system to apply the changes and start the services.',
        code: `sudo nixos-rebuild switch --flake .`,
      },
    ],
  },
  {
    id: 'android',
    label: '📱 Android',
    steps: [
      {
        n: 1,
        title: 'Install Termux',
        desc: 'Download and install Termux from F-Droid (do not use Play Store version).',
        code: `# 1. Install F-Droid from f-droid.org
# 2. Search for "Termux" and install it
# 3. Open Termux and grant storage permissions:
termux-setup-storage`,
        lang: 'bash',
      },
      {
        n: 2,
        title: 'Update & Prerequisites',
        desc: 'Update packages and install basic tools required for the setup.',
        code: `pkg update && pkg upgrade -y
pkg install curl git nodejs-lts python -y`,
        lang: 'bash',
      },
      {
        n: 3,
        title: 'Install Linux Distro (Proot)',
        desc: 'Since Docker is hard on Android, we recommend using a Proot-distro for a full Linux environment.',
        code: `pkg install proot-distro -y
proot-distro install ubuntu
proot-distro login ubuntu`,
        lang: 'bash',
      },
      {
        n: 4,
        title: 'Run Atomia Setup',
        desc: 'Inside the Ubuntu environment, run the Atomia setup script.',
        code: `curl -fsSL https://raw.githubusercontent.com/HiTechTN/atomia-cloud-suite/main/setup.sh | bash`,
        lang: 'bash',
      },
      {
        n: 5,
        title: 'Access IDE/Chat',
        desc: 'Keep Termux running in the background and access Atomia via your mobile browser.',
        code: `# IDE: http://localhost:8443
# Chat: http://localhost:8080`,
        lang: 'text',
      },
    ],
  },
]

export default function InstallSteps() {
  const [active, setActive] = useState('linux')
  const platform = platforms.find(p => p.id === active)!

  return (
    <section id="install" className="py-24 px-4">
      <div className="max-w-4xl mx-auto">

        {/* Header */}
        <div className="text-center mb-12">
          <p className="text-sky-400 text-sm font-mono uppercase tracking-widest mb-3">Step by step</p>
          <h2 className="text-4xl md:text-5xl font-semibold text-white tracking-tight mb-4">
            Install <span className="text-gradient">anywhere</span>
          </h2>
          <p className="text-slate-400 text-lg">
            Follow the platform-specific guide below. Most setups complete in under 10 minutes.
          </p>
        </div>

        {/* Platform tabs */}
        <div className="flex flex-wrap justify-center gap-2 mb-10">
          {platforms.map(p => (
            <button
              key={p.id}
              onClick={() => setActive(p.id)}
              className={`px-5 py-2.5 rounded-xl text-sm font-medium border transition-all duration-200 ${
                active === p.id
                  ? 'bg-sky-500/20 border-sky-500/40 text-sky-300'
                  : 'bg-white/3 border-white/8 text-slate-400 hover:text-white hover:border-white/20'
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>

        {/* Steps */}
        <div className="space-y-4">
          {platform.steps.map((step) => (
            <div key={step.n} className="glass rounded-2xl overflow-hidden animate-fade-up">
              <div className="p-5">
                <div className="flex items-start gap-4">
                  <div className="flex-shrink-0 w-8 h-8 rounded-full bg-sky-500/15 border border-sky-500/30 flex items-center justify-center">
                    <span className="text-sky-400 text-xs font-mono font-bold">{step.n}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="text-white font-semibold text-[15px] mb-1">{step.title}</h3>
                    <p className="text-slate-400 text-sm">{step.desc}</p>
                    <CodeBlock code={step.code} lang={step.lang} />
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Success state */}
        <div className="mt-8 glass rounded-2xl p-5 border-l-2 border-emerald-500">
          <div className="flex items-start gap-3">
            <Check className="w-5 h-5 text-emerald-400 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-white font-medium text-sm">You're all set!</p>
              <p className="text-slate-400 text-sm mt-0.5">
                After setup completes, navigate to{' '}
                <code className="text-sky-400 font-mono text-xs bg-sky-500/10 px-1.5 py-0.5 rounded">http://localhost:8080</code>{' '}
                to access Atomia Chat, or{' '}
                <code className="text-sky-400 font-mono text-xs bg-sky-500/10 px-1.5 py-0.5 rounded">http://localhost:8443</code>{' '}
                for the IDE.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
