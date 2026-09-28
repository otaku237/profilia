'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import styles from './admin.module.css'

type Stats = {
  totalUsers: number
  totalConversations: number
  totalMessages: number
  userMessages: number
  aiMessages: number
  profileBreakdown: Record<string, number>
  recentUsers: { id: string; name: string; profile_type: string; created_at: string }[]
  avgConvsPerUser: string | number
}

const PROFILE_ICONS: Record<string, string> = {
  'Ingénieur informatique': '💻', 'Médecin': '🩺', 'Étudiant': '📚',
  'Entrepreneur': '🚀', 'Juriste': '⚖️', 'Enseignant': '🎓',
  'Comptable': '📊', 'Architecte': '🏛️',
}

export default function AdminPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  useEffect(() => { loadStats() }, [])

  async function loadStats() {
    setLoading(true)
    const res = await fetch('/api/admin')
    if (res.status === 403) { setError('Accès refusé — vous n\'êtes pas admin'); setLoading(false); return }
    const data = await res.json()
    setStats(data); setLoading(false)
  }

  if (loading) return (
    <div className={styles.page}>
      <div className={styles.loading}><span className={styles.spinner} /> Chargement des stats...</div>
    </div>
  )

  if (error) return (
    <div className={styles.page}>
      <div className={styles.errorBox}>
        <div>🔒</div>
        <p>{error}</p>
        <button onClick={() => router.push('/chat')} className={styles.backBtn}>← Retour au chat</button>
      </div>
    </div>
  )

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div>
          <h1>⚡ Dashboard Admin</h1>
          <p>Vue d'ensemble de ProfilIA</p>
        </div>
        <button onClick={() => router.push('/chat')} className={styles.backBtn}>← Chat</button>
      </div>

      {/* KPIs */}
      <div className={styles.kpis}>
        {[
          { label: 'Utilisateurs', value: stats!.totalUsers, icon: '👥', color: '#6C63FF' },
          { label: 'Conversations', value: stats!.totalConversations, icon: '💬', color: '#10B981' },
          { label: 'Messages totaux', value: stats!.totalMessages, icon: '✉️', color: '#F59E0B' },
          { label: 'Moy. conv/user', value: stats!.avgConvsPerUser, icon: '📈', color: '#3B82F6' },
        ].map(k => (
          <div key={k.label} className={styles.kpi} style={{ '--c': k.color } as any}>
            <div className={styles.kpiIcon}>{k.icon}</div>
            <div className={styles.kpiValue}>{k.value}</div>
            <div className={styles.kpiLabel}>{k.label}</div>
          </div>
        ))}
      </div>

      <div className={styles.row}>
        {/* Profils */}
        <div className={styles.card}>
          <h2>Répartition des profils</h2>
          <div className={styles.profileList}>
            {Object.entries(stats!.profileBreakdown)
              .sort(([, a], [, b]) => b - a)
              .map(([profile, count]) => {
                const pct = Math.round((count / stats!.totalUsers) * 100)
                return (
                  <div key={profile} className={styles.profileRow}>
                    <span className={styles.profileIcon}>{PROFILE_ICONS[profile] || '👤'}</span>
                    <div className={styles.profileBar}>
                      <div className={styles.profileBarLabel}>
                        <span>{profile}</span>
                        <span>{count} ({pct}%)</span>
                      </div>
                      <div className={styles.barTrack}>
                        <div className={styles.barFill} style={{ width: `${pct}%` }} />
                      </div>
                    </div>
                  </div>
                )
              })}
          </div>
        </div>

        {/* Messages */}
        <div className={styles.card}>
          <h2>Activité messages</h2>
          <div className={styles.messageStats}>
            <div className={styles.msgStat}>
              <div className={styles.msgStatValue} style={{ color: '#6C63FF' }}>{stats!.userMessages}</div>
              <div className={styles.msgStatLabel}>Messages utilisateurs</div>
            </div>
            <div className={styles.msgDivider} />
            <div className={styles.msgStat}>
              <div className={styles.msgStatValue} style={{ color: '#10B981' }}>{stats!.aiMessages}</div>
              <div className={styles.msgStatLabel}>Réponses IA</div>
            </div>
          </div>
          <div className={styles.ratio}>
            <div className={styles.ratioBar}>
              <div className={styles.ratioUser} style={{ width: `${Math.round(stats!.userMessages / stats!.totalMessages * 100)}%` }} />
              <div className={styles.ratioAi} style={{ width: `${Math.round(stats!.aiMessages / stats!.totalMessages * 100)}%` }} />
            </div>
            <div className={styles.ratioLabels}>
              <span style={{ color: '#6C63FF' }}>● Utilisateurs</span>
              <span style={{ color: '#10B981' }}>● IA</span>
            </div>
          </div>
        </div>
      </div>

      {/* Derniers inscrits */}
      <div className={styles.card}>
        <h2>Derniers utilisateurs inscrits</h2>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Nom</th>
              <th>Profil</th>
              <th>Inscrit le</th>
            </tr>
          </thead>
          <tbody>
            {stats!.recentUsers.map(u => (
              <tr key={u.id}>
                <td>{u.name}</td>
                <td><span className={styles.badge}>{PROFILE_ICONS[u.profile_type]} {u.profile_type}</span></td>
                <td className={styles.dateCell}>{new Date(u.created_at).toLocaleDateString('fr-FR')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Export */}
      <div className={styles.card}>
        <h2>Export des données</h2>
        <p style={{ color: 'var(--text3)', fontSize: 13, marginBottom: 12 }}>Télécharger toutes les conversations de la plateforme</p>
        <div className={styles.exportBtns}>
          <a href="/api/export?format=json" download className={styles.exportBtn}>📦 JSON</a>
          <a href="/api/export?format=markdown" download className={styles.exportBtn}>📝 Markdown</a>
          <a href="/api/export?format=txt" download className={styles.exportBtn}>📄 Texte</a>
        </div>
      </div>
    </div>
  )
}
