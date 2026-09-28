import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase-server'

export async function GET(req: NextRequest) {
  const supabase = createServerSupabase()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Non autorisé' }, { status: 401 })

  const { searchParams } = new URL(req.url)
  const format = searchParams.get('format') || 'json' // json | markdown | txt

  // Récupérer toutes les conversations avec leurs messages
  const { data: conversations } = await supabase
    .from('conversations')
    .select('id, title, created_at')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false })

  if (!conversations) return NextResponse.json({ error: 'Erreur BDD' }, { status: 500 })

  const fullConversations = await Promise.all(
    conversations.map(async (conv) => {
      const { data: messages } = await supabase
        .from('messages')
        .select('role, content, created_at')
        .eq('conversation_id', conv.id)
        .order('created_at')
      return { ...conv, messages: messages || [] }
    })
  )

  const { data: profile } = await supabase
    .from('profiles').select('name, profile_type').eq('id', user.id).single()

  const now = new Date().toISOString().split('T')[0]

  if (format === 'markdown') {
    let md = `# Export ProfilIA — ${profile?.name}\n`
    md += `**Profil :** ${profile?.profile_type}  \n`
    md += `**Exporté le :** ${now}  \n`
    md += `**Conversations :** ${conversations.length}\n\n---\n\n`

    for (const conv of fullConversations) {
      md += `## ${conv.title}\n`
      md += `*${new Date(conv.created_at).toLocaleDateString('fr-FR')}*\n\n`
      for (const msg of conv.messages) {
        const role = msg.role === 'user' ? `**${profile?.name || 'Vous'}**` : '**ProfilIA**'
        md += `${role}\n\n${msg.content}\n\n---\n\n`
      }
    }

    return new Response(md, {
      headers: {
        'Content-Type': 'text/markdown; charset=utf-8',
        'Content-Disposition': `attachment; filename="profilia-export-${now}.md"`,
      }
    })
  }

  if (format === 'txt') {
    let txt = `EXPORT PROFILIA - ${profile?.name} (${profile?.profile_type})\n`
    txt += `Exporté le ${now}\n`
    txt += `${'='.repeat(50)}\n\n`

    for (const conv of fullConversations) {
      txt += `${conv.title.toUpperCase()}\n${'-'.repeat(40)}\n`
      for (const msg of conv.messages) {
        const role = msg.role === 'user' ? (profile?.name || 'Vous') : 'ProfilIA'
        txt += `[${role}]\n${msg.content}\n\n`
      }
      txt += '\n'
    }

    return new Response(txt, {
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
        'Content-Disposition': `attachment; filename="profilia-export-${now}.txt"`,
      }
    })
  }

  // JSON par défaut
  return new Response(
    JSON.stringify({ exportedAt: now, profile, conversations: fullConversations }, null, 2),
    {
      headers: {
        'Content-Type': 'application/json',
        'Content-Disposition': `attachment; filename="profilia-export-${now}.json"`,
      }
    }
  )
}
