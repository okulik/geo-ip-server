import Config

config :logger, level: :info

# Events are only reported to Sentry when a DSN is configured.
config :sentry,
  dsn:
    "https://87bb5bd5e933440fd2752529723fb397@o4506274286403584.ingest.sentry.io/4506274286600192",
  tags: %{env: "production"}

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
