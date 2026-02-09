#!/usr/bin/env node

/**
 * Twitter MCP Server - SIMPLE VERSION (no database)
 *
 * Tools:
 * - post_tweet: post text tweet
 * - post_tweet_with_media: tweet with images
 *
 * Required env vars:
 * - TWITTER_API_KEY
 * - TWITTER_API_SECRET
 * - TWITTER_ACCESS_TOKEN
 * - TWITTER_ACCESS_SECRET
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
import https from "https";
import http from "http";

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

const twitter = twitterClient.readWrite;

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

function log(msg) {
  const ts = new Date().toISOString();
  console.error(`[${ts}] ${msg}`);
}

/**
 * Download file from URL to temp path
 */
async function downloadFile(url) {
  return new Promise((resolve, reject) => {
    log(`Downloading: ${url}`);

    const protocol = url.startsWith('https') ? https : http;
    const ext = path.extname(new URL(url).pathname) || '.png';
    const tempPath = `${process.env.TEMP || '/tmp'}/media_${Date.now()}${ext}`;

    const file = fs.createWriteStream(tempPath);

    protocol.get(url, (response) => {
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

function isUrl(str) {
  return str.startsWith('http://') || str.startsWith('https://');
}

// ═══════════════════════════════════════════════════════════════════════════
// TOOL IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════════════════════════

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
    url: `https://twitter.com/i/status/${tweetId}`
  };
}

async function postTweetWithMedia(text, imageSources) {
  const sources = Array.isArray(imageSources) ? imageSources : [imageSources];

  log(`post_tweet_with_media: "${text.substring(0, 30)}..." + ${sources.length} image(s)`);

  if (text.length > 280) {
    throw new Error(`Tweet too long: ${text.length} chars (max 280)`);
  }

  if (sources.length > 4) {
    throw new Error(`Too many images: ${sources.length} (max 4)`);
  }

  const mediaIds = [];
  const tempFiles = [];

  try {
    for (const source of sources) {
      let localPath = source;

      if (isUrl(source)) {
        localPath = await downloadFile(source);
        tempFiles.push(localPath);
      } else if (!fs.existsSync(source)) {
        throw new Error(`File not found: ${source}`);
      }

      const mediaId = await twitter.v1.uploadMedia(localPath);
      mediaIds.push(mediaId);
      log(`Uploaded ${source} -> media_id=${mediaId}`);
    }

    const response = await twitter.v2.tweet({
      text: text,
      media: { media_ids: mediaIds }
    });

    const tweetId = response.data.id;
    log(`post_tweet_with_media: success, tweet_id=${tweetId}`);

    return {
      success: true,
      tweet_id: tweetId,
      media_ids: mediaIds,
      media_count: sources.length,
      text: text,
      url: `https://twitter.com/i/status/${tweetId}`
    };
  } finally {
    for (const tempFile of tempFiles) {
      if (fs.existsSync(tempFile)) {
        fs.unlinkSync(tempFile);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MCP SERVER
// ═══════════════════════════════════════════════════════════════════════════

const server = new Server(
  { name: "twitter-mcp-simple", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "post_tweet",
        description: "Post text tweet (max 280 chars)",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "Tweet text (max 280 chars)"
            }
          },
          required: ["text"]
        }
      },
      {
        name: "post_tweet_with_media",
        description: "Post tweet with 1-4 images. Accepts local file paths.",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "Tweet text (max 280 chars)"
            },
            image_paths: {
              oneOf: [
                { type: "string" },
                { type: "array", items: { type: "string" } }
              ],
              description: "Path(s) to image file(s)"
            }
          },
          required: ["text", "image_paths"]
        }
      }
    ]
  };
});

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
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }]
    };

  } catch (error) {
    log(`ERROR in ${name}: ${error.message}`);
    return {
      content: [{ type: "text", text: `Error: ${error.message}` }],
      isError: true
    };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// START
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  log("Starting Twitter MCP (simple) server...");

  const transport = new StdioServerTransport();
  await server.connect(transport);

  log("Twitter MCP connected and ready");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
