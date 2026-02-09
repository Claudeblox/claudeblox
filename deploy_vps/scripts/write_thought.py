"""
Write a thought to the stream overlay.
Usage: python write_thought.py "your thought here"

Subagents (computer-player, world-builder) call this to show thoughts on stream.
"""
import sys
import json
import os
from datetime import datetime

THOUGHTS_FILE = r"C:\claudeblox\stream\thoughts.js"
MAX_THOUGHTS = 8  # Keep last 8 thoughts


def write_thought(text):
    os.makedirs(os.path.dirname(THOUGHTS_FILE), exist_ok=True)

    # Read existing thoughts
    thoughts = []
    if os.path.exists(THOUGHTS_FILE):
        try:
            with open(THOUGHTS_FILE, 'r', encoding='utf-8') as f:
                content = f.read()
                # Parse: var thoughts = [...];
                start = content.find('[')
                end = content.rfind(']') + 1
                if start != -1 and end != 0:
                    thoughts = json.loads(content[start:end])
        except Exception:
            thoughts = []

    # Add new thought
    thoughts.append({
        "time": datetime.now().strftime("%H:%M:%S"),
        "text": text
    })

    # Keep only last N
    thoughts = thoughts[-MAX_THOUGHTS:]

    # Write back
    with open(THOUGHTS_FILE, 'w', encoding='utf-8') as f:
        f.write(f"var thoughts = {json.dumps(thoughts, ensure_ascii=False, indent=2)};")

    print(f"Thought written: {text}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        write_thought(" ".join(sys.argv[1:]))
    else:
        print("Usage: python write_thought.py \"your thought\"")
