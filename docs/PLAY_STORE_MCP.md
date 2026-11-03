# Play Store MCP server

`.mcp.json` registers a `play-store` MCP server that uploads builds to the
internal, alpha and beta tracks (production is saved as a draft only). The
file holds variable names only: every machine supplies its own paths and
credentials, so nothing personal is committed.

## Setup (once per machine)

1. Build the server (JDK 17+):

   ```bash
   git clone https://github.com/develop4God/play-store-mcp.git
   cd play-store-mcp && ./gradlew clean build -x test
   ```

2. Create a Play Console service account and download its JSON key. Follow
   the "Setup" section of the play-store-mcp README, then `chmod 600` the key
   (the server refuses to start otherwise).

3. Export the two variables in your shell profile (`~/.bashrc`, `~/.profile`)
   and restart Claude Code / your IDE so it inherits them:

   ```bash
   export PLAY_STORE_MCP_JAR=/path/to/play-store-mcp/build/libs/play-store-mcp-all.jar
   export PLAY_STORE_SERVICE_ACCOUNT_KEY_PATH=/path/to/service-account-key.json
   ```

4. Approve the `play-store` server when Claude Code asks, and check
   `claude mcp list` shows it as connected.

If a variable is missing the server loads with the literal `${VAR}` text and
fails to start; `claude mcp list` shows a warning.

## Rules

- Never commit the key file, its path, or the jar path.
- Every write is a dry run until `confirm=true` is passed.
