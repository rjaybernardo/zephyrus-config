#!/usr/bin/env python3
"""Chat with a local Ollama model; replies are rendered as styled markdown by glow.

The reply streams in as plain text, then is redrawn styled once it's done.
A reply too long for the screen switches to a line counter while it's written.

  qwen-chat.py MODEL             interactive chat
  qwen-chat.py MODEL "question"  one answer, then exit
  /clear forgets the conversation, /bye or Ctrl+D quits, Ctrl+C stops a reply.
"""

import json
import os
import readline  # noqa: F401  (arrow keys + history in input())
import shutil
import subprocess
import sys
import urllib.request

HOST = os.environ.get("OLLAMA_API_BASE", "http://127.0.0.1:11434")
DIM, RESET = "\033[2m", "\033[0m"


def cols():
    return shutil.get_terminal_size().columns


def rows():
    return shutil.get_terminal_size().lines


def screen_lines(text):
    """How many terminal rows the text takes up once wrapped."""
    w = cols()
    return sum(max(1, -(-len(line) // w)) for line in text.split("\n"))


def render(text):
    if shutil.which("glow"):
        width = str(min(cols() - 2, 100))
        subprocess.run(["glow", "-s", "auto", "-w", width, "-"], input=text.encode())
    else:
        print(text)


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
    model, messages = sys.argv[1], []

    try:
        if len(sys.argv) > 2:
            answer(model, [{"role": "user", "content": " ".join(sys.argv[2:])}])
            return
        print(f"{DIM}{model} — /clear to start over, /bye to quit{RESET}")
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
            messages.append({"role": "user", "content": text})
            messages.append({"role": "assistant", "content": answer(model, messages)})
    except EOFError:
        print()
    except (OSError, RuntimeError) as e:
        sys.exit(f"qwen: can't reach Ollama ({e}) — try ai-on")


if __name__ == "__main__":
    main()
