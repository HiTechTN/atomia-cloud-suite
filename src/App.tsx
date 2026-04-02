import { useState } from 'react'
import Navbar from './components/Navbar'
import HeroSection from './components/HeroSection'
import FeatureGrid from './components/FeatureGrid'
import DownloadSection from './components/DownloadSection'
import InstallSteps from './components/InstallSteps'
import Changelog from './components/Changelog'
import ArchSection from './components/ArchSection'
import Footer from './components/Footer'
import Dashboard from './components/Dashboard'

export default function App() {
  const [view, setView] = useState<'landing' | 'dashboard'>('landing')

  if (view === 'dashboard') {
    return (
      <div className="min-h-screen bg-[#020B18]">
        <button 
          onClick={() => setView('landing')}
          className="fixed bottom-6 right-6 z-50 bg-sky-500 hover:bg-sky-400 text-white px-4 py-2 rounded-full shadow-lg text-sm font-medium transition-colors"
        >
          View Landing
        </button>
        <Dashboard />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#020B18] text-white">
      <Navbar onDashboard={() => setView('dashboard')} />
      <main>
        <HeroSection />
        <FeatureGrid />
        <DownloadSection />
        <InstallSteps />
        <ArchSection />
        <Changelog />
      </main>
      <Footer />
    </div>
  )
}
