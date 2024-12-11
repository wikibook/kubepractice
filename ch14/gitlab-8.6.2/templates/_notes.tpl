{{/* vim: set filetype=mustache: */}}
{{/*
  Returns information about all non-production ready subcharts, formatted
  as YAML.
*/}}
{{- define "gitlab.nonProdCharts" }}
charts:
  - name: PostgreSQL
    enabled: {{ .Values.postgresql.install }}
  - name: Redis
    enabled: {{ .Values.redis.install }}
  - name: Gitaly
    enabled: {{ .Values.global.gitaly.enabled }}
  - name: Praefect
    enabled: {{ .Values.global.praefect.enabled }}
  - name: MinIO
    enabled: {{ .Values.global.minio.enabled }}
{{- end }}

{{/*
  Returns a array of all enabled non-production ready subcharts.
*/}}
{{- define "gitlab.nonProdCharts.enabledNames" }}
{{- $names := (list) }}
{{- $charts := (fromYaml (include "gitlab.nonProdCharts" .)).charts }}
{{- range $charts }}
{{-   if .enabled }}
{{-     $names = append $names .name }}
{{-   end }}
{{- end }}
{{ toJson $names }}
{{- end }}
