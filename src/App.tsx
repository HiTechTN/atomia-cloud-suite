import Navbar from './components/Navbar'
import HeroSection from './components/HeroSection'
import FeatureGrid from './components/FeatureGrid'
import DownloadSection from './components/DownloadSection'
import InstallSteps from './components/InstallSteps'
import Changelog from './components/Changelog'
import ArchSection from './components/ArchSection'
import Footer from './components/Footer'

export default function App() {
  return (
    <div className="min-h-screen bg-[#020B18] text-white">
      <Navbar />
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
