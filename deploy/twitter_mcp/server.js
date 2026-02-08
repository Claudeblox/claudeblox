#!/usr/bin/env node

/**
 * ClaudeBlox Twitter MCP Server (Standalone Version)
 *
 * Simple Twitter posting for ClaudeBlox.
 * No database dependency - just posts tweets.
 *
 * Tools:
 * - post_tweet: post text tweet
 * - post_tweet_with_media: post tweet with images
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { TwitterApi } from "twitter-api-v2";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

// Load .env file
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, ".env") });

// ═══════════════════════════════════════════════════════════════════════════
// CONFIG
// ═══════════════════════════════════════════════════════════════════════════

// Twitter client (OAuth 1.0a User Context)
const twitterClient = new TwitterApi({
  appKey: process.env.TWITTER_API_KEY,
  appSecret: process.env.TWITTER_API_SECRET,
  accessToken: process.env.TWITTER_ACCESS_TOKEN,
  accessSecret: process.env.TWITTER_ACCESS_SECRET,
});

// Read-write client
const twitter = twitterClient.readWrite;

// Log file
const LOG_FILE = path.join(__dirname, "tweets.log");

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

function log(msg) {
  const ts = new Date().toISOString();
  const logLine = `[${ts}] ${msg}`;
  console.error(logLine);

  // Also write to file
  try {
    fs.appendFileSync(LOG_FILE, logLine + "\n");
  } catch (e) {
    // Ignore file write errors
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOOL IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Post text tweet
 */
async function postTweet(text) {
  log(`post_tweet: "${text.substring(0, 50)}..."`);

  if (text.length > 280) {
    throw new Error(`Tweet too long: ${text.length} chars (max 280)`);
  }

  const response = await twitter.v2.tweet(text);
  const tweetId = response.data.id;

  log(`post_tweet: success, tweet_id=${tweetId}`);

  return {
    success: true,
    tweet_id: tweetId,
    text: text,
    url: `https://twitter.com/i/status/${tweetId}`,
  };
}

/**
 * Post tweet with images
 * Supports 1-4 images (local file paths)
 */
async function postTweetWithMedia(text, imagePaths) {
  // Normalize to array
  const paths = Array.isArray(imagePaths) ? imagePaths : [imagePaths];

  log(`post_tweet_with_media: "${text.substring(0, 30)}..." + ${paths.length} image(s)`);

  if (text.length > 280) {
    throw new Error(`Tweet too long: ${text.length} chars (max 280)`);
  }

  if (paths.length > 4) {
    throw new Error(`Too many images: ${paths.length} (max 4)`);
  }

  // Upload all media
  const mediaIds = [];

  for (const imagePath of paths) {
    if (!fs.existsSync(imagePath)) {
      throw new Error(`File not found: ${imagePath}`);
    }

    const mediaId = await twitter.v1.uploadMedia(imagePath);
    mediaIds.push(mediaId);
    log(`post_tweet_with_media: uploaded ${imagePath} -> media_id=${mediaId}`);
  }

  // Post tweet with all media
  const response = await twitter.v2.tweet({
    text: text,
    media: { media_ids: mediaIds },
  });

  const tweetId = response.data.id;
  log(`post_tweet_with_media: success, tweet_id=${tweetId}`);

  return {
    success: true,
    tweet_id: tweetId,
    media_ids: mediaIds,
    media_count: paths.length,
    text: text,
    url: `https://twitter.com/i/status/${tweetId}`,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// MCP SERVER
// ═══════════════════════════════════════════════════════════════════════════

const server = new Server(
  { name: "claudeblox-twitter", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// List tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "post_tweet",
        description: "Post a text tweet (max 280 chars)",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "Tweet text (max 280 chars)",
            },
          },
          required: ["text"],
        },
      },
      {
        name: "post_tweet_with_media",
        description: "Post tweet with 1-4 images",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "Tweet text (max 280 chars)",
            },
            image_paths: {
              oneOf: [
                { type: "string", description: "Single image path" },
                {
                  type: "array",
                  items: { type: "string" },
                  description: "Array of image paths (max 4)",
                },
              ],
              description: "Path(s) to image file(s)",
            },
          },
          required: ["text", "image_paths"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;

    switch (name) {
      case "post_tweet":
        result = await postTweet(args.text);
        break;

      case "post_tweet_with_media":
        result = await postTweetWithMedia(args.text, args.image_paths);
        break;

      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  } catch (error) {
    log(`ERROR in ${name}: ${error.message}`);

    return {
      content: [{ type: "text", text: `Error: ${error.message}` }],
      isError: true,
    };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// START SERVER
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  log("Starting ClaudeBlox Twitter MCP server...");

  // Check if credentials are set
  if (!process.env.TWITTER_API_KEY) {
    log("WARNING: TWITTER_API_KEY not set!");
    log("Create a .env file with your Twitter API credentials:");
    log("  TWITTER_API_KEY=...");
    log("  TWITTER_API_SECRET=...");
    log("  TWITTER_ACCESS_TOKEN=...");
    log("  TWITTER_ACCESS_SECRET=...");
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);

  log("MCP server connected and ready");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
