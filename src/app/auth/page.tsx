'use client'
import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { PROFILES, ProfileType } from '@/lib/profiles'
import styles from './auth.module.css'

export default function AuthPage() {
  const [mode, setMode] = useState<'login' | 'signup'>('login')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [profile, setProfile] = useState<ProfileType | null>(null)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(''); setSuccess('')
    setLoading(true)
    try {
      if (mode === 'signup') {
        if (!profile) { setError('Choisissez votre profil professionnel'); setLoading(false); return }
        const { error } = await supabase.auth.signUp({
          email, password,
          options: { data: { name, profile_type: profile } }
        })
        if (error) throw error
        setSuccess('Compte créé ! Vérifiez votre email pour confirmer.')
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email, password })
        if (error) throw error
        router.push('/chat'); router.refresh()
      }
    } catch (err: any) {
      const msg = err.message || 'Une erreur est survenue'
      setError(msg.includes('Invalid login') ? 'Email ou mot de passe incorrect' : msg)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.page}>
      <div className={styles.bg}>
        {[...Array(6)].map((_, i) => <div key={i} className={styles.blob} style={{ '--i': i } as any} />)}
      </div>
      <div className={styles.card}>
        <div className={styles.logo}>
          <span className={styles.logoIcon}>⚡</span>
          <span className={styles.logoText}>ProfilIA</span>
        </div>
        <p className={styles.tagline}>L'IA qui s'adapte à votre métier</p>

        <div className={styles.tabs}>
          <button className={`${styles.tab} ${mode === 'login' ? styles.active : ''}`} onClick={() => { setMode('login'); setError(''); setSuccess('') }}>Connexion</button>
          <button className={`${styles.tab} ${mode === 'signup' ? styles.active : ''}`} onClick={() => { setMode('signup'); setError(''); setSuccess('') }}>Inscription</button>
        </div>

        <form onSubmit={handleSubmit} className={styles.form}>
          {mode === 'signup' && (
            <div className={styles.field}>
              <label>Nom complet</label>
              <input type="text" placeholder="Jean Dupont" value={name} onChange={e => setName(e.target.value)} required />
            </div>
          )}
          <div className={styles.field}>
            <label>Email</label>
            <input type="email" placeholder="vous@exemple.com" value={email} onChange={e => setEmail(e.target.value)} required />
          </div>
          <div className={styles.field}>
            <label>Mot de passe</label>
            <input type="password" placeholder="••••••••" value={password} onChange={e => setPassword(e.target.value)} required minLength={6} />
          </div>

          {mode === 'signup' && (
            <div className={styles.field}>
              <label>Profil professionnel</label>
              <div className={styles.profiles}>
                {PROFILES.map(p => (
                  <button key={p.type} type="button"
                    className={`${styles.profileBtn} ${profile === p.type ? styles.profileSelected : ''}`}
                    style={{ '--c': p.color } as any}
                    onClick={() => setProfile(p.type)}>
                    <span className={styles.profileIcon}>{p.icon}</span>
                    <span className={styles.profileName}>{p.type}</span>
                    <span className={styles.profileSub}>{p.subtitle}</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {error && <div className={styles.error}>{error}</div>}
          {success && <div className={styles.successMsg}>{success}</div>}

          <button type="submit" className={styles.submit} disabled={loading}>
            {loading ? <span className={styles.spinner} /> : (mode === 'login' ? 'Se connecter →' : 'Créer mon compte →')}
          </button>
        </form>
      </div>
    </div>
  )
}
