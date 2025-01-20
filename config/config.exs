import Config
alias Hush.Provider.SystemEnvironment

config(:hush, providers: [SystemEnvironment])

config(:secrets,
  client_id: {:hush, SystemEnvironment, "CLIENT_ID"},
  client_secret: {:hush, SystemEnvironment, "CLIENT_SECRET"},
  workspace_id: {:hush, SystemEnvironment, "WORKSPACE_ID"},
  workspace_env: {:hush, SystemEnvironment, "WORKSPACE_ENV"}
)
