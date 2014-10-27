# Don't need to ensure we can find cluster machines in test mode
use Mix.Config

config :simple_cache, :ensure_contact, :false

