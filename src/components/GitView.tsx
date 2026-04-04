import { useState } from 'react'
import { GitBranch, GitCommit, GitPullRequest, Folder, File, ChevronRight, CheckCircle2, Circle, Plus, Send } from 'lucide-react'

interface Repo {
  id: string
  name: string
  branch: string
  lastCommit: string
  status: 'clean' | 'modified'
}

const mockRepos: Repo[] = [
  { id: '1', name: 'atomia-cloud-suite', branch: 'main', lastCommit: 'Merge pull request #42...', status: 'modified' },
  { id: '2', name: 'my-awesome-app', branch: 'develop', lastCommit: 'Initial commit', status: 'clean' },
]

export default function GitView() {
  const [selectedRepo, setSelectedRepo] = useState<Repo | null>(null)
  const [commitMsg, setCommitMsg] = useState('')

  if (selectedRepo) {
    return (
      <div className="animate-fade-in space-y-6">
        <div className="flex items-center justify-between">
          <button 
            onClick={() => setSelectedRepo(null)}
            className="text-sky-400 text-sm flex items-center gap-1 hover:underline"
          >
            ← Back to Repos
          </button>
          <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-sky-500/10 border border-sky-500/20">
            <GitBranch className="w-3 h-3 text-sky-400" />
            <span className="text-xs font-mono text-sky-400">{selectedRepo.branch}</span>
          </div>
        </div>

        <div className="glass rounded-2xl p-6">
          <h2 className="text-xl font-bold text-white mb-1">{selectedRepo.name}</h2>
          <p className="text-slate-400 text-xs flex items-center gap-1 mb-6">
            <GitCommit className="w-3 h-3" /> {selectedRepo.lastCommit}
          </p>

          <div className="space-y-4">
            <h3 className="text-white text-sm font-semibold flex items-center gap-2">
              <Folder className="w-4 h-4 text-sky-400" />
              Staged Changes
            </h3>
            <div className="space-y-2">
              {[
                { file: 'docker-compose.yml', type: 'modified' },
                { file: 'README.md', type: 'modified' },
              ].map(f => (
                <div key={f.file} className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5">
                  <div className="flex items-center gap-3">
                    <File className="w-4 h-4 text-slate-500" />
                    <span className="text-sm text-slate-300 font-mono">{f.file}</span>
                  </div>
                  <span className="text-[10px] uppercase tracking-wider text-amber-400 font-bold">{f.type}</span>
                </div>
              ))}
            </div>

            <div className="pt-4 border-t border-white/5">
              <textarea
                value={commitMsg}
                onChange={(e) => setCommitMsg(e.target.value)}
                placeholder="Commit message..."
                className="w-full h-24 bg-[#010810] border border-white/10 rounded-xl p-4 text-sm text-white placeholder:text-slate-600 focus:outline-none focus:border-sky-500/50"
              />
              <button 
                className="w-full mt-3 flex items-center justify-center gap-2 bg-sky-500 hover:bg-sky-400 text-white font-semibold py-3 rounded-xl transition-all active:scale-[0.98]"
              >
                <Send className="w-4 h-4" />
                Commit & Push
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="animate-fade-in space-y-4">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-white text-sm font-semibold flex items-center gap-2">
          <GitBranch className="w-4 h-4 text-emerald-400" />
          Repositories
        </h2>
        <button className="p-2 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 hover:bg-emerald-500/20 transition-colors">
          <Plus className="w-4 h-4" />
        </button>
      </div>

      <div className="grid gap-3">
        {mockRepos.map(repo => (
          <button
            key={repo.id}
            onClick={() => setSelectedRepo(repo)}
            className="flex items-center gap-4 p-4 rounded-2xl bg-white/5 border border-white/5 text-left transition-all hover:bg-white/10 hover:border-white/10 group"
          >
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${repo.status === 'clean' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'}`}>
              {repo.status === 'clean' ? <CheckCircle2 className="w-5 h-5" /> : <Circle className="w-5 h-5 fill-current opacity-50" />}
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="text-white font-semibold text-sm truncate">{repo.name}</h3>
              <p className="text-slate-500 text-xs font-mono">{repo.branch}</p>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-600 group-hover:text-slate-400 transition-colors" />
          </button>
        ))}
      </div>

      <div className="mt-8 p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10">
        <p className="text-xs text-slate-400 leading-relaxed text-center italic">
          Tip: Use the Git Server (Gitea) for full CI/CD management and PR reviews.
        </p>
      </div>
    </div>
  )
}
