// Widgy Widget Generation Edge Function
// Proxies requests to Claude API with SSE streaming
// API key stays server-side — never exposed to the client

import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const CLAUDE_MODEL = "claude-sonnet-4-20250514";
const MAX_OUTPUT_TOKENS = 2000;

interface GenerationRequest {
  prompt: string;
  conversation_history: Array<{ role: string; content: string }>;
  existing_config?: object;
  family: string;
  previous_error?: string;
}

Deno.serve(async (req: Request) => {
  // CORS headers
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    if (!ANTHROPIC_API_KEY) {
      throw new Error("ANTHROPIC_API_KEY not configured");
    }

    const body: GenerationRequest = await req.json();

    // Build messages array for Claude
    const messages = buildMessages(body);

    // Call Claude API with streaming
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: MAX_OUTPUT_TOKENS,
        stream: true,
        system: buildSystemPrompt(body.family),
        messages,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Claude API error: ${response.status} - ${error}`);
    }

    // Stream SSE response to client
    const encoder = new TextEncoder();
    const stream = new ReadableStream({
      async start(controller) {
        const reader = response.body!.getReader();
        const decoder = new TextDecoder();
        let buffer = "";

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            buffer += decoder.decode(value, { stream: true });
            const lines = buffer.split("\n");
            buffer = lines.pop() || "";

            for (const line of lines) {
              if (line.startsWith("data: ")) {
                const data = line.slice(6);
                if (data === "[DONE]") {
                  controller.enqueue(encoder.encode("data: [DONE]\n\n"));
                  continue;
                }

                try {
                  const parsed = JSON.parse(data);

                  // Extract text content from Claude's streaming format
                  if (parsed.type === "content_block_delta") {
                    const text = parsed.delta?.text || "";
                    if (text) {
                      const chunk = JSON.stringify({ content: text });
                      controller.enqueue(
                        encoder.encode(`data: ${chunk}\n\n`)
                      );
                    }
                  }

                  if (parsed.type === "message_stop") {
                    controller.enqueue(encoder.encode("data: [DONE]\n\n"));
                  }
                } catch {
                  // Skip unparseable chunks
                }
              }
            }
          }
        } finally {
          reader.releaseLock();
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});

function buildMessages(
  body: GenerationRequest
): Array<{ role: string; content: string }> {
  const messages: Array<{ role: string; content: string }> = [];

  // Add conversation history
  for (const msg of body.conversation_history || []) {
    if (msg.role === "user" || msg.role === "assistant") {
      messages.push({ role: msg.role, content: msg.content });
    }
  }

  // Build the current prompt
  let currentPrompt = body.prompt;

  if (body.existing_config) {
    currentPrompt += `\n\nCurrent widget config to modify:\n${JSON.stringify(body.existing_config, null, 2)}`;
  }

  if (body.previous_error) {
    currentPrompt += `\n\nThe previous attempt failed with: ${body.previous_error}\nPlease fix the issue and try again.`;
  }

  messages.push({ role: "user", content: currentPrompt });

  return messages;
}

function buildSystemPrompt(family: string): string {
  return `You are a friendly widget design assistant for Widgy, an iOS app that creates custom homescreen widgets.
Your job is to help users create and refine widgets through conversation.

RESPONSE RULES:
- When the user wants to CREATE or MODIFY a widget: output ONLY a raw JSON object (no text before/after, no code blocks).
- When the user asks a question, wants clarification, or says something unrelated to generating a widget: respond with plain text conversation. Be helpful and guide them toward describing a widget.
- When iterating on an existing widget: apply the user's requested changes to the current config and output the updated JSON.
- Keep conversation natural and helpful. If unsure what the user wants, ASK before generating.

The widget family is: ${family}
Widget sizes: systemSmall=170x170pt, systemMedium=364x170pt, systemLarge=364x382pt.

## Node Types and EXACT Property Names

Each node has "type", "properties", and optionally "children" (for containers).

### Container nodes (have "children" array):
- VStack: {"alignment":"center","spacing":8,"children":[...]}
- HStack: {"alignment":"center","spacing":8,"children":[...]}
- ZStack: {"alignment":"center","children":[...]}

### Leaf nodes:
- Text: {"content":"Hello","font":{"style":"headline","weight":"bold","design":"rounded"},"color":"#FFFFFF","alignment":"center"}
  IMPORTANT: Use "content" (not "text") for the text string.
- SFSymbol: {"system_name":"sun.max.fill","color":"#FFD700","font_size":40,"font_weight":"bold","rendering_mode":"multicolor"}
  IMPORTANT: Use "system_name" (not "symbol" or "name") for the SF Symbol identifier.
- Gauge: {"value":0.75,"min_value":0,"max_value":1,"gauge_style":"circular","tint":"#00FF00","label":"Battery"}
  IMPORTANT: "value" must be a number (not a string). Use "gauge_style" (not "style"). Use "tint" (not "color").
- Spacer: {} (empty properties OK)
- Divider: {"color":"#CCCCCC","thickness":1}
- ContainerRelativeShape: {"fill":"#1A1A1A","glass_effect":true}
  Use as background in a ZStack. Use "fill" for the fill color.

### Wrapper nodes (have single "child"):
- Frame: {"child":{...},"width":100,"height":100}
- Padding: {"child":{...},"edges":"all","value":16}

## Color Formats
- Hex string: "#FF0000"
- System color: {"type":"system","value":"blue"}
  Values: red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, white, black, gray, clear
- Semantic color: {"type":"semantic","value":"primary"}
  Values: primary, secondary, label, secondaryLabel, tertiaryLabel, systemBackground, secondarySystemBackground, separator, accent

## Data Bindings (use in Text content)
- Time: {{date_time.time}}, {{date_time.date}}, {{date_time.day}}, {{date_time.hour}}, {{date_time.minute}}
- Weather: {{weather.temperature}}, {{weather.condition}}, {{weather.high}}, {{weather.low}}
- Battery: {{battery.level}}, {{battery.state}}
- Calendar: {{calendar.next.title}}, {{calendar.next.time}}
- Health: {{health.steps}}, {{health.calories}}
- Location: {{location.city}}

## Required Top-Level Fields
- id: valid UUID string
- schema_version: "1.0"
- name: descriptive name
- family: "${family}"
- root: the node tree

## Example (systemSmall clock):
{
  "id":"550e8400-e29b-41d4-a716-446655440000",
  "schema_version":"1.0",
  "name":"Simple Clock",
  "family":"systemSmall",
  "root":{
    "type":"ZStack",
    "properties":{},
    "children":[
      {"type":"ContainerRelativeShape","properties":{"fill":"#1A2030","glass_effect":true}},
      {"type":"VStack","properties":{"spacing":4},"children":[
        {"type":"Text","properties":{"content":"{{date_time.time}}","font":{"style":"largeTitle","weight":"bold","design":"monospaced"},"color":"#FFFFFF"}},
        {"type":"Text","properties":{"content":"{{date_time.date}}","font":{"style":"caption","weight":"medium"},"color":"#AAAAAA"}}
      ]}
    ]
  }
}

Keep layouts simple (max 3-4 nesting levels).`;
}
