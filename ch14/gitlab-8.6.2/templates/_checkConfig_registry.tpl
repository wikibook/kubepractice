{{/*
Ensure that registry's sentry has a DSN configured if enabled
*/}}
{{- define "gitlab.checkConfig.registry.sentry.dsn" -}}
{{-   if $.Values.registry.reporting.sentry.enabled }}
{{-     if not $.Values.registry.reporting.sentry.dsn }}
registry:
    When enabling sentry, you must configure at least one DSN.
    See https://docs.gitlab.com/charts/charts/registry#reporting
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.sentry.dsn */}}

{{/*
Ensure Registry notifications settings are in global scope
*/}}
{{- define "gitlab.checkConfig.registry.notifications" }}
{{- if hasKey $.Values.registry "notifications" }}
Registry: Notifications should be defined in the global scope. Use `global.registry.notifications` setting instead of `registry.notifications`.
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.notifications */}}

{{/*
Ensure Registry database is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.database" -}}
{{-   if not (quote $.Values.registry.database.sslmode | empty)  }}
{{-     $validSSLModes := list "require" "disable" "allow" "prefer" "require" "verify-ca" "verify-full" -}}
{{-     if not (has $.Values.registry.database.sslmode $validSSLModes) }}
registry:
    Invalid SSL mode "{{ .Values.registry.database.sslmode }}".
    Valid values are: {{ join ", " $validSSLModes }}.
    See https://docs.gitlab.com/charts/charts/registry#database
{{-     end -}}
{{-     $pgVersion := semver (.Values.postgresql.image.tag | toString) -}}
{{-     if lt $pgVersion.Major 13 -}}
registry:
    Invalid PostgreSQL version "{{ .Values.postgresql.image.tag }}".
    PostgreSQL 13 is the minimum required version for the registry database.
    See https://docs.gitlab.com/charts/charts/registry#database
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.database */}}

{{/*
Ensure Registry database load balancing is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.database.loadBalancing" -}}
{{- if $.Values.registry.database.loadBalancing.enabled }}
  {{- if not $.Values.registry.database.enabled }}
registry:
    Enabling database load balancing requires the metadata database to be enabled.
    See https://docs.gitlab.com/charts/charts/registry#load-balancing
  {{- end }}
  {{- if not $.Values.registry.redis.cache.enabled }}
registry:
    Enabling database load balancing requires Redis caching to be enabled.
    See https://docs.gitlab.com/charts/charts/registry/#redis-cache
  {{- end }}
  {{- if and (kindIs "string" $.Values.registry.database.loadBalancing.record) (empty $.Values.registry.database.loadBalancing.record) }}
registry:
    Enabling database load balancing requires the record to not be empty.
    See https://docs.gitlab.com/charts/charts/registry#load-balancing
  {{- end }}
{{- end -}}

{{- end -}}
{{/* END gitlab.checkConfig.registry.database.loadBalancing */}}

{{/*
Ensure Registry Redis cache is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.redis.cache" -}}
{{-   if and $.Values.registry.redis.cache.enabled (not $.Values.registry.database.enabled) }}
registry:
    Enabling the Redis cache requires the metadata database to be enabled.
    See https://docs.gitlab.com/charts/charts/registry#redis-cache
{{-   end -}}
{{-   if and $.Values.registry.database.enabled $.Values.registry.redis.cache.enabled }}
{{-     if  and (kindIs "string" $.Values.registry.redis.cache.host) (empty $.Values.registry.redis.cache.host) }}
registry:
    Enabling the Redis cache requires the host to not be empty.
    See https://docs.gitlab.com/charts/charts/registry#redis-cache
{{-     end -}}
{{- end -}}
{{-   if and $.Values.registry.database.enabled $.Values.registry.redis.cache.enabled $.Values.registry.redis.cache.sentinels}}
{{-     if  not $.Values.registry.redis.cache.host }}
registry:
    Enabling the Redis cache with sentinels requires the registry.redis.cache.host to be set.
    See https://docs.gitlab.com/charts/charts/registry#redis-cache
{{-     end -}}
{{- end -}}
{{-   if and $.Values.registry.redis.cache.enabled $.Values.registry.redis.cache.password.enabled }}
{{-     if and (kindIs "string" $.Values.registry.redis.cache.password.secret) (empty $.Values.registry.redis.cache.password.secret) }}
registry:
    Enabling the Redis cache password requires 'registry.redis.cache.password.secret' to be set.
    See https://docs.gitlab.com/charts/charts/registry#redis-cache
{{-     end -}}
{{-     if and (kindIs "string" $.Values.registry.redis.cache.password.key) (empty $.Values.registry.redis.cache.password.key) }}
registry:
    Enabling the Redis cache password requires 'registry.redis.cache.password.key' to be set.
    See https://docs.gitlab.com/charts/charts/registry#redis-cache
{{-     end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.redis.cache */}}

{{/*
Ensure Registry Redis rate-limiter is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.redis.rateLimiting" -}}
{{-   if $.Values.registry.redis.rateLimiting.enabled }}
{{-     if  and (kindIs "string" $.Values.registry.redis.rateLimiting.host) (empty $.Values.registry.redis.rateLimiting.host) }}
registry:
    Enabling the Redis rate-limiter requires the host to not be empty.
    See https://docs.gitlab.com/charts/charts/registry#redis-rate-limiter
{{-     end -}}
{{- end -}}
{{-   if and $.Values.registry.redis.rateLimiting.enabled $.Values.registry.redis.rateLimiting.sentinels}}
{{-     if  and (kindIs "string" $.Values.registry.redis.rateLimiting.host) (empty $.Values.registry.redis.rateLimiting.host) }}
registry:
    Enabling the Redis rate-limiter with sentinels requires the registry.redis.rateLimiting.host to be set.
    See https://docs.gitlab.com/charts/charts/registry#redis-rate-limiter
{{-     end -}}
{{- end -}}
{{-   if and $.Values.registry.redis.rateLimiting.enabled $.Values.registry.redis.rateLimiting.password.enabled }}
{{-     if and (kindIs "string" $.Values.registry.redis.rateLimiting.password.secret) (empty $.Values.registry.redis.rateLimiting.password.secret) }}
registry:
    Enabling the Redis rate-limiter password requires 'registry.redis.rateLimiting.password.secret' to be set.
    See https://docs.gitlab.com/charts/charts/registry#redis-rate-limiter
{{-     end -}}
{{-     if and (kindIs "string" $.Values.registry.redis.rateLimiting.password.key) (empty $.Values.registry.redis.rateLimiting.password.key) }}
registry:
    Enabling the Redis rate-limiter password requires 'registry.redis.rateLimiting.password.key' to be set.
    See https://docs.gitlab.com/charts/charts/registry#redis-cache
{{-     end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.redis.rateLimiting */}}

{{/*
Ensure Registry TLS has a secret when enabled
*/}}
{{- define "gitlab.checkConfig.registry.tls" -}}
{{-   if $.Values.registry.tls.enabled }}
{{-     if  not (eq (default "http" $.Values.global.hosts.registry.protocol) "https") }}
registry:
    Enabling the service level TLS requires 'global.hosts.registry.protocol'
    be set to 'https'.
    See https://docs.gitlab.com/charts/charts/registry/#configuring-tls
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.tls */}}

{{/*
Ensure a debug TLS secretName is provided if enabling debug TLS for the Registry
*/}}
{{- define "gitlab.checkConfig.registry.debug.tls" -}}
{{-   if $.Values.registry.debug.tls.enabled }}
{{-     if not $.Values.registry.debug.tls.secretName}}
{{-       if not (and $.Values.registry.tls.enabled $.Values.registry.tls.secretName)}}
registry:
    When Registry debug TLS is enabled a `registry.debug.tls.secretName`
    secret is required when not enabling TLS for the non-debug Registry endpoint.
    You must provide a secret containing a TLS certificate and key pair.
    See https://docs.gitlab.com/charts/charts/registry/index.html#configuring-tls-for-the-debug-port
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* gitlab.checkConfig.registry.tls */}}
