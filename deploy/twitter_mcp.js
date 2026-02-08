#!/usr/bin/env node

/**
 * Claudezilla Games - Twitter MCP Server
 *
 * Tools:
 * - post_tweet: post tweet (auto-saves to DB)
 * - post_tweet_with_media: tweet with 1-4 images (auto-uploads, auto-saves)
 * - log_action: log action to DB
 * - get_recent_posts: get recent posts for context
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import pg from "pg";
import { TwitterApi } from "twitter-api-v2";
import fs from "fs";
import path from "path";
import https from "https";
import http from "http";

const { Pool } = pg;

// ═══════════════════════════════════════════════════════════════════════════
// CONFIG
// ═══════════════════════════════════════════════════════════════════════════

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// Twitter client (OAuth 1.0a User Context)
const twitterClient = new TwitterApi({
  appKey: process.env.TWITTER_API_KEY,
  appSecret: process.env.TWITTER_API_SECRET,
  accessToken: process.env.TWITTER_ACCESS_TOKEN,
  accessSecret: process.env.TWITTER_ACCESS_SECRET,
});

// Read-write client
const twitter = twitterClient.readWrite;

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

function log(msg) {
  const ts = new Date().toISOString();
  console.error(`[${ts}] ${msg}`);
}

async function dbQuery(sql, params = []) {
  const client = await pool.connect();
  try {
    const result = await client.query(sql, params);
    return result.rows;
  } finally {
    client.release();
  }
}

/**
 * Auto-log every MCP tool call to claudeblox.logs
 */
async function logToolCall(toolName, args, result, error = null) {
  try {
    const message = error
      ? `[MCP ERROR] ${toolName}: ${error}`
      : `[MCP] ${toolName} called`;

    const details = {
      tool: toolName,
      args: args,
      result: error ? null : (typeof result === 'object' ? result : { value: result }),
      error: error || null,
      timestamp: new Date().toISOString()
    };

    await dbQuery(
      `INSERT INTO claudeblox.logs (action, message, role, details)
       VALUES ($1, $2, $3, $4)`,
      [`mcp_${toolName}`, message, error ? 'error' : 'mcp', JSON.stringify(details)]
    );

    log(`Logged MCP call: ${toolName}`);
  } catch (e) {
    log(`Failed to log tool call: ${e.message}`);
  }
}

async function savePostToDb(ideaId, tweetId, content, mediaUrls = []) {
  log(`Saving post to DB: idea_id=${ideaId}, tweet_id=${tweetId}`);
  try {
    await dbQuery(
      `INSERT INTO public.posts (idea_id, tweet_id, content, media_urls, success)
       VALUES ($1, $2, $3, $4, true)`,
      [ideaId, tweetId, content, mediaUrls]
    );
  } catch (error) {
    log(`Warning: failed to save post to DB: ${error.message}`);
  }
}

/**
 * Download file from URL to temp path
 */
async function downloadFile(url) {
  return new Promise((resolve, reject) => {
    log(`Downloading: ${url}`);

    const protocol = url.startsWith('https') ? https : http;
    const ext = path.extname(new URL(url).pathname) || '.png';
    const tempPath = `/tmp/media_${Date.now()}${ext}`;

    const file = fs.createWriteStream(tempPath);

    protocol.get(url, (response) => {
      // Handle redirects
      if (response.statusCode === 301 || response.statusCode === 302) {
        file.close();
        fs.unlinkSync(tempPath);
        return downloadFile(response.headers.location).then(resolve).catch(reject);
      }

      if (response.statusCode !== 200) {
        file.close();
        fs.unlinkSync(tempPath);
        return reject(new Error(`Failed to download: HTTP ${response.statusCode}`));
      }

      response.pipe(file);

      file.on('finish', () => {
        file.close();
        log(`Downloaded to: ${tempPath}`);
        resolve(tempPath);
      });
    }).on('error', (err) => {
      file.close();
      fs.unlink(tempPath, () => {});
      reject(err);
    });
  });
}

/**
 * Check if string is URL
 */
function isUrl(str) {
  return str.startsWith('http://') || str.startsWith('https://');
}

// ═══════════════════════════════════════════════════════════════════════════
// TOOL IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Post text tweet (auto-saves to DB)
 */
async function postTweet(text, ideaId = null) {
  log(`post_tweet: "${text.substring(0, 50)}..."`);

  if (text.length > 280) {
    throw new Error(`Tweet too long: ${text.length} chars (max 280)`);
  }

  const response = await twitter.v2.tweet(text);
  const tweetId = response.data.id;

  log(`post_tweet: success, tweet_id=${tweetId}`);

  // Auto-save to posts table
  await savePostToDb(ideaId, tweetId, text, []);

  return {
    success: true,
    tweet_id: tweetId,
    text: text,
    url: `https://twitter.com/i/status/${tweetId}`,
    saved_to_db: true
  };
}

/**
 * Upload image -> get media_id
 * Accepts URL (Supabase storage) or local path
 */
async function uploadMedia(imageSource) {
  log(`upload_media: ${imageSource}`);

  let localPath = imageSource;
  let isTemp = false;

  // If URL, download first
  if (isUrl(imageSource)) {
    localPath = await downloadFile(imageSource);
    isTemp = true;
  } else if (!fs.existsSync(imageSource)) {
    throw new Error(`File not found: ${imageSource}`);
  }

  try {
    const mediaId = await twitter.v1.uploadMedia(localPath);
    log(`upload_media: success, media_id=${mediaId}`);
    return { media_id: mediaId, source: imageSource };
  } finally {
    // Cleanup temp file
    if (isTemp && fs.existsSync(localPath)) {
      fs.unlinkSync(localPath);
      log(`upload_media: cleaned up temp file`);
    }
  }
}

/**
 * Post tweet with images (auto-saves to DB)
 * Supports 1-4 images (URLs from Supabase storage or local paths)
 */
async function postTweetWithMedia(text, imageSources, ideaId = null) {
  // Normalize to array
  const sources = Array.isArray(imageSources) ? imageSources : [imageSources];

  log(`post_tweet_with_media: "${text.substring(0, 30)}..." + ${sources.length} image(s)`);

  if (text.length > 280) {
    throw new Error(`Tweet too long: ${text.length} chars (max 280)`);
  }

  if (sources.length > 4) {
    throw new Error(`Too many images: ${sources.length} (max 4)`);
  }

  // Download URLs and upload all media
  const mediaIds = [];
  const tempFiles = [];

  try {
    for (const source of sources) {
      let localPath = source;

      // If URL, download first
      if (isUrl(source)) {
        localPath = await downloadFile(source);
        tempFiles.push(localPath);
      } else if (!fs.existsSync(source)) {
        throw new Error(`File not found: ${source}`);
      }

      const mediaId = await twitter.v1.uploadMedia(localPath);
      mediaIds.push(mediaId);
      log(`post_tweet_with_media: uploaded ${source} -> media_id=${mediaId}`);
    }

    // Post tweet with all media
    const response = await twitter.v2.tweet({
      text: text,
      media: { media_ids: mediaIds }
    });

    const tweetId = response.data.id;
    log(`post_tweet_with_media: success, tweet_id=${tweetId}`);

    // Auto-save to posts table (save original URLs, not temp paths)
    await savePostToDb(ideaId, tweetId, text, sources);

    return {
      success: true,
      tweet_id: tweetId,
      media_ids: mediaIds,
      media_count: sources.length,
      text: text,
      url: `https://twitter.com/i/status/${tweetId}`,
      saved_to_db: true
    };
  } finally {
    // Cleanup temp files
    for (const tempFile of tempFiles) {
      if (fs.existsSync(tempFile)) {
        fs.unlinkSync(tempFile);
        log(`post_tweet_with_media: cleaned up ${tempFile}`);
      }
    }
  }
}

/**
 * Log action to DB
 * Logs to claudeblox.logs with: action, message, role, details
 */
async function logAction(action, message = "", details = {}, role = "agent") {
  log(`log_action: [${role}] ${action} - ${message}`);

  await dbQuery(
    `INSERT INTO claudeblox.logs (action, message, role, details)
     VALUES ($1, $2, $3, $4)`,
    [action, message, role, JSON.stringify(details)]
  );

  return { success: true, action, message };
}

/**
 * Get recent posts (for context)
 */
async function getRecentPosts(limit = 10) {
  log(`get_recent_posts: fetching last ${limit} posts`);

  const rows = await dbQuery(
    `SELECT id, tweet_id, content, media_urls, posted_at
     FROM public.posts
     WHERE success = true
     ORDER BY posted_at DESC
     LIMIT $1`,
    [limit]
  );

  return rows;
}

// ═══════════════════════════════════════════════════════════════════════════
// MCP SERVER
// ═══════════════════════════════════════════════════════════════════════════

const server = new Server(
  { name: "claude-games-mcp", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// List tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "post_tweet",
        description: "Post text tweet (max 280 chars). Auto-saves to posts table.",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "Tweet text (max 280 chars)"
            },
            idea_id: {
              type: "number",
              description: "ID of the idea used (optional, for tracking)"
            }
          },
          required: ["text"]
        }
      },
      {
        name: "post_tweet_with_media",
        description: "Post tweet with 1-4 images. Accepts URLs (Supabase storage) or local paths. Auto-saves to posts table.",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "Tweet text (max 280 chars)"
            },
            image_paths: {
              oneOf: [
                { type: "string", description: "Single image path" },
                { type: "array", items: { type: "string" }, description: "Array of image paths (max 4)" }
              ],
              description: "Path(s) to image file(s). Can be string or array of strings (max 4 images)"
            },
            idea_id: {
              type: "number",
              description: "ID of the idea used (optional, for tracking)"
            }
          },
          required: ["text", "image_paths"]
        }
      },
      {
        name: "log_action",
        description: "ОБЯЗАТЕЛЬНО вызывай для логирования каждого действия! Формат message: [СТАРТ], [ДЕЙСТВИЕ], [РЕЗУЛЬТАТ], [ОШИБКА]",
        inputSchema: {
          type: "object",
          properties: {
            action: {
              type: "string",
              description: "Action type: start, get_ideas, selected_idea, posting, posted, complete, error, skip"
            },
            message: {
              type: "string",
              description: "Human readable message, e.g.: [СТАРТ] начинаю сессию"
            },
            details: {
              type: "object",
              description: "Additional data (JSON)"
            },
            role: {
              type: "string",
              description: "Role: agent, system, error (default: agent)"
            }
          },
          required: ["action", "message"]
        }
      },
      {
        name: "get_recent_posts",
        description: "Get recent posts (to avoid repetition)",
        inputSchema: {
          type: "object",
          properties: {
            limit: {
              type: "number",
              description: "Number of posts (default: 10)",
              default: 10
            }
          }
        }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;

    switch (name) {
      case "post_tweet":
        result = await postTweet(args.text, args.idea_id || null);
        break;

      case "post_tweet_with_media":
        result = await postTweetWithMedia(args.text, args.image_paths, args.idea_id || null);
        break;

      case "log_action":
        result = await logAction(args.action, args.message || "", args.details || {}, args.role || "agent");
        break;

      case "get_recent_posts":
        result = await getRecentPosts(args?.limit || 10);
        break;

      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    // Auto-log successful tool call (skip log_action to avoid recursion)
    if (name !== "log_action") {
      await logToolCall(name, args, result);
    }

    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }]
    };

  } catch (error) {
    log(`ERROR in ${name}: ${error.message}`);

    // Auto-log failed tool call
    await logToolCall(name, args, null, error.message);

    return {
      content: [{ type: "text", text: `Error: ${error.message}` }],
      isError: true
    };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// START SERVER
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  log("Starting Claude Games MCP server...");

  const transport = new StdioServerTransport();
  await server.connect(transport);

  log("MCP server connected and ready");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
