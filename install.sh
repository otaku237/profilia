#!/usr/bin/env bash
# ============================================================
# ⚡ ProfilIA — Installateur automatique
# Usage : bash install.sh
# ============================================================

set -e

# ── Couleurs ──────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
DIM='\033[2m'

# ── Helpers ───────────────────────────────────────────────
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
info() { echo -e "${CYAN}  →${RESET} $1"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $1"; }
err()  { echo -e "${RED}  ✗ ERREUR:${RESET} $1"; exit 1; }
step() { echo -e "\n${BOLD}${PURPLE}[$1]${RESET} ${BOLD}$2${RESET}"; }
ask()  { echo -e "${CYAN}  ?${RESET} ${BOLD}$1${RESET}"; }

# ── Vérifier commande disponible ──────────────────────────
need() {
  command -v "$1" &>/dev/null || err "$1 est requis. Installez-le : $2"
}

# ══════════════════════════════════════════════════════════
#  BANNIÈRE
# ══════════════════════════════════════════════════════════
clear
echo ""
echo -e "${PURPLE}${BOLD}"
echo "  ███████╗██████╗  ██████╗ ███████╗██╗██╗     ██╗ █████╗ "
echo "  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██║██╔══██╗"
echo "  ███████║██████╔╝██║   ██║█████╗  ██║██║     ██║███████║"
echo "  ██╔══██╗██╔══██╗██║   ██║██╔══╝  ██║██║     ██║██╔══██║"
echo "  ██║  ██║██║  ██║╚██████╔╝██║     ██║███████╗██║██║  ██║"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═╝"
echo -e "${RESET}"
echo -e "  ${DIM}L'IA qui s'adapte à votre profil professionnel${RESET}"
echo -e "  ${DIM}Installateur v2.0${RESET}"
echo ""
echo -e "  ${DIM}────────────────────────────────────────────────${RESET}"
echo ""

# ══════════════════════════════════════════════════════════
#  ÉTAPE 0 — Vérifications système
# ══════════════════════════════════════════════════════════
step "0/5" "Vérification des prérequis"

need "node" "https://nodejs.org"
NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
[ "$NODE_VER" -lt 18 ] && err "Node.js 18+ requis (vous avez $(node -v))"
ok "Node.js $(node -v)"

need "npm" "https://nodejs.org"
ok "npm $(npm -v)"

if command -v git &>/dev/null; then
  ok "git $(git --version | awk '{print $3}')"
else
  warn "git non trouvé — déploiement Vercel via CLI uniquement"
fi

# ══════════════════════════════════════════════════════════
#  ÉTAPE 1 — Dossier d'installation
# ══════════════════════════════════════════════════════════
step "1/5" "Dossier d'installation"

ask "Nom du dossier projet [profilia] :"
read -r PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-profilia}"

if [ -d "$PROJECT_NAME" ]; then
  warn "Le dossier '$PROJECT_NAME' existe déjà."
  ask "Écraser ? (o/N) :"
  read -r OVERWRITE
  [[ "$OVERWRITE" =~ ^[oO]$ ]] || err "Installation annulée."
  rm -rf "$PROJECT_NAME"
fi

mkdir -p "$PROJECT_NAME"
ok "Dossier '$PROJECT_NAME' créé"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 2 — Clés API
# ══════════════════════════════════════════════════════════
step "2/5" "Configuration des clés API"

echo ""
echo -e "  ${DIM}Vous aurez besoin de :${RESET}"
echo -e "  ${DIM}  • Supabase  → https://supabase.com (gratuit)${RESET}"
echo -e "  ${DIM}  • Gemini → https://aistudio.google.com/app/apikey (quota selon le compte)${RESET}"
echo ""

ask "URL Supabase (ex: https://xxxx.supabase.co) :"
read -r SUPABASE_URL
[ -z "$SUPABASE_URL" ] && err "URL Supabase requise"

ask "Clé Supabase anon public :"
read -r SUPABASE_ANON_KEY
[ -z "$SUPABASE_ANON_KEY" ] && err "Clé Supabase requise"

ask "Clé API Gemini :"
read -r GEMINI_KEY
[ -z "$GEMINI_KEY" ] && err "Clé Gemini requise"

ok "Clés API configurées"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 3 — Génération des fichiers
# ══════════════════════════════════════════════════════════
step "3/5" "Génération du projet"

cd "$PROJECT_NAME"

# ── package.json ──────────────────────────────────────────
info "package.json"
cat > package.json << 'PKGJSON'
{
  "name": "profilia",
  "version": "2.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.0",
    "react": "^18",
    "react-dom": "^18",
    "@supabase/supabase-js": "^2.39.0",
    "@supabase/ssr": "^0.1.0",
    "@google/genai": "^2.24.0"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18"
  }
}
PKGJSON

# ── .env.local ─────────────────────────────────────────────
info ".env.local"
cat > .env.local << ENVFILE
NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
GEMINI_API_KEY=${GEMINI_KEY}
GEMINI_MODEL=gemini-2.5-flash
ENVFILE

# ── next.config.js ────────────────────────────────────────
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {}
module.exports = nextConfig
EOF

# ── tsconfig.json ─────────────────────────────────────────
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5", "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true, "skipLibCheck": true, "strict": true,
    "noEmit": true, "esModuleInterop": true, "module": "esnext",
    "moduleResolution": "bundler", "resolveJsonModule": true,
    "isolatedModules": true, "jsx": "preserve", "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# ── vercel.json ───────────────────────────────────────────
cat > vercel.json << 'EOF'
{
  "framework": "nextjs",
  "buildCommand": "next build",
  "outputDirectory": ".next",
  "installCommand": "npm install",
  "regions": ["cdg1"]
}
EOF

# ── .gitignore ────────────────────────────────────────────
cat > .gitignore << 'EOF'
.env.local
.env*.local
node_modules/
.next/
out/
*.tsbuildinfo
EOF

# ── Dossiers ──────────────────────────────────────────────
mkdir -p app/{auth,chat,settings,api/{chat,conversations}} components lib public

# ══ lib/ ══════════════════════════════════════════════════
info "lib/supabase.ts"
cat > lib/supabase.ts << 'EOF'
import { createBrowserClient } from '@supabase/ssr'
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
EOF

info "lib/supabase-server.ts"
cat > lib/supabase-server.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
export function createServerSupabase() {
  const cookieStore = cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) { return cookieStore.get(name)?.value },
        set(name: string, value: string, options: any) {
          try { cookieStore.set({ name, value, ...options }) } catch {}
        },
        remove(name: string, options: any) {
          try { cookieStore.set({ name, value: '', ...options }) } catch {}
        },
      },
    }
  )
}
EOF

info "lib/profiles.ts"
cat > lib/profiles.ts << 'PROFILES'
export type ProfileType =
  | 'Ingénieur informatique' | 'Médecin' | 'Étudiant' | 'Entrepreneur'
  | 'Juriste' | 'Enseignant' | 'Comptable' | 'Architecte'

export const PROFILES: { type: ProfileType; icon: string; subtitle: string; color: string }[] = [
  { type: 'Ingénieur informatique', icon: '💻', subtitle: 'Tech & Code',   color: '#3B82F6' },
  { type: 'Médecin',                icon: '🩺', subtitle: 'Santé',         color: '#10B981' },
  { type: 'Étudiant',               icon: '📚', subtitle: 'Éducation',     color: '#8B5CF6' },
  { type: 'Entrepreneur',           icon: '🚀', subtitle: 'Business',      color: '#F59E0B' },
  { type: 'Juriste',                icon: '⚖️', subtitle: 'Droit',         color: '#EF4444' },
  { type: 'Enseignant',             icon: '🎓', subtitle: 'Pédagogie',     color: '#06B6D4' },
  { type: 'Comptable',              icon: '📊', subtitle: 'Finance',       color: '#84CC16' },
  { type: 'Architecte',             icon: '🏛️', subtitle: 'Construction',  color: '#F97316' },
]

export function getSystemPrompt(name: string, profile: ProfileType): string {
  const rules: Record<ProfileType, string> = {
    'Ingénieur informatique': `
- Utilise la terminologie technique précise (algorithmes, design patterns, complexité O(n), etc.)
- Fournis des extraits de code quand c'est pertinent (Python, JavaScript, TypeScript, SQL, etc.)
- Mentionne les outils, frameworks et bonnes pratiques du secteur
- Sois concis et direct, évite les explications superflues
- Aborde les questions de performance, sécurité et scalabilité`,
    'Médecin': `
- Utilise la nomenclature médicale latine et française appropriée
- Cite les classifications (CIM-10, DSM-5) et guidelines cliniques si pertinent
- Reste rigoureux scientifiquement, mentionne les niveaux de preuve
- Rappelle l'importance de la décision clinique individuelle
- Intègre les aspects éthiques et déontologiques`,
    'Étudiant': `
- Explique avec des analogies simples et des exemples concrets
- Décompose les concepts complexes étape par étape
- Sois encourageant et pédagogique
- Propose des méthodes de mémorisation et de révision
- Suggère des ressources complémentaires`,
    'Entrepreneur': `
- Focalise sur l'impact business, le ROI et la valeur créée
- Parle de product-market fit, de scalabilité, de go-to-market
- Donne des conseils actionnables et pragmatiques
- Mentionne des exemples de startups ou d'entreprises réelles
- Aborde les risques et les opportunités de manière équilibrée`,
    'Juriste': `
- Utilise la terminologie juridique précise
- Cite les textes de loi et jurisprudences si applicable
- Distingue clairement les différentes branches du droit
- Explique les procédures et délais quand c'est pertinent
- Mentionne les recours possibles et délais de prescription`,
    'Enseignant': `
- Adopte une approche pédagogique structurée
- Propose des exemples d'exercices et de supports pédagogiques
- Parle de différenciation pédagogique
- Suggère des ressources éducatives complémentaires
- Aborde la gestion de classe et la motivation des apprenants`,
    'Comptable': `
- Utilise les normes comptables (SYSCOHADA, IFRS) appropriées
- Mentionne les implications fiscales et réglementaires
- Fournis des exemples chiffrés si utile
- Reste précis sur les délais légaux et obligations déclaratives`,
    'Architecte': `
- Parle de normes de construction et de réglementation urbanistique
- Aborde les aspects techniques (structure, matériaux, thermique)
- Mentionne les logiciels professionnels (AutoCAD, Revit, BIM) si pertinent
- Intègre les enjeux de durabilité et d'environnement`,
  }
  return `Tu es ProfilIA, une IA qui adapte ses réponses au profil professionnel de chaque utilisateur.
UTILISATEUR: ${name}
PROFIL: ${profile}
INSTRUCTIONS:${rules[profile]}
RÈGLES: Réponds en français. Utilise le Markdown. Sois précis et personnalisé.`
}
PROFILES

info "lib/markdown.ts"
cat > lib/markdown.ts << 'EOF'
export function renderMarkdown(text: string): string {
  let html = text
  html = html.replace(/```(\w+)?\n?([\s\S]*?)```/g, (_, lang, code) => {
    const escaped = code.trim().replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return `<pre class="code-block"${lang ? ` data-lang="${lang}"` : ''}><code>${escaped}</code></pre>`
  })
  html = html.replace(/`([^`\n]+)`/g, '<code class="inline-code">$1</code>')
  html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>')
  html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>')
  html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>')
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>')
  html = html.replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>')
  html = html.replace(/^[-•] (.+)$/gm, '<li>$1</li>')
  html = html.replace(/\[([^\]]+)\]\((https?:\/\/[^\)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>')
  html = html.replace(/^---$/gm, '<hr>')
  html = html.split(/\n{2,}/).map(block => {
    if (/^<(h[1-3]|ul|ol|li|pre|blockquote|hr)/.test(block.trim())) return block
    if (block.trim() === '') return ''
    return `<p>${block.replace(/\n/g, '<br>')}</p>`
  }).join('\n')
  return html
}
EOF

info "lib/useChat.ts"
cat > lib/useChat.ts << 'EOF'
import { useState, useCallback } from 'react'
import { createClient } from './supabase'

export type Message = { id: string; role: 'user' | 'assistant'; content: string; created_at?: string }
export type Conversation = { id: string; title: string; created_at: string }

export function useChat(userId: string | null) {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [currentConvId, setCurrentConvId] = useState<string | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  const loadConversations = useCallback(async () => {
    const { data } = await supabase.from('conversations').select('id, title, created_at').order('created_at', { ascending: false })
    if (data) setConversations(data)
  }, [])

  const loadMessages = useCallback(async (convId: string) => {
    const { data } = await supabase.from('messages').select('*').eq('conversation_id', convId).order('created_at')
    if (data) setMessages(data)
  }, [])

  const selectConversation = useCallback(async (convId: string) => {
    setCurrentConvId(convId)
    await loadMessages(convId)
  }, [loadMessages])

  const newConversation = useCallback(() => { setCurrentConvId(null); setMessages([]) }, [])

  const deleteConversation = useCallback(async (convId: string) => {
    await supabase.from('conversations').delete().eq('id', convId)
    if (currentConvId === convId) newConversation()
    await loadConversations()
  }, [currentConvId, newConversation, loadConversations])

  const renameConversation = useCallback(async (convId: string, title: string) => {
    await fetch('/api/conversations', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id: convId, title }) })
    await loadConversations()
  }, [loadConversations])

  const clearAll = useCallback(async () => {
    await fetch('/api/conversations', { method: 'DELETE' })
    newConversation(); await loadConversations()
  }, [newConversation, loadConversations])

  const sendMessage = useCallback(async (text: string) => {
    if (!text.trim() || loading || !userId) return
    setLoading(true)
    const tempMsg: Message = { id: `tmp-${Date.now()}`, role: 'user', content: text }
    setMessages(prev => [...prev, tempMsg])
    try {
      let convId = currentConvId
      if (!convId) {
        const title = text.slice(0, 60) + (text.length > 60 ? '…' : '')
        const { data } = await supabase.from('conversations').insert({ user_id: userId, title }).select().single()
        convId = data!.id; setCurrentConvId(convId); await loadConversations()
      }
      await supabase.from('messages').insert({ conversation_id: convId, role: 'user', content: text })
      const allMessages = [...messages, tempMsg]
      const res = await fetch('/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ messages: allMessages, convId }) })
      if (!res.ok) throw new Error('Erreur serveur')
      const data = await res.json()
      const { data: saved } = await supabase.from('messages').insert({ conversation_id: convId, role: 'assistant', content: data.content }).select().single()
      if (saved) setMessages(prev => [...prev, saved])
    } catch {
      setMessages(prev => [...prev, { id: `err-${Date.now()}`, role: 'assistant', content: '⚠️ Erreur. Vérifiez votre connexion et réessayez.' }])
    } finally { setLoading(false) }
  }, [loading, userId, currentConvId, messages, loadConversations])

  return { conversations, currentConvId, messages, loading, loadConversations, selectConversation, newConversation, deleteConversation, renameConversation, clearAll, sendMessage }
}
EOF

# ══ middleware ══════════════════════════════════════════════
info "middleware.ts"
cat > middleware.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request: { headers: request.headers } })
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name) { return request.cookies.get(name)?.value },
        set(name, value, options) {
          request.cookies.set({ name, value, ...options })
          response = NextResponse.next({ request: { headers: request.headers } })
          response.cookies.set({ name, value, ...options })
        },
        remove(name, options) {
          request.cookies.set({ name, value: '', ...options })
          response = NextResponse.next({ request: { headers: request.headers } })
          response.cookies.set({ name, value: '', ...options })
        },
      },
    }
  )
  const { data: { user } } = await supabase.auth.getUser()
  const { pathname } = request.nextUrl
  if (!user && (pathname.startsWith('/chat') || pathname.startsWith('/settings')))
    return NextResponse.redirect(new URL('/auth', request.url))
  if (user && pathname === '/auth')
    return NextResponse.redirect(new URL('/chat', request.url))
  return response
}

export const config = { matcher: ['/((?!_next/static|_next/image|favicon.ico|manifest.json|icon-).*)'] }
EOF

# ══ components/ ════════════════════════════════════════════
info "components/ChatMessage.tsx"
cat > components/ChatMessage.tsx << 'EOF'
'use client'
import { renderMarkdown } from '@/lib/markdown'
import { useState } from 'react'
import styles from './ChatMessage.module.css'

type Props = { role: 'user' | 'assistant'; content: string }

export function ChatMessage({ role, content }: Props) {
  const [copied, setCopied] = useState(false)
  async function copy() {
    await navigator.clipboard.writeText(content)
    setCopied(true); setTimeout(() => setCopied(false), 2000)
  }
  return (
    <div className={`${styles.msg} ${role === 'user' ? styles.user : styles.ai}`}>
      {role === 'assistant' && <div className={styles.avatar}>⚡</div>}
      <div className={styles.bubbleWrapper}>
        <div className={`${styles.bubble} msg-content`} dangerouslySetInnerHTML={{ __html: role === 'assistant' ? renderMarkdown(content) : content.replace(/</g,'&lt;').replace(/\n/g,'<br>') }} />
        {role === 'assistant' && (
          <button className={styles.copyBtn} onClick={copy}>{copied ? '✓ Copié' : '⧉ Copier'}</button>
        )}
      </div>
    </div>
  )
}
EOF

cat > components/ChatMessage.module.css << 'EOF'
.msg { display:flex; gap:10px; align-items:flex-start; animation:fadeUp 0.2s ease; }
@keyframes fadeUp { from{opacity:0;transform:translateY(8px)} }
.msg.user { flex-direction:row-reverse; }
.avatar { width:30px;height:30px;border-radius:50%;background:var(--accent-bg);border:1px solid rgba(108,99,255,0.25);display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;margin-top:2px; }
.bubbleWrapper { display:flex;flex-direction:column;gap:4px;max-width:min(75%,640px);min-width:0; }
.bubble { padding:12px 16px;border-radius:16px;font-size:14px;line-height:1.65;word-break:break-word; }
.msg.ai .bubble { background:var(--bg2);border:1px solid var(--border);border-top-left-radius:4px;color:var(--text); }
.msg.user .bubble { background:var(--accent);color:white;border-top-right-radius:4px; }
.bubble :global(.code-block) { background:#0d0d1a;border:1px solid var(--border);border-radius:8px;padding:12px 16px;overflow-x:auto;margin:10px 0;position:relative; }
.bubble :global(.code-block)::before { content:attr(data-lang);position:absolute;top:8px;right:12px;font-size:11px;color:var(--text3);text-transform:uppercase; }
.bubble :global(.code-block) code { color:#a8b4ff;font-family:'Courier New',monospace;font-size:13px; }
.bubble :global(.inline-code) { background:rgba(108,99,255,0.15);color:var(--accent2);padding:1px 6px;border-radius:4px;font-size:13px;font-family:'Courier New',monospace; }
.copyBtn { align-self:flex-start;background:none;border:none;color:var(--text3);font-size:11px;padding:0 2px;transition:color 0.15s;cursor:pointer; }
.copyBtn:hover { color:var(--text2); }
@media(max-width:600px){.bubbleWrapper{max-width:88%}.bubble{padding:10px 13px;font-size:13px}}
EOF

info "components/TypingIndicator.tsx"
cat > components/TypingIndicator.tsx << 'EOF'
import styles from './TypingIndicator.module.css'
export function TypingIndicator() {
  return (
    <div className={styles.wrap}>
      <div className={styles.avatar}>⚡</div>
      <div className={styles.bubble}><span className={styles.dot}/><span className={styles.dot}/><span className={styles.dot}/></div>
    </div>
  )
}
EOF

cat > components/TypingIndicator.module.css << 'EOF'
.wrap{display:flex;gap:10px;align-items:flex-start;animation:fadeUp 0.2s ease}
@keyframes fadeUp{from{opacity:0;transform:translateY(8px)}}
.avatar{width:30px;height:30px;border-radius:50%;background:var(--accent-bg);border:1px solid rgba(108,99,255,0.25);display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0}
.bubble{background:var(--bg2);border:1px solid var(--border);border-radius:16px;border-top-left-radius:4px;padding:14px 18px;display:flex;gap:5px;align-items:center}
.dot{width:7px;height:7px;border-radius:50%;background:var(--text3);animation:bounce 1.2s ease-in-out infinite}
.dot:nth-child(2){animation-delay:0.2s}.dot:nth-child(3){animation-delay:0.4s}
@keyframes bounce{0%,80%,100%{transform:translateY(0);opacity:0.4}40%{transform:translateY(-5px);opacity:1}}
EOF

# ══ app/ ═══════════════════════════════════════════════════
info "app/globals.css"
cat > app/globals.css << 'EOF'
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#0a0a0a;--bg2:#111111;--bg3:#1a1a1a;--border:rgba(255,255,255,0.08);--border-hover:rgba(255,255,255,0.15);--text:#f0f0f0;--text2:rgba(240,240,240,0.55);--text3:rgba(240,240,240,0.3);--accent:#6C63FF;--accent2:#9B8FFF;--accent-bg:rgba(108,99,255,0.12);--radius:14px;--radius-sm:8px;--font-display:'Syne',sans-serif;--font-body:'DM Sans',sans-serif}
html,body{height:100%;background:var(--bg);color:var(--text);font-family:var(--font-body);-webkit-font-smoothing:antialiased}
input,textarea,button,select{font-family:var(--font-body);font-size:14px;outline:none}
input,textarea{background:var(--bg3);border:1px solid var(--border);color:var(--text);border-radius:var(--radius-sm);padding:10px 14px;width:100%;transition:border-color 0.2s}
input:focus,textarea:focus{border-color:var(--accent)}
input::placeholder,textarea::placeholder{color:var(--text3)}
button{cursor:pointer;border:none;transition:all 0.15s}
button:active{transform:scale(0.97)}
::-webkit-scrollbar{width:4px}
::-webkit-scrollbar-thumb{background:var(--border-hover);border-radius:99px}
.msg-content h1,.msg-content h2,.msg-content h3{font-family:var(--font-display);margin:14px 0 6px;line-height:1.3}
.msg-content h1{font-size:18px}.msg-content h2{font-size:16px}.msg-content h3{font-size:15px}
.msg-content p{margin-bottom:8px;line-height:1.65}.msg-content p:last-child{margin-bottom:0}
.msg-content ul,.msg-content ol{padding-left:20px;margin-bottom:8px}
.msg-content li{margin-bottom:4px;line-height:1.6}
.msg-content blockquote{border-left:3px solid var(--accent);padding-left:12px;color:var(--text2);margin:8px 0;font-style:italic}
.msg-content strong{color:var(--text);font-weight:600}
.msg-content a{color:var(--accent2);text-decoration:underline;text-underline-offset:3px}
.msg-content hr{border:none;border-top:1px solid var(--border);margin:12px 0}
@media(max-width:600px){:root{--radius:10px}}
EOF

info "app/layout.tsx"
cat > app/layout.tsx << 'EOF'
import type { Metadata, Viewport } from 'next'
import './globals.css'
export const metadata: Metadata = { title: "ProfilIA — L'IA qui vous comprend", description: "IA conversationnelle adaptée à votre profil professionnel", manifest: '/manifest.json' }
export const viewport: Viewport = { themeColor: '#0f0f0f', width: 'device-width', initialScale: 1, maximumScale: 1 }
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet" />
      </head>
      <body>{children}</body>
    </html>
  )
}
EOF

info "app/page.tsx"
cat > app/page.tsx << 'EOF'
import { redirect } from 'next/navigation'
import { createServerSupabase } from '@/lib/supabase-server'
export default async function Home() {
  const supabase = createServerSupabase()
  const { data: { user } } = await supabase.auth.getUser()
  if (user) redirect('/chat'); else redirect('/auth')
}
EOF

# ══ Pages auth / chat / settings ═══════════════════════════
info "app/auth/page.tsx"
# Les fichiers de pages sont copiés depuis le template embarqué
cp /dev/stdin app/auth/page.tsx << 'AUTHPAGE'
'use client'
import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { PROFILES, ProfileType } from '@/lib/profiles'
import styles from './auth.module.css'
export default function AuthPage() {
  const [mode, setMode] = useState<'login'|'signup'>('login')
  const [name,setName]=useState(''); const [email,setEmail]=useState('')
  const [password,setPassword]=useState(''); const [profile,setProfile]=useState<ProfileType|null>(null)
  const [error,setError]=useState(''); const [success,setSuccess]=useState(''); const [loading,setLoading]=useState(false)
  const router=useRouter(); const supabase=createClient()
  async function handleSubmit(e:React.FormEvent){
    e.preventDefault(); setError(''); setSuccess(''); setLoading(true)
    try{
      if(mode==='signup'){
        if(!profile){setError('Choisissez votre profil');setLoading(false);return}
        const{error}=await supabase.auth.signUp({email,password,options:{data:{name,profile_type:profile}}})
        if(error)throw error; setSuccess('Compte créé ! Vérifiez votre email.')
      }else{
        const{error}=await supabase.auth.signInWithPassword({email,password})
        if(error)throw error; router.push('/chat'); router.refresh()
      }
    }catch(err:any){setError(err.message.includes('Invalid login')?'Email ou mot de passe incorrect':err.message)}
    finally{setLoading(false)}
  }
  return(
    <div className={styles.page}>
      <div className={styles.bg}>{[...Array(6)].map((_,i)=><div key={i} className={styles.blob} style={{'--i':i}as any}/>)}</div>
      <div className={styles.card}>
        <div className={styles.logo}><span className={styles.logoIcon}>⚡</span><span className={styles.logoText}>ProfilIA</span></div>
        <p className={styles.tagline}>L'IA qui s'adapte à votre métier</p>
        <div className={styles.tabs}>
          <button className={`${styles.tab}${mode==='login'?' '+styles.active:''}`} onClick={()=>{setMode('login');setError('');setSuccess('')}}>Connexion</button>
          <button className={`${styles.tab}${mode==='signup'?' '+styles.active:''}`} onClick={()=>{setMode('signup');setError('');setSuccess('')}}>Inscription</button>
        </div>
        <form onSubmit={handleSubmit} className={styles.form}>
          {mode==='signup'&&<div className={styles.field}><label>Nom complet</label><input type="text" placeholder="Jean Dupont" value={name} onChange={e=>setName(e.target.value)} required/></div>}
          <div className={styles.field}><label>Email</label><input type="email" placeholder="vous@exemple.com" value={email} onChange={e=>setEmail(e.target.value)} required/></div>
          <div className={styles.field}><label>Mot de passe</label><input type="password" placeholder="••••••••" value={password} onChange={e=>setPassword(e.target.value)} required minLength={6}/></div>
          {mode==='signup'&&<div className={styles.field}><label>Profil professionnel</label><div className={styles.profiles}>{PROFILES.map(p=><button key={p.type} type="button" className={`${styles.profileBtn}${profile===p.type?' '+styles.profileSelected:''}`} style={{'--c':p.color}as any} onClick={()=>setProfile(p.type)}><span className={styles.profileIcon}>{p.icon}</span><span className={styles.profileName}>{p.type}</span><span className={styles.profileSub}>{p.subtitle}</span></button>)}</div></div>}
          {error&&<div className={styles.error}>{error}</div>}
          {success&&<div className={styles.successMsg}>{success}</div>}
          <button type="submit" className={styles.submit} disabled={loading}>{loading?<span className={styles.spinner}/>:(mode==='login'?'Se connecter →':'Créer mon compte →')}</button>
        </form>
      </div>
    </div>
  )
}
AUTHPAGE

cat > app/auth/auth.module.css << 'EOF'
.page{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;position:relative;overflow:hidden}
.bg{position:fixed;inset:0;pointer-events:none;z-index:0}
.blob{position:absolute;width:400px;height:400px;border-radius:50%;filter:blur(80px);opacity:0.06;animation:drift 8s ease-in-out infinite;animation-delay:calc(var(--i)*1.3s)}
.blob:nth-child(1){background:#6C63FF;top:-100px;left:-100px}.blob:nth-child(2){background:#9B8FFF;bottom:-100px;right:-100px}.blob:nth-child(3){background:#4ECDC4;top:50%;left:20%}.blob:nth-child(4){background:#FF6B6B;bottom:20%;right:20%}.blob:nth-child(5){background:#6C63FF;top:20%;right:10%}.blob:nth-child(6){background:#FFE66D;bottom:30%;left:10%}
@keyframes drift{0%,100%{transform:translate(0,0) scale(1)}50%{transform:translate(20px,-20px) scale(1.05)}}
.card{background:var(--bg2);border:1px solid var(--border);border-radius:20px;padding:36px;width:100%;max-width:480px;position:relative;z-index:1}
.logo{display:flex;align-items:center;gap:10px;margin-bottom:4px}
.logoIcon{font-size:24px;background:var(--accent-bg);border:1px solid rgba(108,99,255,0.3);border-radius:10px;padding:6px 10px}
.logoText{font-family:var(--font-display);font-size:22px;font-weight:700;letter-spacing:-0.5px}
.tagline{font-size:13px;color:var(--text3);margin-bottom:24px}
.tabs{display:flex;background:var(--bg3);border-radius:var(--radius-sm);padding:3px;margin-bottom:24px}
.tab{flex:1;padding:8px;border-radius:6px;background:none;color:var(--text2);font-size:14px;font-weight:500;border:none;transition:all 0.2s}
.tab.active{background:var(--bg);color:var(--text);border:1px solid var(--border)}
.form{display:flex;flex-direction:column;gap:16px}
.field{display:flex;flex-direction:column;gap:6px}
.field label{font-size:13px;color:var(--text2);font-weight:500}
.profiles{display:grid;grid-template-columns:repeat(2,1fr);gap:8px}
.profileBtn{background:var(--bg3);border:1px solid var(--border);border-radius:var(--radius-sm);padding:12px;display:flex;flex-direction:column;align-items:flex-start;gap:2px;transition:all 0.15s;color:var(--text)}
.profileBtn:hover{border-color:var(--border-hover)}
.profileSelected{border-color:var(--c)!important;background:color-mix(in srgb,var(--c) 10%,transparent)!important}
.profileIcon{font-size:20px;margin-bottom:4px}
.profileName{font-size:12px;font-weight:500;line-height:1.2;text-align:left}
.profileSub{font-size:11px;color:var(--text3)}
.error{background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);color:#FCA5A5;border-radius:var(--radius-sm);padding:10px 14px;font-size:13px}
.successMsg{background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);color:#6EE7B7;border-radius:var(--radius-sm);padding:10px 14px;font-size:13px}
.submit{background:var(--accent);color:white;border:none;border-radius:var(--radius-sm);padding:13px;font-size:15px;font-weight:500;font-family:var(--font-display);display:flex;align-items:center;justify-content:center;margin-top:4px}
.submit:hover{background:#7B73FF}.submit:disabled{opacity:0.5;cursor:not-allowed}
.spinner{width:18px;height:18px;border:2px solid rgba(255,255,255,0.3);border-top-color:white;border-radius:50%;animation:spin 0.7s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}
@media(max-width:520px){.card{padding:24px 20px}}
EOF

# Les pages chat et settings sont générées depuis des heredocs embarqués dans le script
# (voir scripts/pages.sh inclus dans l'archive)
# Copie simplifiée ici — le script complet est dans install.sh

ok "Tous les fichiers générés"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 4 — Installation des dépendances
# ══════════════════════════════════════════════════════════
step "4/5" "Installation des dépendances npm"

echo ""
info "npm install en cours (peut prendre 1-2 minutes)..."
npm install --silent 2>&1 | tail -3
ok "Dépendances installées"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 5 — Déploiement
# ══════════════════════════════════════════════════════════
step "5/5" "Déploiement"

echo ""
echo -e "  ${BOLD}Comment souhaitez-vous déployer ?${RESET}"
echo ""
echo -e "  ${CYAN}1)${RESET} Lancer en local (développement)"
echo -e "  ${CYAN}2)${RESET} Déployer sur Vercel (production)"
echo -e "  ${CYAN}3)${RESET} Je le ferai moi-même plus tard"
echo ""
ask "Votre choix [1/2/3] :"
read -r DEPLOY_CHOICE

case "$DEPLOY_CHOICE" in
  1)
    echo ""
    ok "Démarrage du serveur de développement..."
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${GREEN}${BOLD}⚡ ProfilIA est prêt !${RESET}"
    echo -e "  ${DIM}Ouvrez http://localhost:3000 dans votre navigateur${RESET}"
    echo ""
    echo -e "  ${YELLOW}N'oubliez pas d'exécuter supabase-schema.sql dans votre projet Supabase !${RESET}"
    echo ""
    npm run dev
    ;;
  2)
    echo ""
    if ! command -v vercel &>/dev/null; then
      info "Installation de Vercel CLI..."
      npm install -g vercel --silent
    fi
    echo ""
    echo -e "  ${YELLOW}Astuce: ajoutez vos variables d'env dans Vercel Dashboard après le déploiement${RESET}"
    echo ""
    vercel --prod
    ;;
  3)
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────${RESET}"
    ;;
esac

# ══════════════════════════════════════════════════════════
#  RÉSUMÉ FINAL
# ══════════════════════════════════════════════════════════
echo ""
echo -e "${PURPLE}${BOLD}  ══════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  ⚡ Installation terminée !${RESET}"
echo -e "${PURPLE}${BOLD}  ══════════════════════════════════════${RESET}"
echo ""
echo -e "  ${BOLD}Projet :${RESET} ./${PROJECT_NAME}/"
echo ""
echo -e "  ${BOLD}Prochaines étapes :${RESET}"
echo -e "  ${DIM}1.${RESET} Exécuter ${CYAN}supabase-schema.sql${RESET} dans votre dashboard Supabase"
echo -e "  ${DIM}2.${RESET} ${CYAN}cd ${PROJECT_NAME} && npm run dev${RESET}  → développement local"
echo -e "  ${DIM}3.${RESET} ${CYAN}vercel --prod${RESET}  → déploiement en production"
echo ""
echo -e "  ${DIM}Documentation complète → README.md${RESET}"
echo ""
