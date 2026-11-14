<div align="center">

# BurpAgent

### Agentic AI Security Testing for Burp Suite

An open-source Burp Suite extension that brings agentic AI to your pentesting workflow — like Burp AT. The AI agent investigates Scanner findings, validates them by sending proof-of-concept requests through Burp's HTTP engine, can send requests to Repeater or Intruder, and logs every action as reproducible evidence.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://openjdk.org/)
[![Burp Suite](https://img.shields.io/badge/Burp%20Suite-Pro%20%7C%20Community-red.svg)](https://portswigger.net/burp)
[![Montoya API](https://img.shields.io/badge/Montoya%20API-2025.5-blue.svg)](https://portswigger.net/burp/documentation/api)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Supported LLM Providers](#supported-llm-providers)
- [How It Works](#how-it-works)
- [Project Structure](#project-structure)
- [Building from Source](#building-from-source)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)

---

## Overview

BurpAgent is a Burp Suite extension that adds an AI agent to your pentesting toolkit. Inspired by PortSwigger's Burp AT, it lets you delegate vulnerability investigation to an AI agent that works through Burp's own tools — sending requests, checking proxy history, sending to Repeater/Intruder — while you stay in control.

**The agent proposes actions, Burp enforces limits, the human decides.**

Key principles:
- **Boundaries enforced in code** — the LLM can only do what the tool layer allows. Approval gates block unapproved actions regardless of what the model suggests.
- **Reproducible evidence** — every HTTP request/response the agent sends is logged. You don't have to trust the AI's summary; you can verify the raw traffic.
- **Bring your own LLM** — connect to any OpenAI-compatible or Anthropic-compatible API. No vendor lock-in.

---

## Features

- **Agentic investigation loop** — the AI plans, calls tools, reads results, and iterates until it reaches a verdict (confirmed / false positive / needs review)
- **Multi-provider LLM support** — works with Command Code, OpenAI/Codex, Google Gemini/Antigravity, Anthropic, OpenRouter, Ollama, vLLM, LM Studio, or any custom endpoint
- **6 Burp-integrated tools** the agent can call:
  | Tool | Action |
  |---|---|
  | `send_request` | Send an HTTP request through Burp's engine and return the full response |
  | `send_to_repeater` | Send a request to Burp's Repeater tab for manual follow-up |
  | `send_to_intruder` | Send a request to Burp's Intruder tab for payload testing |
  | `get_scanner_issues` | List all scanner findings in the current project |
  | `get_proxy_history` | List proxy history entries to understand normal traffic patterns |
  | `mark_verdict` | Record the final assessment (confirmed / false_positive / needs_review) |
- **Approval gates** — control autonomy per action type (Auto / Approve / Off)
- **Evidence logging** — every request/response the agent sends is captured for reproducible proof
- **Context menu integration** — right-click any request → "Send to BurpAgent"
- **Settings persistence** — your provider config and API key are saved across Burp restarts
- **Batch investigation** — investigate all scanner findings in one click

---

## Requirements

- **Burp Suite** Professional (for Scanner integration) or Community (manual investigation via context menu)
- **Java 17+** (Burp Suite ships with a bundled JRE; you only need a JDK if building from source)
- **An LLM API key** for your chosen provider (see [Supported LLM Providers](#supported-llm-providers))

---

## Installation

### Option A: Pre-built jar (recommended)

1. Download `burpagent.jar` from the [Releases](../../releases) page
2. Open Burp Suite
3. Go to **Extensions** → **Installed**
4. Click **Add**
5. Set Extension type to **Java**
6. Select the downloaded `burpagent.jar`
7. Click **Next** — the extension loads and a new **BurpAgent** tab appears

### Option B: Build from source (no Gradle required)

```bat
git clone https://github.com/YOUR_USERNAME/burpagent.git
cd burpagent
build.bat
```

The `build.bat` script automatically:
1. Downloads the Montoya API (`montoya-api-2025.5.jar`) and Gson (`gson-2.11.0.jar`) from Maven Central
2. Compiles all Java sources with `javac`
3. Packages everything into `build/burpagent.jar`

Then load `build/burpagent.jar` via Burp → Extensions → Add (same as Option A).

> **Prerequisite:** You need a JDK (17+) with `javac` on your PATH. Verify with `javac -version`.

### Option C: Build with Gradle

```bat
git clone https://github.com/YOUR_USERNAME/burpagent.git
cd burpagent
.\gradlew jar
```

Output: `build/libs/burpagent.jar`

> The Gradle wrapper will download Gradle automatically on first run — no separate Gradle installation needed.

---

## Configuration

After loading the extension, configure your LLM provider:

1. Click the **BurpAgent** tab in Burp Suite
2. Go to the **Settings** sub-tab

### Settings fields

| Field | Description |
|---|---|
| **Provider** | Select a preset provider from the dropdown, or choose "Custom" |
| **Custom endpoint** | Enabled when "Custom" is selected — enter any OpenAI-compatible or Anthropic-compatible API root URL |
| **API Key** | Your API key for the chosen provider (stored securely in Burp's preferences) |
| **Model** | The model ID to use (e.g. `claude-sonnet-4-6`, `gpt-5.3-codex`, `gemini-3.5-flash`) |
| **Zero data retention** | Enforce ZDR (Command Code only) — sends the `x-cmd-zdr: 1` header |
| **Autonomy: send_request** | Approval level for HTTP requests the agent sends |
| **Autonomy: send_to_repeater** | Approval level for sending requests to Repeater |
| **Autonomy: send_to_intruder** | Approval level for sending requests to Intruder |

### Autonomy levels

| Level | Behavior |
|---|---|
| **AUTO** | Execute immediately without asking |
| **APPROVE** | Show a confirmation dialog before executing |
| **OFF** | Refuse the action entirely — the agent cannot perform it |

3. Click **Test Connection** to verify your provider settings work
4. Click **Save Settings** to persist your configuration across Burp restarts

---

## Usage Guide

### Investigating Scanner Findings

1. Run a Burp Scanner scan on your target (requires Burp Pro)
2. Go to the **BurpAgent** tab → **Findings** sub-tab
3. Click **Refresh Issues** — all scanner findings appear in the table
4. Select a finding you want the AI to investigate
5. Click **Investigate**

The agent will:
- Analyze the finding details (issue name, severity, confidence, request/response)
- Query proxy history to understand the application's normal behavior
- Send proof-of-concept requests to validate or disprove the vulnerability
- Optionally send interesting requests to Repeater or Intruder for your follow-up
- Record a final verdict: **Confirmed**, **False Positive**, or **Needs Review**

6. Watch the **Investigation Log** sub-tab fill in real-time as the agent works
7. Check the **Evidence** sub-tab for captured request/response pairs

### Investigating All Findings at Once

1. Go to **Findings** → click **Refresh Issues**
2. Click **Investigate All** — the agent investigates each finding sequentially
3. Monitor progress in the findings table (status column updates live)

### Investigating Any Request Manually

1. Right-click any request in Burp Suite (Proxy history, Repeater, Target, etc.)
2. Select **Send to BurpAgent**
3. The agent starts investigating that request for security issues

### Stopping an Investigation

Click **Stop** at any time to halt the current investigation. The agent finishes its current tool call and stops.

### Reviewing Evidence

1. Go to the **Evidence** sub-tab
2. Click **Refresh** to see all captured request/response pairs
3. Each entry shows the tool that generated it and a preview of the request and response
4. Click **Clear** to remove evidence from a previous investigation

---

## Supported LLM Providers

BurpAgent works with any provider that speaks the OpenAI Chat Completions or Anthropic Messages wire format.

### Quick reference

| Provider | Endpoint | Wire Format | Where to get an API key |
|---|---|---|---|
| **Command Code** | `api.commandcode.ai/provider/v1` | OpenAI or Anthropic | [commandcode.ai/settings/keys](https://commandcode.ai/settings/keys) |
| **OpenAI / Codex** | `api.openai.com/v1` | OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| **Google Gemini / Antigravity** | `generativelanguage.googleapis.com/v1beta/openai` | OpenAI | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |
| **Anthropic (Claude)** | `api.anthropic.com/v1` | Anthropic | [console.anthropic.com](https://console.anthropic.com/) |
| **OpenRouter** | `openrouter.ai/api/v1` | OpenAI | [openrouter.ai/keys](https://openrouter.ai/keys) |
| **Local (Ollama)** | `localhost:11434/v1` | OpenAI | No key needed |

### Popular model IDs

| Provider | Model ID | Notes |
|---|---|---|
| Command Code | `claude-sonnet-4-6` | Claude via Command Code API |
| Command Code | `gpt-5.3-codex` | GPT Codex via Command Code API |
| Command Code | `gemini-3.5-flash` | Gemini via Command Code API |
| OpenAI | `gpt-5.3-codex` | Direct OpenAI |
| Anthropic | `claude-sonnet-4-6` | Direct Anthropic |
| Google | `gemini-3.5-flash` | Direct Google |
| OpenRouter | `anthropic/claude-sonnet-4-6` | Via OpenRouter |
| Ollama | `llama3.3:70b` | Local, free |

### Using a custom provider

1. Select **Custom** from the Provider dropdown
2. Enter the endpoint root URL (e.g. `https://my-gateway.example.com/v1`)
3. The wire format is auto-detected from the URL (Anthropic if it contains `anthropic.com` or `/messages`, otherwise OpenAI)
4. Enter your API key and model ID

---

## How It Works

```
                    ┌─────────────────────────────────┐
                    │         Scanner Finding          │
                    │  (issue name, severity, req/resp)│
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────────┐
                    │          Agent Loop               │
                    │  ┌─────────────────────────┐     │
  LLM API ◄─────────┤  │  System prompt + tools  │     │
  (tool-calling)    │  │  + finding context      │     │
  ─────────────────►│  └───────────┬─────────────┘     │
                    │              │                    │
                    │   ┌──────────▼──────────┐        │
                    │   │  Approval Gate       │        │
                    │   │  (Auto/Approve/Off)  │        │
                    │   └──────────┬──────────┘        │
                    └──────────────┼────────────────────┘
                                   │ approved
                                   ▼
                    ┌──────────────────────────────────┐
                    │       Burp Tool Layer             │
                    │  send_request  │ send_to_repeater│
                    │  send_to_intruder                │
                    │  get_scanner_issues              │
                    │  get_proxy_history │ mark_verdict │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │       Evidence Logger            │
                    │  (all req/resp captured)         │
                    └──────────────────────────────────┘
```

**The loop:**
1. The finding details + context are sent to the LLM with a set of tool definitions
2. The LLM decides which tools to call (e.g., "get proxy history to understand the app, then send a test request")
3. Each tool call passes through the approval gate — if set to APPROVE, a dialog asks for your confirmation
4. The tool executes via the Montoya API (Burp's extension API) and the result feeds back into the conversation
5. The LLM iterates: analyze → test → verify → repeat
6. When done, the LLM calls `mark_verdict` with its assessment, or the turn limit is reached

**Why this is safe:**
- The LLM cannot bypass the approval gate — it's enforced in Java code
- Every HTTP action is logged as evidence — you can verify what the agent actually did
- The agent only has access to the 6 defined tools — it cannot execute arbitrary code
- The turn limit (default: 25) prevents infinite loops

---

## Project Structure

```
burpagent/
├── build.bat                          # Build script (no Gradle needed)
├── build.gradle.kts                   # Gradle build config
├── settings.gradle.kts                # Gradle project settings
├── README.md
├── LICENSE
└── src/main/java/io/github/burpagent/
    ├── BurpAgentExtension.java         # Extension entry point (implements BurpExtension)
    ├── agent/
    │   ├── AgentTool.java              # Tool interface
    │   ├── AgentLoop.java              # The reasoning loop (LLM + tool-calling)
    │   ├── ApprovalGate.java           # Autonomy enforcement (Auto/Approve/Off)
    │   └── BurpTools.java              # 6 Burp tool implementations
    ├── evidence/
    │   └── EvidenceLogger.java         # Request/response evidence capture
    ├── llm/
    │   ├── LlmProvider.java            # Provider interface + data types
    │   ├── OpenAIWireProvider.java     # OpenAI Chat Completions wire format
    │   ├── AnthropicWireProvider.java  # Anthropic Messages wire format
    │   ├── ProviderConfig.java         # Provider configuration POJO
    │   └── ProviderPresets.java        # Built-in provider presets
    └── ui/
        └── AgentPanel.java             # Swing UI (Settings, Findings, Log, Evidence)
```

---

## Building from Source

### Prerequisites

- JDK 17 or later (verify with `javac -version`)
- Internet access (to download Montoya API and Gson from Maven Central)

### Build

**Using the build script (no Gradle):**
```bat
build.bat
```
Output: `build/burpagent.jar`

**Using Gradle:**
```bat
.\gradlew jar
```
Output: `build/libs/burpagent.jar`

### Dependencies

| Dependency | Version | Purpose | Scope |
|---|---|---|---|
| Montoya API | 2025.5 | Burp Suite extension API | compileOnly (provided by Burp at runtime) |
| Gson | 2.11.0 | JSON parsing for LLM API calls | implementation (bundled in the jar) |

---

## Troubleshooting

### The extension doesn't load

- Ensure you're selecting the `.jar` file (not the source files)
- Check Burp's **Extensions** → **Installed** → **Errors** tab for error messages
- Verify your Burp Suite version supports the Montoya API (Burp 2023.5+)

### "Connection failed" when testing the provider

- Double-check your **API key** — it must be valid for the selected provider
- Verify the **model ID** is correct for your provider (see [Popular model IDs](#popular-model-ids))
- For Command Code: ensure your plan includes API access (GOAT plan or higher, or the Provider plan)
- Check your network — BurpAgent needs to reach the LLM provider's endpoint
- Check the **Investigation Log** tab for detailed error messages

### No scanner issues appear in the Findings tab

- Scanner issues require **Burp Suite Professional** (Community edition has no scanner)
- Issues are collected via an audit issue handler — they appear after the extension is loaded and the scanner finds them
- Run a new scan after loading the extension, then click **Refresh Issues**

### The agent sends requests I didn't approve

- Check your **Autonomy** settings — if `send_request` is set to **AUTO**, the agent sends requests without asking
- Set it to **APPROVE** to require confirmation before each request
- Set it to **OFF** to block the agent from sending requests entirely

### The agent reaches the turn limit without a verdict

- The default turn limit is 25. Some complex findings may need more.
- Try a more capable model (e.g., Claude Sonnet instead of Haiku)
- Check the investigation log for where the agent got stuck

---

## FAQ

**Is this the same as Burp AT?**

No. BurpAgent is an independent, open-source project inspired by Burp AT's approach. It uses the same core principles (agentic AI, approval gates, evidence logging, works through Burp's tools) but is community-maintained and lets you bring your own LLM provider.

**Does my data get sent to the LLM provider?**

Yes. The finding details (request/response, issue details) are sent to your chosen LLM provider's API for analysis. This is necessary for the agent to reason about the findings. Use the **Zero data retention** option with Command Code to prevent data storage. For sensitive engagements, use a local model (Ollama) to keep all data on your machine.

**Can I use this with Burp Community?**

Yes, with limitations. Burp Community has no Scanner, so the Findings tab won't populate. However, you can still use the right-click → "Send to BurpAgent" context menu to investigate individual requests.

**Which LLM model should I use?**

Claude Sonnet 4.6 is recommended for security analysis — it has strong reasoning and tool-calling capabilities. GPT-5.3 Codex and Gemini 3.5 Flash also work well. For budget-conscious use, DeepSeek V4 Flash via Command Code or OpenRouter offers good value.

**Can the agent execute arbitrary code?**

No. The agent can only call the 6 defined tools. It cannot run shell commands, modify files, or access your system outside of Burp's HTTP engine.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
