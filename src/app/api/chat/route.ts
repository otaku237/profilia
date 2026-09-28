import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase-server'
import { getSystemPrompt, ProfileType } from '@/lib/profiles'
import { createGeminiClient, GEMINI_MODEL, toGeminiContents } from '@/lib/gemini'

export async function POST(req: NextRequest) {
  try {
    const supabase = createServerSupabase()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return NextResponse.json({ error: 'Non autorisé' }, { status: 401 })

    const { data: profile } = await supabase
      .from('profiles').select('name, profile_type').eq('id', user.id).single()
    if (!profile) return NextResponse.json({ error: 'Profil introuvable' }, { status: 404 })

    const { messages } = await req.json()

    const history = messages.map((m: { role: string; content: string }) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content
    }))

    const systemPrompt = getSystemPrompt(profile.name, profile.profile_type as ProfileType)

    if (!process.env.GEMINI_API_KEY) {
      return NextResponse.json({ error: 'Configurez GEMINI_API_KEY dans src/.env.local pour activer l’assistant.' }, { status: 503 })
    }

    const response = await createGeminiClient().models.generateContent({
      model: GEMINI_MODEL,
      contents: toGeminiContents(history),
      config: { systemInstruction: systemPrompt, maxOutputTokens: 2048 },
    })

    return NextResponse.json({ content: response.text || '' })
  } catch (error: any) {
    console.error('API Chat error:', error)
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
}
