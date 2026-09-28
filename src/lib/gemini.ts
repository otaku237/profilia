import { GoogleGenAI } from '@google/genai'

export const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash'

export function createGeminiClient() {
  const apiKey = process.env.GEMINI_API_KEY
  if (!apiKey) throw new Error('La variable GEMINI_API_KEY est absente de la configuration.')
  return new GoogleGenAI({ apiKey })
}

export function toGeminiContents(messages: { role: string; content: string }[]) {
  return messages.map(({ role, content }) => ({
    role: role === 'assistant' ? 'model' : 'user',
    parts: [{ text: content }],
  }))
}