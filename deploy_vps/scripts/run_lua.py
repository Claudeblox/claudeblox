# run_lua.py
# Helper script to execute Lua code via MCP
# Usage: python run_lua.py "your lua code"

import subprocess
import sys
import json

def run_lua(code):
    """
    Execute Lua code in Roblox Studio via MCP.

    This requires:
    1. Roblox Studio running with MCP plugin
    2. MCP server running (rbx-studio-mcp.exe)
    3. Claude Code connected to MCP

    For standalone execution, this script sends HTTP request to local MCP bridge.
    """
    # Try to use MCP bridge if available
    import requests

    try:
        response = requests.post(
            "http://localhost:8586/run_code",
            json={"code": code},
            timeout=10
        )
        if response.status_code == 200:
            return response.json().get("result", "")
        else:
            return f"Error: {response.status_code}"
    except requests.exceptions.ConnectionError:
        # Fallback: print code for manual execution
        print("MCP bridge not available. Execute this Lua code manually:")
        print("-" * 40)
        print(code)
        print("-" * 40)
        return ""
    except Exception as e:
        return f"Error: {e}"

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_lua.py 'lua code'")
        print("       python run_lua.py --file script.lua")
        sys.exit(1)

    if sys.argv[1] == "--file":
        if len(sys.argv) < 3:
            print("Error: --file requires a filename")
            sys.exit(1)
        with open(sys.argv[2], "r", encoding="utf-8") as f:
            code = f.read()
    else:
        code = sys.argv[1]

    result = run_lua(code)
    print(result)

if __name__ == "__main__":
    main()
