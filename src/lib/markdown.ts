/**
 * Convertit du texte Markdown en HTML sécurisé
 * Support : titres, gras, italique, code inline, blocs code, listes, blockquote, liens
 */
export function renderMarkdown(text: string): string {
  let html = text

  // Blocs de code (``` ... ```) — à traiter avant le reste
  html = html.replace(/```(\w+)?\n?([\s\S]*?)```/g, (_, lang, code) => {
    const escaped = code.trim().replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return `<pre class="code-block"${lang ? ` data-lang="${lang}"` : ''}><code>${escaped}</code></pre>`
  })

  // Code inline `...`
  html = html.replace(/`([^`\n]+)`/g, '<code class="inline-code">$1</code>')

  // Titres
  html = html.replace(/^### (.+)$/gm, '<h3>$1</h3>')
  html = html.replace(/^## (.+)$/gm, '<h2>$1</h2>')
  html = html.replace(/^# (.+)$/gm, '<h1>$1</h1>')

  // Gras et italique
  html = html.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>')

  // Blockquote
  html = html.replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>')

  // Listes non-ordonnées
  html = html.replace(/^[-•] (.+)$/gm, '<li>$1</li>')
  html = html.replace(/(<li>[\s\S]*?<\/li>)(\n(?!<li>)|$)/g, '<ul>$1</ul>$2')

  // Listes ordonnées
  html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>')

  // Liens [texte](url)
  html = html.replace(/\[([^\]]+)\]\((https?:\/\/[^\)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>')

  // Séparateurs ---
  html = html.replace(/^---$/gm, '<hr>')

  // Paragraphes : double saut de ligne
  html = html.split(/\n{2,}/).map(block => {
    if (/^<(h[1-3]|ul|ol|li|pre|blockquote|hr)/.test(block.trim())) return block
    if (block.trim() === '') return ''
    return `<p>${block.replace(/\n/g, '<br>')}</p>`
  }).join('\n')

  return html
}
