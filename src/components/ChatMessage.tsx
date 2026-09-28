'use client'
import { renderMarkdown } from '@/lib/markdown'
import { useState } from 'react'
import styles from './ChatMessage.module.css'

type Props = {
  role: 'user' | 'assistant'
  content: string
}

export function ChatMessage({ role, content }: Props) {
  const [copied, setCopied] = useState(false)

  async function copy() {
    await navigator.clipboard.writeText(content)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className={`${styles.msg} ${role === 'user' ? styles.user : styles.ai}`}>
      {role === 'assistant' && (
        <div className={styles.avatar} aria-hidden>⚡</div>
      )}
      <div className={styles.bubbleWrapper}>
        <div
          className={`${styles.bubble} msg-content`}
          dangerouslySetInnerHTML={{
            __html: role === 'assistant' ? renderMarkdown(content) : escapeHtml(content)
          }}
        />
        {role === 'assistant' && (
          <button className={styles.copyBtn} onClick={copy} title="Copier la réponse" aria-label="Copier">
            {copied ? '✓ Copié' : '⧉ Copier'}
          </button>
        )}
      </div>
    </div>
  )
}

function escapeHtml(str: string) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br>')
}
