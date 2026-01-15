# Squarespace Editing with Playwright MCP

This directory previously contained a custom MCP server, but we now use the standard Playwright MCP server instead.

## Using Playwright MCP for Squarespace Editing

### Setup

1. **Install Playwright MCP globally:**
   ```bash
   npm install -g @aethr/playwright-mcp
   ```

2. **Configure in Cursor MCP Settings:**
   
   Add to your Cursor MCP configuration (Settings → Features → Model Context Protocol):
   
   ```json
   {
     "mcpServers": {
       "playwright": {
         "command": "npx",
         "args": ["-y", "@aethr/playwright-mcp"]
       }
     }
   }
   ```

3. **Restart Cursor**

### Usage

Once configured, you can ask the AI assistant to:
- Navigate to Squarespace and login
- Edit pages on your website
- Add or modify content
- Save and publish changes

The Playwright MCP server provides generic browser automation tools that work with any website, including Squarespace.

### Credentials

You'll need to provide your Squarespace login credentials when asked, or the AI can navigate to the login page and you can enter them manually in the browser that opens.
