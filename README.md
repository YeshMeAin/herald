# Herald

Herald adds a natural language agent to any Rails application, accessible via Telegram. Talk to your app in plain English — query data, update records, trigger business logic — without building a separate interface.

## How it works

```
Telegram message → Webhook → LLM → Action Dispatcher → Response → Telegram
```

1. A Telegram message hits the mounted webhook endpoint
2. Herald validates the sender against a single whitelisted user ID
3. The message is sent to an LLM (you provide your own API key) with an auto-generated instruction file as the system prompt
4. The LLM returns a structured action + params
5. Herald dispatches the action directly inside the Rails process — no HTTP, pure Ruby
6. The result is sent back as a plain text Telegram message

## Installation

Add to your Gemfile:

```ruby
gem "herald-agent"
```

Then run:

```
bundle install
```

## Setup

### 1. Configure Herald

Create an initializer:

```ruby
# config/initializers/herald.rb
Herald.configure do |config|
  config.telegram_bot_token = ENV["HERALD_TELEGRAM_TOKEN"]
  config.telegram_user_id   = ENV["HERALD_TELEGRAM_USER_ID"]
  config.llm_api_key        = ENV["HERALD_LLM_API_KEY"]
  config.llm_provider       = :anthropic  # or :openai
end
```

### 2. Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Herald::Engine => "/herald"
end
```

This adds a single endpoint: `POST /herald/webhook`.

### 3. Register your Telegram webhook

```
HERALD_WEBHOOK_URL=https://yourapp.com/herald/webhook rake herald:setup_webhook
```

## Usage

### Annotating models

Include `Herald::Agentable` and whitelist the actions you want to expose. **Nothing is exposed by default** — every action must appear in `only:`.

```ruby
class InventoryItem < ApplicationRecord
  include Herald::Agentable

  agent_description "Tracks stock levels for warehouse items"
  agent_actions only: [:index, :show, :create, :update]

  agent_action_description :show, "Look up a single item by ID"
  agent_action_description :update, "Change an item's name or quantity"
end
```

For ActiveRecord models, these reserved action names map to standard operations:

| Action    | What it does                          |
|-----------|---------------------------------------|
| `index`   | `Model.where(filters)`                |
| `show`    | `Model.find(id)`                      |
| `create`  | `Model.create!(params)`              |
| `update`  | `Model.find(id).update!(params)`     |
| `destroy` | `Model.find(id).destroy!`            |

Parameters are introspected automatically from your AR column types (names, types, nullability, defaults).

### Annotating service classes

Any Ruby class can be an agent target. Method parameters are introspected from the method signature:

```ruby
class ReportService
  include Herald::Agentable

  agent_description "Generates business reports"
  agent_actions only: [:generate_monthly, :health_check]

  agent_action_description :generate_monthly, "Creates the monthly revenue report"
  agent_action_description :health_check, "Returns system status"

  def generate_monthly(month:, year:)
    # your logic here
    "Report for #{month}/#{year} generated."
  end

  def health_check
    "All systems operational."
  end
end
```

### Generating the instruction file

```
rake herald:generate_instructions
```

This reads every class that includes `Herald::Agentable`, introspects their allowed actions, AR column types, method signatures, and all your `agent_description` / `agent_action_description` annotations, then writes `config/herald_instructions.md`.

This file is the LLM's system prompt — its complete source of truth about what the app can do. Run the rake task again any time you change your annotations or models. It always regenerates from scratch.

**You should not edit this file by hand.** All context belongs in annotations on your models and services.

## Architecture

### What the gem owns

- **Telegram webhook controller** — mounted as a Rails Engine
- **LLM client + response parsing** — Anthropic and OpenAI supported
- **Action registry** — built at boot from annotated classes, frozen, closed
- **Dispatcher** — validates params, executes actions, returns results
- **Instruction file generator** — rake task that builds the system prompt
- **Conversation memory** — per-chat context with automatic compression

### What you own

- Annotation of eligible models and services
- Your LLM API key
- Your Telegram bot token and whitelisted user ID

### Key constraints

- **Whitelist-only** — nothing is registered unless explicitly listed in `agent_actions only: [...]`
- **Closed action space** — the LLM can only call registered actions; the dispatcher hard-rejects anything else
- **Single user** — only one Telegram user ID can communicate with the agent
- **No shadow API** — no duplicate routes, no separate HTTP layer; actions execute in-process
- **Telegram-first** for v1, transport layer abstracted for future channels

## Conversation memory

Herald maintains conversation context per Telegram chat. Consecutive messages can reference earlier ones naturally — "show me widget 5", then "update its quantity to 20" — because the full conversation history is sent to the LLM.

When the conversation reaches a configurable threshold (default: 20 messages), Herald makes a separate async LLM call to summarize the history so far. The summary replaces the older messages, and the most recent 4 messages are kept verbatim. This keeps context without growing the token cost unboundedly.

Conversations expire after a period of inactivity (default: 30 minutes), at which point the history is cleared.

Both values are configurable:

```ruby
Herald.configure do |config|
  config.conversation_compression_threshold = 30   # compress every 30 messages
  config.conversation_ttl = 3600                    # expire after 1 hour of inactivity
end
```

## Configuration reference

| Option                | Required | Default      | Description                              |
|-----------------------|----------|--------------|------------------------------------------|
| `telegram_bot_token`  | Yes      | —            | Your Telegram bot token                  |
| `telegram_user_id`    | Yes      | —            | Whitelisted Telegram user ID             |
| `llm_api_key`         | Yes      | —            | API key for your LLM provider            |
| `llm_provider`        | No       | `:anthropic` | `:anthropic` or `:openai`                |
| `instructions_path`   | No       | `config/herald_instructions.md` | Path for the generated instruction file |
| `conversation_compression_threshold` | No | `20` | Messages before context compression triggers |
| `conversation_ttl`    | No       | `1800`       | Seconds of inactivity before conversation expires |

## Demo app

A complete demo app is included in the `demo/` directory with Products, Orders, and a StatsService.

### Quick start

1. Create a `.env.development` file in the project root:

```
OPENAI_API_KEY=your-openai-api-key
```

2. Run the demo:

```bash
demo/bin/run
```

The script will:
- Load your API key from `.env.development`
- Install dependencies
- Set up an SQLite database with seed data (7 products, 6 orders)
- Generate the Herald instruction file
- Start a server on `http://localhost:3000`

3. Test with curl (the script prints the full command on startup):

```bash
curl -X POST http://localhost:3000/herald/webhook \
  -H 'Content-Type: application/json' \
  -H 'X-Telegram-Bot-Api-Secret-Token: <printed-by-script>' \
  -d '{"message":{"text":"list all products","from":{"id":123456},"chat":{"id":1}}}'
```

### Environment variables

The demo script loads `.env.development` automatically. It maps `OPENAI_API_KEY` to Herald's config if `HERALD_LLM_API_KEY` is not explicitly set.

You can also export directly:

```bash
export HERALD_LLM_API_KEY=your-key
export HERALD_LLM_PROVIDER=anthropic  # or openai
demo/bin/run
```

## License

MIT
