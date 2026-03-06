---
name: mcp-server-development
description: "Building Model Context Protocol (MCP) servers to connect AI assistants to external tools, databases, and services. Use when creating integrations between Claude and external systems, exposing tools to AI, or building structured AI interfaces. Triggers include MCP server creation, tool definitions, resource exposure, AI integrations, or discussions of connecting Claude to databases/APIs/AutoCAD."
---

# MCP Server Development

Build MCP servers to connect Claude to your systems.

## MCP Concepts

```
┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
│   AI Client     │◀────────▶│   MCP Server    │◀────────▶│  Your System    │
│   (Claude)      │  JSON-RPC │  (you build)    │          │  (Database,     │
│                 │           │                 │          │   AutoCAD, etc) │
└─────────────────┘          └─────────────────┘          └─────────────────┘
```

| Concept | Purpose | Example |
|---------|---------|---------|
| **Tools** | Functions AI can call | `CreateFactoryOrder()`, `InsertBadge()` |
| **Resources** | Data AI can read | Job list, client database, drawing metadata |
| **Prompts** | Pre-built workflows | "Create FO from description" |

## Python MCP Server (FastMCP)

```python
# server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("cambium-api")

@mcp.tool()
async def get_job_status(job_number: str) -> dict:
    """Get current status of a job by job number."""
    # Query your database
    job = await db.jobs.find_one({"number": job_number})
    return {
        "number": job["number"],
        "status": job["status"],
        "client": job["client"]
    }

@mcp.tool()
async def create_factory_order(
    job_number: str,
    description: str,
    due_date: str
) -> dict:
    """Create a new factory order for a job."""
    fo = await db.factory_orders.insert_one({
        "job_number": job_number,
        "description": description,
        "due_date": due_date,
        "status": "pending"
    })
    return {"id": str(fo.inserted_id), "status": "created"}

@mcp.resource("jobs://list")
async def list_jobs() -> str:
    """List all active jobs."""
    jobs = await db.jobs.find({"status": "active"}).to_list(100)
    return "\n".join(f"{j['number']}: {j['name']}" for j in jobs)

if __name__ == "__main__":
    mcp.run()
```

## TypeScript MCP Server

```typescript
// server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "cambium-api",
  version: "1.0.0"
}, {
  capabilities: {
    tools: {},
    resources: {}
  }
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{
    name: "get_job_status",
    description: "Get current status of a job",
    inputSchema: {
      type: "object",
      properties: {
        job_number: { type: "string", description: "Job number" }
      },
      required: ["job_number"]
    }
  }]
}));

server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;
  
  if (name === "get_job_status") {
    const job = await getJob(args.job_number);
    return { content: [{ type: "text", text: JSON.stringify(job) }] };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

## C# MCP Server Pattern

```csharp
// For ASP.NET Core integration
[McpTool("create_badge")]
public async Task<BadgeResult> CreateBadge(
    string jobNumber,
    string category,
    string prefix,
    int suffix)
{
    // Validate through Cage
    var validation = await _cage.Validate(jobNumber, category);
    if (!validation.IsValid)
        return new BadgeResult { Error = validation.Message };
    
    // Create badge
    var badge = await _badgeManager.Create(category, prefix, suffix);
    
    return new BadgeResult { 
        Code = badge.Code,
        Shape = badge.Shape.ToString()
    };
}
```

## Claude Code Configuration

Add to `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "cambium": {
      "command": "python",
      "args": ["/path/to/server.py"],
      "env": {
        "DATABASE_URL": "postgresql://..."
      }
    },
    "autocad": {
      "command": "dotnet",
      "args": ["run", "--project", "/path/to/AutoCADMcp"]
    }
  }
}
```

## Tool Design Principles

1. **Clear descriptions**: AI needs to understand when to use each tool
2. **Typed parameters**: Use proper types, not just strings
3. **Error handling**: Return structured errors AI can understand
4. **Idempotency**: Tools should be safe to retry
5. **Permissions**: Validate user/context before operations

## Luxify Integration Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    MCP SERVER (Graft Layer)                 │
│                                                             │
│   Tools:                      Resources:                    │
│   • CreateFactoryOrder()      • jobs://list                │
│   • UpdateBadge()             • badges://catalog           │
│   • GetJobStatus()            • drawings://metadata        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
              ↓                           ↓
       ┌─────────────┐            ┌─────────────┐
       │ Job Ramus   │            │ Badge Ramus │
       └─────────────┘            └─────────────┘
```

MCP servers act as **grafts** — they expose rami capabilities to AI without letting AI access rami directly.

## Debugging

```bash
# Run with debug flag
claude --mcp-debug

# Test server directly
npx @anthropic-ai/mcp-cli test /path/to/server.py
```

## Common MCP Servers

| Server | Purpose |
|--------|---------|
| filesystem | Read/write local files |
| postgres | Direct database queries |
| brave-search | Web search |
| puppeteer | Browser automation |
| Custom | Your business logic |
