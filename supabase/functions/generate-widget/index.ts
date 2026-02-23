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
  return `You are a widget design assistant for Widgy, an iOS app that creates custom homescreen widgets.
Your job is to generate valid JSON widget configurations based on user descriptions.

You MUST output a single valid JSON object matching the WidgetConfig schema.
Do NOT include any text before or after the JSON. Do NOT wrap in code blocks.
Output ONLY the raw JSON object.

The widget family is: ${family}

Node types: VStack, HStack, ZStack, Text, SFSymbol, Image, Spacer, Divider, Gauge, Frame, Padding, ContainerRelativeShape.
Each node has "type" and "properties". Container nodes have "children" array. Wrapper nodes have "child".

Color formats: "#hex", {"type":"system","value":"blue"}, {"type":"semantic","value":"primary"}
Font: {"style":"headline","weight":"bold","design":"rounded"}
Data bindings: {{date_time.time}}, {{weather.temperature}}, {{battery.level}}, {{calendar.next.title}}

Required fields: id (UUID), schema_version ("1.0"), name, family, root (node tree).
Keep layouts simple (max 3-4 nesting levels). Use glass_effect:true for Liquid Glass look.
For systemSmall: 170x170pt, keep minimal. systemMedium: 364x170pt. systemLarge: 364x382pt.`;
}
