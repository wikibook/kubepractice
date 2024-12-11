{{/* vim: set filetype=mustache: */}}

{{/*
Return the URL desired by GitLab Exporter

If global.redis.queues is present, use this. If not present, use global.redis
*/}}
{{- define "gitlab.gitlab-exporter.redis.url" -}}
{{- if $.Values.global.redis.queues -}}
{{- $_ := set $ "redisConfigName" "queues" }}
{{- end -}}
{{- include "gitlab.redis.url" $ -}}
{{- end -}}

{{- define "gitlab.gitlab-exporter.redis.sentinelsList" -}}
{{- if $.Values.global.redis.queues -}}
{{- $_ := set $ "redisConfigName" "queues" }}
{{- end -}}
{{- include "gitlab.redis.sentinelsList" . }}
{{- end -}}
