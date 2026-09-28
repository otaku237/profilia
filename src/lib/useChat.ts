import { useState, useCallback } from 'react'
import { createClient } from './supabase'

export type Message = { id: string; role: 'user' | 'assistant'; content: string; created_at?: string }
export type Conversation = { id: string; title: string; created_at: string }

export function useChat(userId: string | null) {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [currentConvId, setCurrentConvId] = useState<string | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [loading, setLoading] = useState(false)
  const [streamingContent, setStreamingContent] = useState('')
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
    setCurrentConvId(convId); await loadMessages(convId)
  }, [loadMessages])

  const newConversation = useCallback(() => {
    setCurrentConvId(null); setMessages([]); setStreamingContent('')
  }, [])

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
    setLoading(true); setStreamingContent('')
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

      // Streaming SSE
      const res = await fetch('/api/chat-stream', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: allMessages })
      })
      if (!res.ok) throw new Error((await res.text()) || `Erreur serveur (${res.status})`)

      const reader = res.body!.getReader()
      const decoder = new TextDecoder()
      let fullReply = ''
      let buffer = ''

      const processEvent = (event: string) => {
        const data = event.split(/\r?\n/)
          .filter(line => line.startsWith('data: '))
          .map(line => line.slice(6))
          .join('\n')
        if (!data) return

        const json = JSON.parse(data)
        if (json.error) throw new Error(json.error)
        if (json.chunk) { fullReply += json.chunk; setStreamingContent(fullReply) }
        if (json.done) fullReply = json.full
      }

      while (true) {
        const { done, value } = await reader.read()
        buffer += decoder.decode(value, { stream: !done })
        let boundary: RegExpExecArray | null
        const eventBoundary = /\r?\n\r?\n/
        while ((boundary = eventBoundary.exec(buffer)) !== null) {
          processEvent(buffer.slice(0, boundary.index))
          buffer = buffer.slice(boundary.index + boundary[0].length)
        }
        if (done) break
      }
      if (buffer.trim()) processEvent(buffer)

      const { data: saved } = await supabase.from('messages')
        .insert({ conversation_id: convId, role: 'assistant', content: fullReply }).select().single()
      setStreamingContent('')
      if (saved) setMessages(prev => [...prev, saved])
    } catch (error) {
      setStreamingContent('')
      const reason = error instanceof Error ? error.message : 'Erreur inconnue'
      setMessages(prev => [...prev, { id: `err-${Date.now()}`, role: 'assistant', content: `⚠️ ${reason}` }])
    } finally { setLoading(false) }
  }, [loading, userId, currentConvId, messages, loadConversations])

  return { conversations, currentConvId, messages, loading, streamingContent, loadConversations, selectConversation, newConversation, deleteConversation, renameConversation, clearAll, sendMessage }
}
