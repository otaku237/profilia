import { NextRequest } from 'next/server'
import { createServerSupabase } from '@/lib/supabase-server'
import { getSystemPrompt, ProfileType } from '@/lib/profiles'
import { createGeminiClient, GEMINI_MODEL, toGeminiContents } from '@/lib/gemini'

export async function POST(req: NextRequest) {
  const supabase = createServerSupabase()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return new Response('Non autorisé', { status: 401 })

  const { data: profile } = await supabase
    .from('profiles').select('name, profile_type').eq('id', user.id).single()
  if (!profile) return new Response('Profil introuvable', { status: 404 })

  const { messages } = await req.json()
  const systemPrompt = getSystemPrompt(profile.name, profile.profile_type as ProfileType)
  if (!process.env.GEMINI_API_KEY) {
    return new Response('Configurez GEMINI_API_KEY dans src/.env.local pour activer l’assistant.', { status: 503 })
  }

  // Retourner un stream SSE
  const encoder = new TextEncoder()
  const stream = new ReadableStream({
    async start(controller) {
      try {
        const geminiStream = await createGeminiClient().models.generateContentStream({
          model: GEMINI_MODEL,
          contents: toGeminiContents(messages),
          config: { systemInstruction: systemPrompt, maxOutputTokens: 2048 },
        })

        let fullText = ''

        for await (const response of geminiStream) {
          const chunk = response.text || ''
          if (chunk) {
            fullText += chunk
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ chunk })}\n\n`))
          }
        }

        // Signal de fin avec le texte complet
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true, full: fullText })}\n\n`))
        controller.close()
      } catch (err: any) {
        console.error('Gemini stream error:', err)
        const errorMessage = String(err?.message || '')
        const message = /quota|resource_exhausted|429/i.test(errorMessage)
          ? 'Le quota Gemini est atteint. Réessayez plus tard ou vérifiez les limites de votre compte Google AI.'
          : 'Gemini n’a pas pu répondre. Vérifiez la clé GEMINI_API_KEY et réessayez.'
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: message })}\n\n`))
        controller.close()
      }
    }
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    }
  })
}
