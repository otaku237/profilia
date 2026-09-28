'use client'
import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { PROFILES, ProfileType } from '@/lib/profiles'
import styles from './settings.module.css'

export default function SettingsPage() {
  const [name, setName] = useState('')
  const [profile, setProfile] = useState<ProfileType | null>(null)
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [email, setEmail] = useState('')
  const [profileMsg, setProfileMsg] = useState('')
  const [passwordMsg, setPasswordMsg] = useState('')
  const [loading, setLoading] = useState(false)
  const [tab, setTab] = useState<'profile' | 'security' | 'danger'>('profile')
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => { loadUser() }, [])

  async function loadUser() {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    setEmail(user.email || '')
    const { data } = await supabase.from('profiles').select('name, profile_type').eq('id', user.id).single()
    if (data) { setName(data.name); setProfile(data.profile_type as ProfileType) }
  }

  async function saveProfile(e: React.FormEvent) {
    e.preventDefault()
    if (!profile) return
    setLoading(true); setProfileMsg('')
    const { data: { user } } = await supabase.auth.getUser()
    const { error } = await supabase.from('profiles').update({ name, profile_type: profile }).eq('id', user!.id)
    setLoading(false)
    setProfileMsg(error ? '❌ Erreur : ' + error.message : '✅ Profil mis à jour !')
  }

  async function changePassword(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true); setPasswordMsg('')
    const { error } = await supabase.auth.updateUser({ password: newPassword })
    setLoading(false)
    setPasswordMsg(error ? '❌ ' + error.message : '✅ Mot de passe mis à jour !')
    if (!error) { setCurrentPassword(''); setNewPassword('') }
  }

  async function deleteAccount() {
    if (!confirm('Supprimer définitivement votre compte et toutes vos données ? Cette action est irréversible.')) return
    // Supprimer les données, puis déconnecter (l'admin API supprime l'utilisateur)
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      await supabase.from('conversations').delete().eq('user_id', user.id)
      await supabase.from('profiles').delete().eq('id', user.id)
    }
    await supabase.auth.signOut()
    router.push('/auth')
  }

  return (
    <div className={styles.page}>
      <div className={styles.container}>
        <div className={styles.back}>
          <button onClick={() => router.push('/chat')} className={styles.backBtn}>← Retour au chat</button>
        </div>

        <div className={styles.header}>
          <div className={styles.headerIcon}>⚙️</div>
          <div>
            <h1>Paramètres</h1>
            <p>{email}</p>
          </div>
        </div>

        <div className={styles.tabs}>
          {(['profile', 'security', 'danger'] as const).map(t => (
            <button key={t} className={`${styles.tab} ${tab === t ? styles.active : ''} ${t === 'danger' ? styles.dangerTab : ''}`} onClick={() => setTab(t)}>
              {t === 'profile' ? '👤 Profil' : t === 'security' ? '🔒 Sécurité' : '⚠️ Danger'}
            </button>
          ))}
        </div>

        {tab === 'profile' && (
          <form onSubmit={saveProfile} className={styles.card}>
            <h2>Informations personnelles</h2>
            <div className={styles.field}>
              <label>Nom complet</label>
              <input value={name} onChange={e => setName(e.target.value)} placeholder="Votre nom" required />
            </div>
            <div className={styles.field}>
              <label>Profil professionnel</label>
              <p className={styles.hint}>Changer votre profil adapte le comportement de l'IA</p>
              <div className={styles.profiles}>
                {PROFILES.map(p => (
                  <button key={p.type} type="button"
                    className={`${styles.profileBtn} ${profile === p.type ? styles.selected : ''}`}
                    style={{ '--c': p.color } as any}
                    onClick={() => setProfile(p.type)}>
                    <span>{p.icon}</span>
                    <span className={styles.pName}>{p.type}</span>
                  </button>
                ))}
              </div>
            </div>
            {profileMsg && <div className={`${styles.msg} ${profileMsg.startsWith('✅') ? styles.success : styles.error}`}>{profileMsg}</div>}
            <button type="submit" className={styles.btnPrimary} disabled={loading}>
              {loading ? <span className={styles.spinner} /> : 'Enregistrer'}
            </button>
          </form>
        )}

        {tab === 'security' && (
          <form onSubmit={changePassword} className={styles.card}>
            <h2>Changer le mot de passe</h2>
            <div className={styles.field}>
              <label>Nouveau mot de passe</label>
              <input type="password" value={newPassword} onChange={e => setNewPassword(e.target.value)} placeholder="••••••••" required minLength={6} />
            </div>
            {passwordMsg && <div className={`${styles.msg} ${passwordMsg.startsWith('✅') ? styles.success : styles.error}`}>{passwordMsg}</div>}
            <button type="submit" className={styles.btnPrimary} disabled={loading || !newPassword}>
              {loading ? <span className={styles.spinner} /> : 'Mettre à jour le mot de passe'}
            </button>
          </form>
        )}

        {tab === 'danger' && (
          <div className={styles.card}>
            <h2 style={{ color: '#EF4444' }}>Zone de danger</h2>
            <div className={styles.dangerBox}>
              <div>
                <strong>Supprimer mon compte</strong>
                <p>Supprime définitivement votre compte, toutes vos conversations et messages. Cette action est irréversible.</p>
              </div>
              <button onClick={deleteAccount} className={styles.btnDanger}>Supprimer mon compte</button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
