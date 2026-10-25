# PIXMINT BOT (Flutter Client Package)

This package contains the client-side presentation components for the PIXMINT BOT floating assistant within Archi Draft Studio.

## Architecture & Integration Scope

- **Exported Symbols:**
  - `BotUserRole`: Enum for user portal roles (`engineer`, `draughtsman`, `student`, `admin`).
  - `PixmintBotLauncher`: Floating animated mascot launcher button mounted in `ResponsiveScaffold`.
  - `PixmintChatSheet`: Draggable bottom sheet with mascot badge, role descriptor, and chat input field.
  - `pixmintUseRemoteProvider`, `pixmintApiBaseUrlProvider`, `pixmintAuthTokenProvider`: Riverpod state providers for configuring the assistant service endpoint and user authentication tokens.

## Current Implementation Status & Limitations

> [!NOTE]
> **Presentational Component Only:**
> The current chat sheet implementation is presentational and provides the visual UI structure and theme compliance (high-contrast input field with emerald focus borders).
> It **does not** yet provide complete bidirectional AI backend streaming/RPC communication with the companion AI service listening on `http://127.0.0.1:8788`.
> Full conversational request/response messaging and prompt dispatch will be integrated in a subsequent phase when the upstream AI streaming protocol is finalized.
