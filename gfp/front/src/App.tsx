import React, { useState, useEffect, useRef } from 'react';

// Types
interface Protein {
  id: string;
  name: string;
  pdb_id: string;
  description: string;
  created_at: string;
}

const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8080/api';

export default function App() {
  const [proteins, setProteins] = useState<Protein[]>([]);
  const [selectedProtein, setSelectedProtein] = useState<Protein | null>(null);
  const [isEditing, setIsEditing] = useState<string | null>(null); // Stores ID of protein being edited
  const [formData, setFormData] = useState({
    name: '',
    pdb_id: '',
    description: ''
  });
  const viewerRef = useRef<HTMLDivElement>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchProteins();
  }, []);

  const fetchProteins = async () => {
    try {
      const response = await fetch(`${API_BASE}/proteins`);
      const data = await response.json();
      setProteins(data || []);
    } catch (error) {
      console.error('Error fetching proteins:', error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const url = isEditing 
      ? `${API_BASE}/proteins/${isEditing}` 
      : `${API_BASE}/proteins`;
    const method = isEditing ? 'PUT' : 'POST';

    try {
      const response = await fetch(url, {
        method: method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });
      
      if (response.ok) {
        fetchProteins(); // Refresh list
        setFormData({ name: '', pdb_id: '', description: '' });
        setIsEditing(null);
      }
    } catch (error) {
      console.error('Error saving protein:', error);
    }
  };

  const deleteProtein = async (e: React.MouseEvent, id: string) => {
    e.stopPropagation(); // Prevent triggering visualization
    if (!window.confirm("Delete this molecule from records?")) return;

    try {
      await fetch(`${API_BASE}/proteins/${id}`, { method: 'DELETE' });
      setProteins(proteins.filter(p => p.id !== id));
      if (selectedProtein?.id === id) setSelectedProtein(null);
    } catch (error) {
      console.error('Error deleting protein:', error);
    }
  };

  const startEdit = (e: React.MouseEvent, protein: Protein) => {
    e.stopPropagation();
    setIsEditing(protein.id);
    setFormData({
      name: protein.name,
      pdb_id: protein.pdb_id,
      description: protein.description
    });
  };

  const visualizeProtein = async (protein: Protein) => {
    setSelectedProtein(protein);
    setLoading(true);

    try {
      const response = await fetch(`${API_BASE}/pdb?id=${protein.pdb_id}`);
      const pdbData = await response.text();

      if (viewerRef.current) {
        // @ts-ignore - 3Dmol is loaded via CDN
        const viewer = $3Dmol.createViewer(viewerRef.current, {
          backgroundColor: 'white'
        });
        viewer.addModel(pdbData, 'pdb');
        viewer.setStyle({}, { cartoon: { color: 'spectrum' } });
        viewer.zoomTo();
        viewer.render();
      }
    } catch (error) {
      console.error('Error visualizing protein:', error);
    } finally {
      setLoading(false);
    }
  };

return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #0f0f1e 0%, #1a1a2e 100%)',
      color: '#e0e0e0',
      fontFamily: '"JetBrains Mono", monospace',
      padding: '2rem'
    }}>
      <div style={{ maxWidth: '1400px', margin: '0 auto' }}>
        {/* Header same as yours */}
        <header style={{ marginBottom: '3rem', borderBottom: '2px solid #00ff88', paddingBottom: '1rem' }}>
          <h1 style={{ fontSize: '3rem', margin: 0, background: 'linear-gradient(90deg, #00ff88, #00ccff)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', fontWeight: 900 }}>
            PROTEIN LAB
          </h1>
        </header>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
          <div>
            {/* Form Section */}
            <div style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(0,255,136,0.3)', borderRadius: '8px', padding: '2rem', marginBottom: '2rem' }}>
              <h2 style={{ color: '#00ff88', marginTop: 0 }}>{isEditing ? 'Edit' : 'Register'} Protein</h2>
              <form onSubmit={handleSubmit}>
                {/* Inputs same as yours */}
                <input style={inputStyle} value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} placeholder="Name" required />
                <input style={inputStyle} value={formData.pdb_id} onChange={(e) => setFormData({ ...formData, pdb_id: e.target.value })} placeholder="PDB ID" required />
                <textarea style={inputStyle} value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} placeholder="Description" />
                
                <div style={{ display: 'flex', gap: '10px' }}>
                    <button type="submit" style={btnStyle}>{isEditing ? 'Update' : 'Register'}</button>
                    {isEditing && (
                        <button type="button" onClick={() => { setIsEditing(null); setFormData({name:'', pdb_id:'', description:''})}} style={{...btnStyle, background: '#444'}}>Cancel</button>
                    )}
                </div>
              </form>
            </div>

            {/* List Section */}
            <div style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(0,255,136,0.3)', borderRadius: '8px', padding: '2rem' }}>
              <h2 style={{ color: '#00ff88', marginTop: 0 }}>Registered Proteins</h2>
              <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
                {proteins.map((p) => (
                  <div key={p.id} onClick={() => visualizeProtein(p)} style={{ ...cardStyle, borderColor: selectedProtein?.id === p.id ? '#00ff88' : 'rgba(255,255,255,0.1)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <div>
                            <div style={{ color: '#00ff88', fontWeight: 'bold' }}>{p.name}</div>
                            <div style={{ color: '#00ccff', fontSize: '0.8rem' }}>{p.pdb_id}</div>
                        </div>
                        <div style={{ display: 'flex', gap: '10px' }}>
                            <button onClick={(e) => startEdit(e, p)} style={iconBtnStyle}>EDIT</button>
                            <button onClick={(e) => deleteProtein(e, p.id)} style={{...iconBtnStyle, color: '#ff4444'}}>DEL</button>
                        </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right Column - Visualization */}
          <div style={{
            background: 'rgba(255,255,255,0.05)',
            border: '1px solid rgba(0,255,136,0.3)',
            borderRadius: '8px',
            padding: '2rem',
            backdropFilter: 'blur(10px)',
            position: 'sticky',
            top: '2rem',
            height: 'fit-content'
          }}>
            <h2 style={{
              fontSize: '1.5rem',
              color: '#00ff88',
              marginTop: 0,
              marginBottom: '1.5rem',
              textTransform: 'uppercase',
              letterSpacing: '0.1em'
            }}>
              3D Visualization
            </h2>
            {selectedProtein ? (
              <>
                <div style={{ marginBottom: '1rem' }}>
                  <div style={{ 
                    fontSize: '1.2rem', 
                    color: '#00ff88',
                    fontWeight: 'bold'
                  }}>
                    {selectedProtein.name}
                  </div>
                  <div style={{ 
                    fontSize: '0.9rem', 
                    color: '#00ccff',
                    marginTop: '0.25rem'
                  }}>
                    PDB ID: {selectedProtein.pdb_id}
                  </div>
                </div>
                <div
                  ref={viewerRef}
                  style={{
                    width: '100%',
                    height: '500px',
                    background: 'white',
                    borderRadius: '4px',
                    border: '2px solid #00ff88',
                    position: 'relative'
                  }}
                >
                  {loading && (
                    <div style={{
                      position: 'absolute',
                      top: '50%',
                      left: '50%',
                      transform: 'translate(-50%, -50%)',
                      color: '#00ff88',
                      fontSize: '1.2rem',
                      fontWeight: 'bold'
                    }}>
                      Loading...
                    </div>
                  )}
                </div>
              </>
            ) : (
              <div style={{
                height: '500px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                border: '2px dashed rgba(0,255,136,0.3)',
                borderRadius: '4px',
                color: '#808080',
                fontSize: '1.1rem'
              }}>
                Select a protein to visualize
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// Reusable Styles
const inputStyle: React.CSSProperties = {
    width: '100%', padding: '0.75rem', background: 'rgba(0,0,0,0.3)', border: '1px solid rgba(0,255,136,0.2)', 
    borderRadius: '4px', color: '#e0e0e0', marginBottom: '1rem', fontFamily: 'inherit'
};

const btnStyle: React.CSSProperties = {
    flex: 1, padding: '1rem', background: 'linear-gradient(90deg, #00ff88, #00ccff)', border: 'none', 
    borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold', textTransform: 'uppercase'
};

const cardStyle: React.CSSProperties = {
    padding: '1rem', marginBottom: '0.5rem', background: 'rgba(0,0,0,0.2)', border: '1px solid', borderRadius: '4px', cursor: 'pointer'
};

const iconBtnStyle: React.CSSProperties = {
    background: 'none', border: '1px solid currentColor', borderRadius: '4px', color: '#888', 
    fontSize: '0.7rem', cursor: 'pointer', padding: '2px 6px'
};
