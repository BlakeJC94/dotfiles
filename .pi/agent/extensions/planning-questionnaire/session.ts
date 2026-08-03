/** Extract the readable text content of a session message, joining text blocks. */
export function messageText(message: unknown): string {
  if (!message || typeof message !== "object") return ""
  const content = (message as { content?: unknown }).content
  if (typeof content === "string") return content.trim()
  if (!Array.isArray(content)) return ""

  return content
    .flatMap((item) => {
      if (!item || typeof item !== "object") return []
      const block = item as { type?: unknown; text?: unknown }
      if (block.type !== "text" || typeof block.text !== "string") return []
      return [block.text]
    })
    .join("\n")
    .trim()
}
