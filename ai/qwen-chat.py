#!/usr/bin/env python3
"""Chat with a local Ollama model; replies are rendered as styled markdown by glow.

The reply streams in as plain text, then is redrawn styled once it's done.
A reply too long for the screen switches to a line counter while it's written.

  qwen-chat.py MODEL             interactive chat
  qwen-chat.py MODEL "question"  one answer, then exit
  qwen-chat.py MODEL --last      continue the most recent saved chat
  qwen-chat.py MODEL --resume F  continue the saved chat in file F
  /clear forgets the conversation, /bye or Ctrl+D quits, Ctrl+C stops a reply.
  Each code block gets a Copy button (Ctrl+click). /c copies the last reply's
  code too; /c 2 copies its block 2.
  Every chat is saved as markdown in $QWEN_CHATS (default ~/Documents/qwen-chats).
"""

import json
import os
import re
import readline  # noqa: F401  (arrow keys + history in input())
import shutil
import subprocess
import sys
import time
from datetime import datetime
import urllib.request

HOST = os.environ.get("OLLAMA_API_BASE", "http://127.0.0.1:11434")
DIM, RESET = "\033[2m", "\033[0m"
STYLE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "glow-style.json")
# Code blocks behind the Copy buttons; ai/qwen-copy reads them when one is clicked.
SAVE_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "qwen-copy")
saved = 0
CHATS_DIR = os.path.expanduser(os.environ.get("QWEN_CHATS", "~/Documents/qwen-chats"))


def cols():
    return shutil.get_terminal_size().columns


def rows():
    return shutil.get_terminal_size().lines


def screen_lines(text):
    """How many terminal rows the text takes up once wrapped."""
    w = cols()
    return sum(max(1, -(-len(line) // w)) for line in text.split("\n"))


def render(text):
    """Print the reply styled by glow, with a Copy button above each code block."""
    blocks = code_blocks(text)
    if not shutil.which("glow"):
        print(text)
        return
    marked, ids = text, [save_block(b) for b in blocks]
    if ids:
        n = iter(range(len(ids)))
        marked = FENCE.sub(lambda m: f"{m.group(1)}QWENCOPY{next(n)}\n\n{m.group(0)}", text)
    style = STYLE if os.path.isfile(STYLE) else "dark"
    width = str(min(cols() - 2, 100))
    out = subprocess.run(
        ["glow", "-s", style, "-w", width, "-"],
        input=marked.encode(), capture_output=True, env={**os.environ, "CLICOLOR_FORCE": "1"},
    ).stdout.decode(errors="replace")
    out = TRAILING.sub("", out)  # glow pads lines with spaces; drop them so mouse copy is clean
    for i, block_id in enumerate(ids):
        out = out.replace(f"QWENCOPY{i}", button(block_id), 1)
    sys.stdout.write(out)


TRAILING = re.compile(r"(?:\033\[[0-9;]*m| )+$", re.M)


def save_block(code):
    global saved
    saved += 1
    block_id = f"{os.getpid()}-{saved}"
    os.makedirs(SAVE_DIR, mode=0o700, exist_ok=True)
    with open(os.path.join(SAVE_DIR, block_id), "w") as f:
        f.write(code + "\n")
    return block_id


def button(block_id):
    """A clickable (OSC 8 link) Copy label; ai/qwen-copy handles qwen-copy:// links."""
    return f"\033]8;;qwen-copy://{block_id}\033\\\033[38;5;232;48;5;39;1m ⧉ Copy \033[0m\033]8;;\033\\"


def prune_saved():
    """Forget code blocks saved more than a day ago."""
    try:
        for name in os.listdir(SAVE_DIR):
            path = os.path.join(SAVE_DIR, name)
            if time.time() - os.path.getmtime(path) > 86400:
                os.remove(path)
    except OSError:
        pass


FENCE = re.compile(r"^([ \t]*)(`{3,}|~{3,})[^\n]*\n(.*?)^[ \t]*\2[ \t]*$", re.M | re.S)


def code_blocks(text):
    """The fenced code blocks in a reply, with list indentation taken off."""
    blocks = []
    for m in FENCE.finditer(text):
        indent = len(m.group(1))
        lines = [line[indent:] if line[:indent].isspace() else line for line in m.group(3).split("\n")]
        blocks.append("\n".join(lines).rstrip("\n"))
    return blocks


def copy(text):
    for cmd in (["wl-copy"], ["xclip", "-selection", "clipboard"]):
        if shutil.which(cmd[0]):
            subprocess.run(cmd, input=text.encode())
            return True
    return False


def stream(model, messages):
    body = json.dumps({"model": model, "messages": messages, "think": False}).encode()
    req = urllib.request.Request(f"{HOST}/api/chat", body, {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        for line in resp:
            chunk = json.loads(line)
            if "error" in chunk:
                raise RuntimeError(chunk["error"])
            yield chunk.get("message", {}).get("content", "")


def answer(model, messages):
    """Stream the reply dimmed, then replace it with the styled version."""
    reply, shown, live = "", 0, True
    try:
        for piece in stream(model, messages):
            reply += piece
            if live:
                sys.stdout.write(DIM + piece + RESET)
                shown = screen_lines(reply)
                if shown >= rows() - 3:  # about to scroll: stop echoing
                    sys.stdout.write(f"\033[{shown - 1}F\033[J" if shown > 1 else "\r\033[J")
                    live = False
            if not live:
                sys.stdout.write(f"\r\033[K{DIM}writing… {reply.count(chr(10)) + 1} lines{RESET}")
            sys.stdout.flush()
    except KeyboardInterrupt:
        reply += "\n\n*(stopped)*"
    if live and shown > 1:
        sys.stdout.write(f"\033[{shown - 1}F")
    sys.stdout.write("\r\033[J")
    sys.stdout.flush()
    render(reply)
    return reply


def chat_path(first_question):
    """A new file for a chat: date, time and the first words of the question."""
    slug = re.sub(r"[^a-z0-9]+", "-", first_question.lower())[:40].strip("-") or "chat"
    path = os.path.join(CHATS_DIR, f"{datetime.now():%Y-%m-%d_%H%M}-{slug}.md")
    n = 2
    while os.path.exists(path):
        path = os.path.join(CHATS_DIR, f"{datetime.now():%Y-%m-%d_%H%M}-{slug}-{n}.md")
        n += 1
    return path


def save_chat(path, model, started, messages):
    """Rewrite the chat file after every reply, so nothing is lost if the window closes."""
    title = " ".join(messages[0]["content"].split())[:80]
    parts = [f"# {title}\n\n*{model} · {started:%Y-%m-%d %H:%M} · {os.getcwd()}*\n"]
    for m in messages:
        who = "You" if m["role"] == "user" else "Qwen"
        parts.append(f"## {who}\n\n{m['content'].strip()}\n")
    try:
        os.makedirs(CHATS_DIR, exist_ok=True)
        with open(path, "w") as f:
            f.write("\n".join(parts))
    except OSError as e:
        print(f"{DIM}(couldn't save the chat: {e}){RESET}")


def load_chat(path):
    """Read a saved chat back: its start time and messages (the ## You / ## Qwen sections)."""
    with open(path) as f:
        text = f.read()
    m = re.search(r"^\*.*? · (\d{4}-\d{2}-\d{2} \d{2}:\d{2}) · ", text, re.M)
    started = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M") if m else datetime.now()
    parts = re.split(r"^## (You|Qwen)\n\n", text, flags=re.M)
    messages = [
        {"role": "user" if who == "You" else "assistant", "content": body.strip()}
        for who, body in zip(parts[1::2], parts[2::2])
    ]
    return started, messages


def latest_chat():
    try:
        files = [os.path.join(CHATS_DIR, f) for f in os.listdir(CHATS_DIR) if f.endswith(".md")]
    except OSError:
        files = []
    return max(files, key=os.path.getmtime, default=None)


def ask():
    """One prompt; a line of just triple quotes starts/ends a multi-line message."""
    first = input("\033[1;36m>>>\033[0m ")
    if first.strip() != '"""':
        return first
    lines = []
    while (line := input("... ")).strip() != '"""':
        lines.append(line)
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    model, messages, last = sys.argv[1], [], ""
    path, started = None, datetime.now()
    prune_saved()

    try:
        if len(sys.argv) > 2 and sys.argv[2] in ("--last", "--resume"):
            path = latest_chat() if sys.argv[2] == "--last" else " ".join(sys.argv[3:])
            if not path or not os.path.isfile(path):
                sys.exit("qwen: no saved chat to continue" + (f" ({path})" if path else ""))
            started, messages = load_chat(path)
            if messages and messages[-1]["role"] == "assistant":
                last = messages[-1]["content"]
            title = os.path.basename(path)[:-3]
            print(f"{DIM}continuing {title} ({len(messages) // 2} earlier questions) — last answer:{RESET}")
            if last:
                render(last)
        elif len(sys.argv) > 2:
            messages = [{"role": "user", "content": " ".join(sys.argv[2:])}]
            messages.append({"role": "assistant", "content": answer(model, messages)})
            save_chat(chat_path(messages[0]["content"]), model, started, messages)
            return
        print(f"{DIM}{model} — /c copies code, /clear starts over, /bye quits{RESET}")
        while True:
            try:
                text = ask().strip()
            except KeyboardInterrupt:
                print()
                continue
            if not text:
                continue
            if text in ("/bye", "/exit", "/quit"):
                break
            if text == "/clear":
                messages, path, started = [], None, datetime.now()
                print(f"{DIM}(conversation cleared){RESET}")
                continue
            if text.split()[0] in ("/c", "/copy"):
                blocks, arg = code_blocks(last), text.split()[1:]
                n = int(arg[0]) if arg and arg[0].isdigit() else 1
                if not blocks:
                    print(f"{DIM}(no code in the last reply){RESET}")
                elif not 1 <= n <= len(blocks):
                    print(f"{DIM}(pick 1–{len(blocks)}){RESET}")
                elif copy(blocks[n - 1]):
                    print(f"{DIM}(copied code block {n}){RESET}")
                else:
                    print(f"{DIM}(no clipboard tool: install wl-clipboard){RESET}")
                continue
            messages.append({"role": "user", "content": text})
            last = answer(model, messages)
            messages.append({"role": "assistant", "content": last})
            path = path or chat_path(messages[0]["content"])
            save_chat(path, model, started, messages)
    except EOFError:
        print()
    except (OSError, RuntimeError) as e:
        sys.exit(f"qwen: can't reach Ollama ({e}) — try ai-on")


if __name__ == "__main__":
    main()
