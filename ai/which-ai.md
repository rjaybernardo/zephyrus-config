# Which AI? Local (Qwen) or Claude

## Local — default (`ai-on`)
- Explain a file, function or error message
- Inline edits and quick fixes (`<leader>ci`; inline is local only)
- Boilerplate: components, Zod schemas, loaders/actions, tests
- "Where is X?" in a project (`RAG:` in chat, `llm-rag-query`)
- Private code, or no internet
- Stack sheet loads by itself in Next.js / Shopify projects

## Claude — switch with `<leader>ct`, then `<leader>cn` for a new chat
- Changes across many files, or a new feature end to end
- Bugs the local model didn't solve on the first try
- Screenshots and images (use Claude Code in a terminal or claude.ai)
- APIs the stack sheet doesn't cover, or a library you just upgraded
- Architecture / "how should I build this?" questions
- Anything you will ship without reading every line

## Rule of thumb
Start local. If the answer is wrong twice, or the task touches more than
2–3 files, switch to Claude. Switch back (`<leader>ct`) when done — local
keeps code private and costs nothing.
