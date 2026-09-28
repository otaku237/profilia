'use client'
import { useState, useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { PROFILES } from '@/lib/profiles'
import { useChat } from '@/lib/useChat'
import { ChatMessage } from '@/components/ChatMessage'
import { TypingIndicator } from '@/components/TypingIndicator'
import { renderMarkdown } from '@/lib/markdown'
import styles from './chat.module.css'

type UserProfile = { id: string; name: string; profile_type: string }

const SUGGESTIONS: Record<string, string[]> = {
  'Ingénieur informatique': ['Explique les design patterns les plus utilisés', 'Comment optimiser une requête SQL lente ?', 'Meilleures pratiques CI/CD'],
  'Médecin': ['Critères diagnostiques du diabète type 2', 'Protocole prise en charge sepsis', 'Interactions médicamenteuses courantes'],
  'Étudiant': ['Comment mieux mémoriser pour les examens ?', 'Explique la loi d\'Ohm simplement', 'Méthode pour rédiger une dissertation'],
  'Entrepreneur': ['Comment valider mon idée de startup ?', 'Structure d\'un pitch deck efficace', 'Stratégies d\'acquisition client low-cost'],
  'Juriste': ['Différences CDI vs CDD', 'Procédure de création d\'une SARL', 'Recours en cas de licenciement abusif'],
  'Enseignant': ['Techniques pour gérer une classe difficile', 'Créer une évaluation formative efficace', 'Outils numériques pour l\'enseignement'],
  'Comptable': ['Différence entre charge et immobilisation', 'Établir un tableau de trésorerie', 'Règles d\'amortissement SYSCOHADA'],
  'Architecte': ['Normes parasismiques de construction', 'Établir un cahier des charges', 'Logiciels BIM recommandés'],
}

export default function ChatPage() {
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null)
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [editingConv, setEditingConv] = useState<string | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const [input, setInput] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const textareaRef = useRef<HTMLTextAreaElement>(null)
  const supabase = createClient()
  const router = useRouter()
  const chat = useChat(userProfile?.id || null)

  useEffect(() => { loadUser() }, [])
  useEffect(() => { if (userProfile) chat.loadConversations() }, [userProfile])
  useEffect(() => { messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }) }, [chat.messages, chat.loading, chat.streamingContent])

  async function loadUser() {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { router.push('/auth'); return }
    const { data } = await supabase.from('profiles').select('id, name, profile_type').eq('id', user.id).single()
    if (data) setUserProfile(data)
  }

  async function handleSend() {
    if (!input.trim() || chat.loading) return
    const text = input.trim(); setInput('')
    if (textareaRef.current) textareaRef.current.style.height = 'auto'
    await chat.sendMessage(text)
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend() }
  }

  function handleTextareaChange(e: React.ChangeEvent<HTMLTextAreaElement>) {
    setInput(e.target.value); e.target.style.height = 'auto'
    e.target.style.height = Math.min(e.target.scrollHeight, 140) + 'px'
  }

  async function confirmRename(id: string) {
    if (editTitle.trim()) await chat.renameConversation(id, editTitle.trim())
    setEditingConv(null)
  }

  async function logout() { await supabase.auth.signOut(); router.push('/auth') }

  const profileData = PROFILES.find(p => p.type === userProfile?.profile_type)
  const suggestions = SUGGESTIONS[userProfile?.profile_type || ''] || []

  return (
    <div className={styles.app}>
      <aside className={`${styles.sidebar} ${sidebarOpen ? styles.open : ''}`}>
        <div className={styles.sidebarHeader}>
          <div className={styles.logo}>⚡ ProfilIA</div>
          <button className={styles.newChat} onClick={() => { chat.newConversation(); setSidebarOpen(false) }}>+ Nouveau chat</button>
        </div>
        <div className={styles.convList}>
          {chat.conversations.length === 0 && <div className={styles.empty}>Aucune conversation</div>}
          {chat.conversations.map(c => (
            <div key={c.id} className={`${styles.convItem} ${chat.currentConvId === c.id ? styles.convActive : ''}`}
              onClick={() => { chat.selectConversation(c.id); setSidebarOpen(false) }}>
              {editingConv === c.id
                ? <input className={styles.renameInput} value={editTitle} onChange={e => setEditTitle(e.target.value)}
                    onBlur={() => confirmRename(c.id)} onKeyDown={e => e.key === 'Enter' && confirmRename(c.id)}
                    onClick={e => e.stopPropagation()} autoFocus />
                : <><span className={styles.convTitle}>{c.title}</span>
                    <div className={styles.convActions}>
                      <button className={styles.actionBtn} onClick={e => { e.stopPropagation(); setEditingConv(c.id); setEditTitle(c.title) }}>✎</button>
                      <button className={styles.actionBtn} onClick={e => { e.stopPropagation(); chat.deleteConversation(c.id) }}>✕</button>
                    </div></>}
            </div>
          ))}
        </div>
        <div className={styles.sidebarFooter}>
          {chat.conversations.length > 0 && (
            <div className={styles.footerActions}>
              <button className={styles.iconBtn} onClick={() => { if (confirm('Effacer toutes les conversations ?')) chat.clearAll() }} title="Effacer tout">🗑</button>
              <a href="/api/export?format=markdown" download className={styles.iconBtn} title="Exporter mes conversations">⬇</a>
            </div>
          )}
          {userProfile && (
            <div className={styles.userInfo}>
              <div className={styles.userAvatar}>{profileData?.icon || '👤'}</div>
              <div style={{ flex:1, minWidth:0 }}>
                <div className={styles.userName}>{userProfile.name}</div>
                <div className={styles.userProfile}>{userProfile.profile_type}</div>
              </div>
              <button className={styles.iconBtn} onClick={() => router.push('/settings')} title="Paramètres">⚙</button>
            </div>
          )}
          <button className={styles.logoutBtn} onClick={logout}>Déconnexion</button>
        </div>
      </aside>

      {sidebarOpen && <div className={styles.overlay} onClick={() => setSidebarOpen(false)} />}

      <main className={styles.main}>
        <header className={styles.header}>
          <button className={styles.menuBtn} onClick={() => setSidebarOpen(true)} aria-label="Menu">☰</button>
          <div className={styles.headerCenter}>
            {userProfile && <span className={styles.headerProfile}>{profileData?.icon} {userProfile.profile_type}</span>}
          </div>
          <button className={styles.iconBtnHeader} onClick={() => router.push('/settings')} title="Paramètres">⚙</button>
        </header>

        <div className={styles.messages}>
          {chat.messages.length === 0 && !chat.loading && (
            <div className={styles.welcome}>
              <div className={styles.welcomeIcon}>⚡</div>
              <h1>Bonjour{userProfile ? `, ${userProfile.name}` : ''} !</h1>
              <p>IA personnalisée pour votre profil <strong>{userProfile?.profile_type}</strong></p>
              <div className={styles.suggestions}>
                {suggestions.map((s, i) => (
                  <button key={i} className={styles.suggestion} onClick={() => { setInput(s); textareaRef.current?.focus() }}>{s}</button>
                ))}
              </div>
            </div>
          )}
          {chat.messages.map(msg => <ChatMessage key={msg.id} role={msg.role} content={msg.content} />)}

          {/* Streaming en temps réel — les tokens apparaissent au fur et à mesure */}
          {chat.streamingContent && (
            <div className={styles.streamingMsg}>
              <div className={styles.streamingAvatar}>⚡</div>
              <div>
                <div className={`${styles.streamingBubble} msg-content`}
                  dangerouslySetInnerHTML={{ __html: renderMarkdown(chat.streamingContent) }} />
                <span className={styles.streamingCursor} />
              </div>
            </div>
          )}

          {chat.loading && !chat.streamingContent && <TypingIndicator />}
          <div ref={messagesEndRef} />
        </div>

        <div className={styles.inputArea}>
          <div className={styles.inputBox}>
            <textarea ref={textareaRef} value={input} onChange={handleTextareaChange} onKeyDown={handleKeyDown}
              placeholder="Posez votre question..." rows={1} className={styles.textarea} disabled={chat.loading} />
            <button className={styles.sendBtn} onClick={handleSend} disabled={chat.loading || !input.trim()} aria-label="Envoyer">↑</button>
          </div>
          <div className={styles.inputHint}>Entrée pour envoyer · Maj+Entrée pour saut de ligne</div>
        </div>
      </main>
    </div>
  )
}
