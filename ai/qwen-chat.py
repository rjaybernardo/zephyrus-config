#!/usr/bin/env python3
"""Chat with a local Ollama model; replies are rendered as styled markdown by glow.

The reply streams in as plain text, then is redrawn styled once it's done.
A reply too long for the screen switches to a line counter while it's written.

  qwen-chat.py MODEL             interactive chat
  qwen-chat.py MODEL "question"  one answer, then exit
  /clear forgets the conversation, /bye or Ctrl+D quits, Ctrl+C stops a reply.
  Each code block gets a Copy button (Ctrl+click). /c copies the last reply's
  code too; /c 2 copies its block 2.
"""

import json
import os
import re
import readline  # noqa: F401  (arrow keys + history in input())
import shutil
import subprocess
import sys
import time
import urllib.request

HOST = os.environ.get("OLLAMA_API_BASE", "http://127.0.0.1:11434")
DIM, RESET = "\033[2m", "\033[0m"
STYLE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "glow-style.json")
# Code blocks behind the Copy buttons; ai/qwen-copy reads them when one is clicked.
SAVE_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", "qwen-copy")
saved = 0


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
    prune_saved()

    try:
        if len(sys.argv) > 2:
            answer(model, [{"role": "user", "content": " ".join(sys.argv[2:])}])
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
                messages = []
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
    except EOFError:
        print()
    except (OSError, RuntimeError) as e:
        sys.exit(f"qwen: can't reach Ollama ({e}) — try ai-on")


if __name__ == "__main__":
    main()
