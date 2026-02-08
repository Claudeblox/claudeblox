#!/usr/bin/env python3
"""
Image Generation MCP Server - FLUX.2 Max / Gemini via OpenRouter
Tool: generate_cover
"""

import json
import sys
import os
import requests
import base64
from datetime import datetime
from pathlib import Path

OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY", "")
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OUTPUT_DIR = Path("/data/generated_images")

# For Supabase Storage upload
SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "")

# Fallback URL for serving images locally
BASE_URL = "https://claudezilla-games.up.railway.app"

MODELS = {
    "flux": "black-forest-labs/flux.2-max",
    "gemini": "google/gemini-2.5-flash-preview:image",
}

QUALITY = "award-winning, masterpiece composition, stunning visual impact, breathtaking detail, professional color grading, perfect lighting, 8K ultra high resolution, extraordinary quality"

STYLES = {
    "cover": {
        "prefix": "Epic video game key art, official game cover illustration, heroic dramatic pose,",
        "suffix": "centered subject with dramatic backlighting, dark moody background with glowing accents, vertical composition, intense atmosphere, style of Hades, Dead Cells, Hollow Knight cover art, high contrast lighting, vivid colors against dark, professional digital painting, iconic memorable composition"
    },
    "icon": {
        "prefix": "Premium app icon design, perfectly composed square artwork,",
        "suffix": "bold simple shapes, instantly recognizable, vibrant colors on dark background, glossy professional finish, App Store featured quality, clean modern design, striking visual impact"
    },
    "neon": {
        "prefix": "Stunning cyberpunk neon artwork, electric atmosphere,",
        "suffix": "vibrant neon glow effects, deep blacks with color pop, cinematic contrast, blade runner aesthetic, reflective wet surfaces, volumetric fog with light rays, synthwave color palette, futuristic elegance"
    },
    "game": {
        "prefix": "AAA video game concept art, blockbuster quality,",
        "suffix": "dynamic composition, epic scale, detailed environment design, dramatic lighting, rich color palette, professional digital painting, trending on ArtStation, Unreal Engine 5 quality"
    },
    "fantasy": {
        "prefix": "Magnificent fantasy artwork, legendary scene,",
        "suffix": "magical atmosphere, ethereal lighting, rich jewel tones, epic composition, intricate details, mythical beauty, painterly quality, enchanted mood, breathtaking wonder"
    },
    "minimal": {
        "prefix": "Elegant minimalist design, premium aesthetic,",
        "suffix": "clean lines, sophisticated simplicity, perfect negative space, refined color palette, Apple-level design quality, modern luxury feel, high-end brand aesthetic"
    }
}

GEMINI_SYSTEM = """You are a legendary visual artist. Every image must be BREATHTAKINGLY BEAUTIFUL with cinematic lighting, powerful colors, perfect composition, and extraordinary detail."""


def log(msg):
    sys.stderr.write(f"[gen_mcp] {msg}\n")
    sys.stderr.flush()


def log_tool_call(tool_name, args, result=None, error=None):
    """Auto-log every MCP tool call to public.logs via Supabase"""
    if not SUPABASE_URL or not SUPABASE_KEY:
        log("Skipping log_tool_call: SUPABASE_URL or SUPABASE_KEY not set")
        return

    try:
        url = f"{SUPABASE_URL}/rest/v1/logs"
        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "application/json"
        }
        message = f"[MCP ERROR] {tool_name}: {error}" if error else f"[MCP] {tool_name} called"
        details = {
            "tool": tool_name,
            "args": args,
            "result": result if not error else None,
            "error": error,
        }
        data = {
            "action": f"mcp_{tool_name}",
            "message": message,
            "role": "error" if error else "mcp",
            "details": json.dumps(details)
        }
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        log(f"Logged MCP call: {tool_name}")
    except Exception as e:
        log(f"Failed to log tool call: {e}")


def enhance_prompt(prompt, style="cover"):
    s = STYLES.get(style, STYLES["cover"])
    return f"{s['prefix']} {prompt}, {s['suffix']}, {QUALITY}"


def upload_to_supabase_storage(file_path, filename):
    """Upload image to Supabase Storage and return public URL."""
    if not SUPABASE_URL or not SUPABASE_KEY:
        log("Skipping Supabase upload: credentials not set")
        return None

    try:
        bucket = "images"
        folder = "covers"
        storage_path = f"{folder}/{filename}"

        url = f"{SUPABASE_URL}/storage/v1/object/{bucket}/{storage_path}"

        with open(file_path, "rb") as f:
            file_data = f.read()

        headers = {
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "Content-Type": "image/png",
            "x-upsert": "true"  # Overwrite if exists
        }

        response = requests.post(url, headers=headers, data=file_data)
        response.raise_for_status()

        # Return public URL
        public_url = f"{SUPABASE_URL}/storage/v1/object/public/{bucket}/{storage_path}"
        log(f"Uploaded to Supabase: {public_url}")
        return public_url
    except Exception as e:
        log(f"Supabase upload failed: {e}")
        return None


def save_image(b64_data, prefix="cover"):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    if "base64," in b64_data:
        b64_data = b64_data.split("base64,")[1]
    data = base64.b64decode(b64_data)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{prefix}_{ts}.png"
    path = OUTPUT_DIR / filename
    path.write_bytes(data)

    # Try Supabase Storage upload first
    public_url = upload_to_supabase_storage(str(path), filename)

    # Fallback to local /images/ endpoint if Supabase fails
    if not public_url:
        public_url = f"{BASE_URL}/images/{filename}"
        log(f"Using fallback URL: {public_url}")

    return str(path), public_url, filename


def extract_image(result):
    if "choices" not in result or not result["choices"]:
        return None
    msg = result["choices"][0].get("message", {})

    # Check images field
    imgs = msg.get("images", [])
    if imgs:
        return imgs[0].get("image_url", {}).get("url", "")

    # Check content
    content = msg.get("content", "")
    if isinstance(content, str) and "data:image" in content:
        return content
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "image_url":
                return item.get("image_url", {}).get("url", "")
    return None


def call_flux(prompt):
    log(f"Calling FLUX: {prompt[:60]}...")
    resp = requests.post(
        OPENROUTER_URL,
        headers={
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://claudezilla-games.up.railway.app",
            "X-Title": "Claudezilla Games"
        },
        json={
            "model": MODELS["flux"],
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 4096
        },
        timeout=180
    )
    resp.raise_for_status()
    return resp.json()


def call_gemini(prompt):
    log(f"Calling Gemini: {prompt[:60]}...")
    resp = requests.post(
        OPENROUTER_URL,
        headers={
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://claudezilla-games.up.railway.app",
            "X-Title": "Claudezilla Games"
        },
        json={
            "model": MODELS["gemini"],
            "messages": [
                {"role": "system", "content": GEMINI_SYSTEM},
                {"role": "user", "content": prompt}
            ],
            "modalities": ["image", "text"],
            "image_config": {"aspect_ratio": "1:1", "image_size": "4K"},
            "max_tokens": 4096
        },
        timeout=180
    )
    resp.raise_for_status()
    return resp.json()


def generate_cover(prompt, style="cover"):
    """Generate a cover image using Gemini 2.5 Flash (fallback to FLUX)"""
    if not OPENROUTER_API_KEY:
        return {"ok": False, "error": "OPENROUTER_API_KEY not set"}

    enhanced = enhance_prompt(prompt, style)

    # Try Gemini first (better quality)
    try:
        result = call_gemini(enhanced)
        img = extract_image(result)
        if img:
            path, public_url, filename = save_image(img, f"{style}")
            log(f"Gemini success: {path}, URL: {public_url}")
            return {"ok": True, "path": path, "url": public_url, "model": "gemini-2.5-flash"}
        log("Gemini no image, trying FLUX...")
    except Exception as e:
        log(f"Gemini error: {e}, trying FLUX...")

    # Fallback to FLUX
    try:
        result = call_flux(enhanced)
        img = extract_image(result)
        if img:
            path, public_url, filename = save_image(img, f"{style}")
            log(f"FLUX success: {path}, URL: {public_url}")
            return {"ok": True, "path": path, "url": public_url, "model": "flux.2-max"}
        return {"ok": False, "error": "No image from both models"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def send_response(response):
    sys.stdout.write(json.dumps(response) + "\n")
    sys.stdout.flush()


def handle_request(request):
    method = request.get("method")
    id = request.get("id")

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "gen-mcp", "version": "1.0.0"}
            }
        }

    elif method == "notifications/initialized":
        return None

    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": id,
            "result": {
                "tools": [{
                    "name": "generate_cover",
                    "description": "Generate a game cover image using AI (FLUX.2 Max / Gemini). Returns path to generated image.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "prompt": {
                                "type": "string",
                                "description": "Description of the cover art: mood, colors, key visual elements, game genre"
                            },
                            "style": {
                                "type": "string",
                                "enum": list(STYLES.keys()),
                                "description": "Style preset: cover (default), icon, neon, game, fantasy, minimal"
                            }
                        },
                        "required": ["prompt"]
                    }
                }]
            }
        }

    elif method == "tools/call":
        tool_name = request.get("params", {}).get("name")
        args = request.get("params", {}).get("arguments", {})

        if tool_name == "generate_cover":
            prompt = args.get("prompt", "")
            style = args.get("style", "cover")

            if not prompt:
                log_tool_call(tool_name, args, error="prompt is required")
                return {
                    "jsonrpc": "2.0",
                    "id": id,
                    "result": {
                        "content": [{"type": "text", "text": "Error: prompt is required"}],
                        "isError": True
                    }
                }

            result = generate_cover(prompt, style)

            if result["ok"]:
                log_tool_call(tool_name, args, {"path": result["path"], "url": result.get("url"), "model": result["model"]})
                return {
                    "jsonrpc": "2.0",
                    "id": id,
                    "result": {
                        "content": [{
                            "type": "text",
                            "text": json.dumps({
                                "success": True,
                                "path": result["path"],
                                "url": result.get("url"),  # Public URL from Supabase Storage
                                "model": result["model"]
                            })
                        }]
                    }
                }
            else:
                log_tool_call(tool_name, args, error=result["error"])
                return {
                    "jsonrpc": "2.0",
                    "id": id,
                    "result": {
                        "content": [{"type": "text", "text": f"Error: {result['error']}"}],
                        "isError": True
                    }
                }

    return {"jsonrpc": "2.0", "id": id, "result": {}}


def main():
    log("Starting gen MCP server")
    log(f"OPENROUTER_API_KEY: {'SET' if OPENROUTER_API_KEY else 'NOT SET'}")
    for line in sys.stdin:
        try:
            request = json.loads(line.strip())
            response = handle_request(request)
            if response:
                send_response(response)
        except json.JSONDecodeError:
            pass
        except Exception as e:
            log(f"Error: {e}")


if __name__ == "__main__":
    main()
