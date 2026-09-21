import Config
import Dotenvy

source!(".env")

config :craft_chat, :openrouter,
  api_key: env!("OPENROUTER_API_KEY", :string!),
  model: env!("MODEL", :string, "openai/gpt-4o-mini")
