{{/*
Helper for List of addresses as a string

Expectation: input contents has .sentinels or .cluster, which is a List of Dict
    in the format of [{host: , port:}, ...]
*/}}
{{- define "registry.redis.host.addresses" -}}
{{- $addresses := list -}}
{{- if .sentinels -}}
{{-   range .sentinels -}}
{{-     $addresses = append $addresses (printf "%s:%d" .host (default 26379 .port | int)) -}}
{{-   end -}}
{{- else if .cluster -}}
{{-   range .cluster -}}
{{-     $addresses = append $addresses (printf "%s:%d" .host (default 6379 .port | int)) -}}
{{-   end -}}
{{- end -}}
{{ join "," $addresses }}
{{- end -}}

{{- define "gitlab.registry.redisCacheSecret.mount" -}}
{{- if .Values.redis.cache.password.enabled }}
- secret:
    name: {{ default (include  "redis.secretName" . ) ( .Values.redis.cache.password.secret | quote) }}
    items:
      - key: {{ default (include "redis.secretPasswordKey" . ) ( .Values.redis.cache.password.key | quote) }}
        path: registry/redis-password
{{- end }}
{{- end -}}

{{- define "gitlab.registry.redisSentinelSecret.mount" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
{{- if .Values.redis.cache.sentinelpassword }}
{{-   if .Values.redis.cache.sentinelpassword.enabled }}
- secret:
    name: {{ .Values.redis.cache.sentinelpassword.secret | quote }}
    items:
      - key: {{ .Values.redis.cache.sentinelpassword.key | quote }}
        path: redis-sentinel/redis-sentinel-password
{{-   end }}
{{- else }}
{{- if .redisMergedConfig.sentinelAuth.enabled }}
- secret:
    name: {{ template "gitlab.redis.sentinelAuth.secret" . }}
    items:
      - key: {{ template "gitlab.redis.sentinelAuth.key" . }}
        path: redis-sentinel/redis-sentinel-password
{{- end }}
{{- end -}}
{{- end -}}

{{- define "gitlab.registry.redisRateLimitingSecret.mount" -}}
{{- if .Values.redis.rateLimiting.password.enabled }}
- secret:
    name: {{ default (include  "redis.secretName" . ) ( .Values.redis.rateLimiting.password.secret | quote) }}
    items:
      - key: {{ default (include "redis.secretPasswordKey" . ) ( .Values.redis.rateLimiting.password.key | quote) }}
        path: registry/redis-rateLimiting-password
{{- end }}
{{- end -}}

{{/*
Return Redis configuration.
*/}}
{{- define "registry.redis.config" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
redis:
  {{- if .Values.redis.cache.enabled }}
  cache:
    enabled: {{ .Values.redis.cache.enabled | eq true }}
    {{- if .Values.redis.cache.sentinels }}
    addr: {{ include "registry.redis.host.addresses" .Values.redis.cache | quote }}
    mainname: {{ .Values.redis.cache.host }}
    {{- else if .redisMergedConfig.sentinels }}
    addr: {{ include "registry.redis.host.addresses" .redisMergedConfig | quote }}
    mainname: {{ template "gitlab.redis.host" . }}
    {{-   if .redisMergedConfig.sentinelAuth.enabled }}
    sentinelpassword: {% file.Read "/config/redis-sentinel/redis-sentinel-password" | strings.TrimSpace | data.ToJSON %}
    {{-   end }}
    {{- else if .Values.redis.cache.host  }}
    addr: {{ printf "%s:%d" .Values.redis.cache.host (int .Values.redis.cache.port | default 6379) | quote }}
    {{- else }}
    addr: {{ printf "%s:%s" ( include "gitlab.redis.host" . ) ( include "gitlab.redis.port" . ) | quote }}
    {{- end }}
    {{- if .Values.redis.cache.password.enabled }}
    password: "REDIS_CACHE_PASSWORD"
    {{- end }}
    {{- if hasKey .Values.redis.cache "db" }}
    db: {{ .Values.redis.cache.db }}
    {{- end }}
    {{- if .Values.redis.cache.dialtimeout }}
    dialtimeout: {{ .Values.redis.cache.dialtimeout }}
    {{- end }}
    {{- if .Values.redis.cache.readtimeout }}
    readtimeout: {{ .Values.redis.cache.readtimeout }}
    {{- end }}
    {{- if .Values.redis.cache.writetimeout }}
    writetimeout: {{ .Values.redis.cache.writetimeout }}
    {{- end }}
    {{- if .Values.redis.cache.tls }}
    tls:
      enabled: {{ .Values.redis.cache.tls.enabled | eq true }}
      insecure: {{ .Values.redis.cache.tls.insecure | eq true }}
    {{- end }}
    {{- if .Values.redis.cache.pool }}
    pool:
      {{- if .Values.redis.cache.pool.size }}
      size: {{ .Values.redis.cache.pool.size }}
      {{- end }}
      {{- if .Values.redis.cache.pool.maxlifetime }}
      maxlifetime: {{ .Values.redis.cache.pool.maxlifetime }}
      {{- end }}
      {{- if .Values.redis.cache.pool.idletimeout }}
      idletimeout: {{ .Values.redis.cache.pool.idletimeout }}
      {{- end -}}
    {{- end -}}
  {{- end }}
  {{- /* reload template so that sentinels are included if they were set for the cache block first
  TODO: replace gitlab.redis.host with redisMergedConfig
  https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5628 */ -}}
  {{- include "gitlab.redis.selectedMergedConfig" . -}}
  {{- if .Values.redis.rateLimiting.enabled }}
  ratelimiter:
    enabled: {{ .Values.redis.rateLimiting.enabled | eq true }}
    {{- if .Values.redis.rateLimiting.sentinels }}
    addr: {{ include "registry.redis.host.addresses" .Values.redis.rateLimiting | quote }}
    mainname: {{ .Values.redis.rateLimiting.host }}
    {{- else if .Values.redis.rateLimiting.cluster }}
    addr: {{ include "registry.redis.host.addresses" .Values.redis.rateLimiting | quote }}
    {{- else if .Values.redis.rateLimiting.host  }}
    addr: {{ printf "%s:%d" .Values.redis.rateLimiting.host (int .Values.redis.rateLimiting.port | default 6379) | quote }}
    {{- else if .redisMergedConfig.sentinels }}
    addr: {{ include "registry.redis.host.addresses" .redisMergedConfig | quote }}
    mainname: {{ template "gitlab.redis.host" . }}
    {{- else }}
    addr: {{ printf "%s:%s" ( include "gitlab.redis.host" . ) ( include "gitlab.redis.port" . ) | quote }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.username }}
    username: {{ .Values.redis.rateLimiting.username }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.password.enabled }}
    password: "REDIS_RATE_LIMITING_PASSWORD"
    {{- end }}
    {{- if hasKey .Values.redis.rateLimiting "db" }}
    db: {{ .Values.redis.rateLimiting.db }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.dialtimeout }}
    dialtimeout: {{ .Values.redis.rateLimiting.dialtimeout }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.readtimeout }}
    readtimeout: {{ .Values.redis.rateLimiting.readtimeout }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.writetimeout }}
    writetimeout: {{ .Values.redis.rateLimiting.writetimeout }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.tls }}
    tls:
      enabled: {{ .Values.redis.rateLimiting.tls.enabled | eq true }}
      insecure: {{ .Values.redis.rateLimiting.tls.insecure | eq true }}
    {{- end }}
    {{- if .Values.redis.rateLimiting.pool }}
    pool:
      {{- if .Values.redis.rateLimiting.pool.size }}
      size: {{ .Values.redis.rateLimiting.pool.size }}
      {{- end }}
      {{- if .Values.redis.rateLimiting.pool.maxlifetime }}
      maxlifetime: {{ .Values.redis.rateLimiting.pool.maxlifetime }}
      {{- end }}
      {{- if .Values.redis.rateLimiting.pool.idletimeout }}
      idletimeout: {{ .Values.redis.rateLimiting.pool.idletimeout }}
      {{- end -}}
    {{- end -}}
  {{- end }}
{{- end -}}
