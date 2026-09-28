# ⚡ ProfilIA v2 — IA adaptée à votre profil

## 🚀 Déploiement (15 minutes)

### 1. Supabase (BDD gratuite)
1. Compte sur [supabase.com](https://supabase.com) → nouveau projet
2. **SQL Editor** → coller et exécuter `supabase-schema.sql`
3. **Settings > API** → copier `Project URL` et `anon key`

### 2. Clé Google Gemini
- [Google AI Studio](https://aistudio.google.com/app/apikey) → créer une clé API
- Le quota gratuit dépend des limites applicables à votre compte Google AI.

### 3. Vercel (hébergement gratuit)
```bash
npm install -g vercel
vercel --prod
```
Ou : importer le repo GitHub sur [vercel.com](https://vercel.com)

### 4. Variables d'environnement sur Vercel
```
NEXT_PUBLIC_SUPABASE_URL      = https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY = eyJxxx...
GEMINI_API_KEY                = votre-cle-gemini
GEMINI_MODEL                  = gemini-2.5-flash
```
Redéployer → votre app est live ! ✅

---

## 💻 Dev local
```bash
cp .env.local.example .env.local  # remplir les valeurs
npm install
npm run dev
# → http://localhost:3000
```

---

## 📁 Structure v2

```
profilia/
├── app/
│   ├── auth/                   # Connexion / Inscription
│   ├── chat/                   # Interface de chat principale
│   ├── settings/               # ⭐ NOUVEAU: Paramètres utilisateur
│   ├── api/
│   │   ├── chat/               # API → Google Gemini
│   │   └── conversations/      # ⭐ NOUVEAU: Rename / Delete
│   ├── layout.tsx
│   ├── page.tsx
│   └── globals.css
├── components/
│   ├── ChatMessage.tsx          # ⭐ NOUVEAU: Composant message + bouton copier
│   └── TypingIndicator.tsx      # ⭐ NOUVEAU: Animation de frappe
├── lib/
│   ├── supabase.ts
│   ├── supabase-server.ts
│   ├── profiles.ts             # 8 profils + system prompts
│   ├── useChat.ts              # ⭐ NOUVEAU: Hook centralisé
│   └── markdown.ts             # ⭐ NOUVEAU: Renderer Markdown
├── middleware.ts               # ⭐ NOUVEAU: Protection des routes
└── supabase-schema.sql         # Schéma BDD avec indexes
```

---

## ✨ Fonctionnalités v2

| Feature | Description |
|---------|-------------|
| 🔐 Auth complète | Inscription, connexion, déconnexion |
| 👤 8 profils | Ingénieur, Médecin, Étudiant, Entrepreneur, Juriste, Enseignant, Comptable, Architecte |
| 💬 Chat adaptatif | Réponses Markdown avec coloration syntaxique code |
| ⧉ Copier réponse | Bouton copie sur chaque réponse IA |
| ✎ Renommer conv. | Double clic sur une conversation |
| 🗑 Effacer tout | Supprimer toutes les conversations |
| ⚙ Paramètres | Modifier nom, profil, mot de passe |
| ⚠️ Suppr. compte | Suppression complète des données |
| 🛡 Middleware | Redirections automatiques auth/non-auth |
| 📱 PWA | Installable comme app mobile |
| 🔒 Sécurité | RLS Supabase, clé API côté serveur |

---

## 📱 Installation mobile (PWA)
- **Android** : Chrome > Menu ⋮ > "Ajouter à l'écran d'accueil"
- **iPhone** : Safari > Partager ⬆ > "Sur l'écran d'accueil"
