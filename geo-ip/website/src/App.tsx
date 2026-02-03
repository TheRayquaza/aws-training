import { useState, useEffect, useRef } from 'react'
import * as d3 from 'd3'
import { feature } from 'topojson-client'
import './App.css'

interface IPEntry {
  ip: string
  country: string
  city: string
  visits: number
  lastSeen: string
  lat?: number
  lon?: number
}

function App() {
  const [leaderboard, setLeaderboard] = useState<IPEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [newIP, setNewIP] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [detectedIP, setDetectedIP] = useState<string | null>(null)
  const svgRef = useRef<SVGSVGElement>(null)
  const [worldData, setWorldData] = useState<any>(null)

  const API_BASE = 'https://your-api-gateway.amazonaws.com/prod'

  // Detect user's IP on page load
  useEffect(() => {
    const detectIP = async () => {
      try {
        // Using ipify API to detect user's IP
        const response = await fetch('https://api.ipify.org?format=json')
        const data = await response.json()
        setDetectedIP(data.ip)
        
        // Automatically track the detected IP
        if (data.ip) {
          await trackIP(data.ip)
        }
      } catch (err) {
        console.error('Failed to detect IP:', err)
      }
    }
    
    detectIP()
  }, [])

  // Load world map data
  useEffect(() => {
    const loadWorldData = async () => {
      try {
        const response = await fetch('https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json')
        const data = await response.json()
        setWorldData(data)
      } catch (err) {
        console.error('Failed to load world map:', err)
      }
    }
    
    loadWorldData()
  }, [])

  useEffect(() => {
    fetchLeaderboard()
    const interval = setInterval(fetchLeaderboard, 30000)
    return () => clearInterval(interval)
  }, [])

  // Draw the world map with IP locations
  useEffect(() => {
    if (!svgRef.current || !worldData || leaderboard.length === 0) return

    const svg = d3.select(svgRef.current)
    svg.selectAll('*').remove()

    const width = svgRef.current.clientWidth
    const height = svgRef.current.clientHeight

    const projection = d3.geoMercator()
      .scale(width / 6.5)
      .translate([width / 2, height / 1.5])

    const path = d3.geoPath().projection(projection)

    const countries = feature(worldData, worldData.objects.countries) as unknown as GeoJSON.FeatureCollection<GeoJSON.Geometry>

    // Draw countries
    svg.append('g')
      .selectAll('path')
      .data(countries.features)
      .enter()
      .append('path')
      .attr('d', path as any)
      .attr('fill', 'rgba(0, 255, 255, 0.05)')
      .attr('stroke', 'rgba(0, 255, 255, 0.3)')
      .attr('stroke-width', 0.5)
      .on('mouseenter', function() {
        d3.select(this)
          .attr('fill', 'rgba(0, 255, 255, 0.15)')
      })
      .on('mouseleave', function() {
        d3.select(this)
          .attr('fill', 'rgba(0, 255, 255, 0.05)')
      })

    // Draw IP locations
    const maxVisits = Math.max(...leaderboard.map(e => e.visits))

    leaderboard.forEach((entry, index) => {
      if (entry.lat && entry.lon) {
        const [x, y] = projection([entry.lon, entry.lat]) || [0, 0]
        
        // Pulsing circle for each IP
        const g = svg.append('g')
          .attr('class', 'ip-marker')
          .style('opacity', 0)
          .attr('transform', `translate(${x}, ${y})`)

        // Animated appearance
        g.transition()
          .delay(index * 50)
          .duration(500)
          .style('opacity', 1)

        // Outer pulse circle
        g.append('circle')
          .attr('r', 0)
          .attr('fill', 'none')
          .attr('stroke', '#00ffff')
          .attr('stroke-width', 2)
          .style('animation', `pulse 2s infinite ${index * 0.1}s`)

        // Inner dot
        const radius = 3 + (entry.visits / maxVisits) * 8
        g.append('circle')
          .attr('r', radius)
          .attr('fill', '#ff00ff')
          .attr('stroke', '#00ffff')
          .attr('stroke-width', 1.5)
          .style('filter', 'drop-shadow(0 0 5px #ff00ff)')

        // Tooltip
        g.append('title')
          .text(`${entry.ip}\n${entry.city}, ${entry.country}\n${entry.visits} visits`)

        // Click to highlight
        g.style('cursor', 'pointer')
          .on('click', () => {
            // Highlight the corresponding leaderboard entry
            const element = document.querySelector(`[data-ip="${entry.ip}"]`)
            element?.scrollIntoView({ behavior: 'smooth', block: 'center' })
          })
      }
    })

    // Add connection lines between points (optional visual effect)
    if (leaderboard.length > 1) {
      const lineGenerator = d3.line()
        .x(d => d[0])
        .y(d => d[1])
        .curve(d3.curveBundle.beta(0.5))

      for (let i = 0; i < Math.min(5, leaderboard.length - 1); i++) {
        const entry1 = leaderboard[i]
        const entry2 = leaderboard[i + 1]
        
        if (entry1.lat && entry1.lon && entry2.lat && entry2.lon) {
          const [x1, y1] = projection([entry1.lon, entry1.lat]) || [0, 0]
          const [x2, y2] = projection([entry2.lon, entry2.lat]) || [0, 0]
          
          svg.append('path')
            .datum([[x1, y1], [x2, y2]])
            .attr('d', lineGenerator as any)
            .attr('fill', 'none')
            .attr('stroke', 'rgba(255, 0, 255, 0.2)')
            .attr('stroke-width', 1)
            .style('opacity', 0)
            .transition()
            .delay(i * 200)
            .duration(1000)
            .style('opacity', 1)
        }
      }
    }

  }, [worldData, leaderboard])

  const fetchLeaderboard = async () => {
    try {
      const response = await fetch(`${API_BASE}/leaderboard`)
      if (!response.ok) throw new Error('Failed to fetch')
      const data = await response.json()
      setLeaderboard(data.leaderboard || [])
      setLoading(false)
    } catch (err) {
      console.error('Error fetching leaderboard:', err)
      setError('Failed to load leaderboard')
      setLoading(false)
    }
  }

  const trackIP = async (ipAddress: string) => {
    try {
      const response = await fetch(`${API_BASE}/track`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ip: ipAddress })
      })

      if (!response.ok) throw new Error('Failed to track IP')
      
      await fetchLeaderboard()
      return true
    } catch (err) {
      console.error('Error tracking IP:', err)
      return false
    }
  }

  const addIP = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newIP.trim()) return

    setSubmitting(true)
    setError('')

    const success = await trackIP(newIP.trim())
    
    if (success) {
      setNewIP('')
    } else {
      setError('Failed to track IP address')
    }
    
    setSubmitting(false)
  }

  const getFlag = (country: string) => {
    const flags: Record<string, string> = {
      'US': '🇺🇸', 'GB': '🇬🇧', 'DE': '🇩🇪', 'FR': '🇫🇷', 'JP': '🇯🇵',
      'CN': '🇨🇳', 'IN': '🇮🇳', 'BR': '🇧🇷', 'CA': '🇨🇦', 'AU': '🇦🇺'
    }
    return flags[country] || '🌐'
  }

  return (
    <div className="dashboard">
      <div className="scan-line"></div>
      <div className="grid-bg"></div>
      
      <header className="header">
        <div className="glitch" data-text="GEO.TRACK">GEO.TRACK</div>
        <div className="subtitle">Global IP Intelligence Network</div>
        {detectedIP && (
          <div className="detected-ip">
            YOUR IP: <span className="ip-highlight">{detectedIP}</span> — AUTO-TRACKED
          </div>
        )}
      </header>

      <div className="stats-bar">
        <div className="stat-item">
          <span className="stat-label">ACTIVE NODES</span>
          <span className="stat-value">{leaderboard.length}</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">TOTAL HITS</span>
          <span className="stat-value">
            {leaderboard.reduce((sum, entry) => sum + entry.visits, 0)}
          </span>
        </div>
        <div className="stat-item">
          <span className="stat-label">STATUS</span>
          <span className="stat-value blink">● LIVE</span>
        </div>
      </div>

      {/* World Map */}
      <div className="map-container">
        <svg ref={svgRef} className="world-map"></svg>
        <div className="map-legend">
          <div className="legend-item">
            <div className="legend-dot" style={{ background: '#ff00ff' }}></div>
            <span>Active IP Locations</span>
          </div>
          <div className="legend-item">
            <div className="legend-dot pulse-dot"></div>
            <span>Live Activity</span>
          </div>
        </div>
      </div>

      <form onSubmit={addIP} className="tracker-form">
        <div className="input-wrapper">
          <input
            type="text"
            value={newIP}
            onChange={(e) => setNewIP(e.target.value)}
            placeholder="ENTER IP ADDRESS TO TRACK..."
            className="ip-input"
            disabled={submitting}
          />
          <button 
            type="submit" 
            className="track-btn"
            disabled={submitting || !newIP.trim()}
          >
            {submitting ? 'TRACKING...' : '▶ TRACK'}
          </button>
        </div>
        {error && <div className="error-msg">{error}</div>}
      </form>

      <div className="leaderboard-container">
        <h2 className="section-title">
          <span className="title-icon">◆</span>
          GLOBAL LEADERBOARD
          <span className="title-icon">◆</span>
        </h2>

        {loading ? (
          <div className="loader">
            <div className="spinner"></div>
            <div>SCANNING NETWORK...</div>
          </div>
        ) : leaderboard.length === 0 ? (
          <div className="empty-state">
            NO TRACKED IPS YET
          </div>
        ) : (
          <div className="leaderboard">
            {leaderboard.map((entry, index) => (
              <div 
                key={entry.ip} 
                className="entry-card" 
                data-ip={entry.ip}
                style={{ animationDelay: `${index * 0.05}s` }}
              >
                <div className="entry-rank">#{index + 1}</div>
                <div className="entry-content">
                  <div className="entry-header">
                    <span className="entry-flag">{getFlag(entry.country)}</span>
                    <span className="entry-ip">{entry.ip}</span>
                    <span className="entry-visits">{entry.visits} HITS</span>
                  </div>
                  <div className="entry-details">
                    <span className="location">
                      {entry.city}, {entry.country}
                    </span>
                    {entry.lat && entry.lon && (
                      <span className="coords">
                        {entry.lat.toFixed(2)}°, {entry.lon.toFixed(2)}°
                      </span>
                    )}
                    <span className="timestamp">
                      LAST: {new Date(entry.lastSeen).toLocaleTimeString()}
                    </span>
                  </div>
                </div>
                <div className="entry-bar">
                  <div 
                    className="entry-bar-fill" 
                    style={{ 
                      width: `${Math.min(100, (entry.visits / Math.max(...leaderboard.map(e => e.visits))) * 100)}%` 
                    }}
                  ></div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <footer className="footer">
        <div className="terminal-line">
          &gt; System operational | Redis cache: ACTIVE | RDS sync: ENABLED
        </div>
      </footer>
    </div>
  )
}

export default App
