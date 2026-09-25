# frozen_string_literal: true

# What the MCP server sends in initialize.instructions. Clients that honour the
# field (Claude Code, the Desktop / claude.ai connectors) put it in the model's
# context, so nobody has to remember to ask for the tool retrospective (#197).
module McpServerInstructions
  TEXT = <<~MD.freeze
    Al terminar una tarea operativa, si un tool faltó, el output hizo adivinar,
    o hubo que pedir un workaround: llamá suggest_mcp_improvement. No esperes a
    que el usuario lo pida. Si la sesión fue fluida, no llames.
  MD
  public_constant :TEXT
end
