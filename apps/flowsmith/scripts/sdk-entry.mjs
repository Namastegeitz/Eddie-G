// Re-exports the official Anthropic SDK so esbuild can bundle it into vendor/anthropic-sdk.mjs.
// The app loads that file only in "API key" mode (never inside the Claude artifact).
export { default } from "@anthropic-ai/sdk";
export * from "@anthropic-ai/sdk";
