# ⚡ ProfilIA — Setup

## 🚀 Installation en 1 commande

### Mac / Linux
```bash
bash install.sh
```

### Windows
```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

---

## 📋 Ce dont vous avez besoin AVANT de lancer

### 1. Node.js 18+
→ https://nodejs.org (télécharger la version LTS)

### 2. Compte Supabase (gratuit)
1. Créer un compte sur https://supabase.com
2. Créer un nouveau projet
3. Aller dans **SQL Editor** → coller et exécuter le fichier `src/supabase-schema.sql`
4. Aller dans **Settings > API** → noter :
   - `Project URL`
   - `anon public` key

### 3. Clé Google Gemini
1. Créer une clé sur https://aistudio.google.com/app/apikey
2. Le quota gratuit dépend des limites applicables à votre compte Google AI.

---

## 🎬 Déroulement de l'installation

L'installateur vous posera 5 questions :

```
[1/5] Nom du dossier projet  →  ex: profilia
[2/5] URL Supabase           →  https://xxxx.supabase.co
[2/5] Clé Supabase anon      →  eyJxxx...
[2/5] Clé API Gemini        →  clé créée dans Google AI Studio
[5/5] Mode déploiement       →  local / Vercel / manuel
```

Puis il génère tous les fichiers, installe les dépendances, et lance l'app.

---

## 📁 Contenu de cette archive

```
profilia-setup/
├── install.sh        ← Installateur Mac/Linux
├── install.ps1       ← Installateur Windows
├── README.md         ← Ce fichier
└── src/              ← Code source complet
    ├── app/
    │   ├── auth/         # Page connexion/inscription
    │   ├── chat/         # Interface de chat
    │   ├── settings/     # Paramètres utilisateur
    │   └── api/          # Routes API (Gemini + conversations)
    ├── components/       # ChatMessage, TypingIndicator
    ├── lib/              # Supabase, profiles, markdown, useChat
    ├── middleware.ts     # Protection des routes
    └── supabase-schema.sql  # À exécuter dans Supabase
```

---

## 📱 Installation mobile (PWA)

Une fois déployée, l'app s'installe comme une vraie app :
- **Android** : Chrome > Menu ⋮ > "Ajouter à l'écran d'accueil"
- **iPhone** : Safari > Partager ⬆ > "Sur l'écran d'accueil"

---

## 💡 Profils disponibles

| Profil | Adaptation IA |
|--------|--------------|
| 💻 Ingénieur informatique | Code, design patterns, perf |
| 🩺 Médecin | Terminologie médicale, guidelines |
| 📚 Étudiant | Pédagogique, analogies simples |
| 🚀 Entrepreneur | Business, ROI, go-to-market |
| ⚖️ Juriste | Textes de loi, procédures |
| 🎓 Enseignant | Pédagogie, supports de cours |
| 📊 Comptable | Normes comptables, fiscalité |
| 🏛️ Architecte | Normes, BIM, matériaux |

---

## 🆘 Problèmes courants

**`npm: command not found`**
→ Installer Node.js depuis https://nodejs.org

**Erreur de clé ou de quota Gemini**
→ Vérifier `GEMINI_API_KEY` dans `.env.local` et les limites du compte Google AI.

**`Error: relation "profiles" does not exist`**
→ Exécuter `supabase-schema.sql` dans Supabase Dashboard > SQL Editor

**Page blanche après connexion**
→ Vérifier l'URL Supabase et la clé anon dans `.env.local`
