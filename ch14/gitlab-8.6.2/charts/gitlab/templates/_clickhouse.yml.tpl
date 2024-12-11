{{- define "gitlab.clickhouse.yml" -}}
production:
  main:
    database: {{ .Values.global.clickhouse.main.database | quote }}
    url: {{ .Values.global.clickhouse.main.url | quote }}
    username: {{ .Values.global.clickhouse.main.username | quote }}
    password: <%= File.read('/etc/gitlab/clickhouse/.main_password').chomp.to_json %>
    variables:
      enable_http_compression: 1
      date_time_input_format: basic # needed for CH cloud
{{- end -}}

{{- define "gitlab.clickhouse.main.secrets" -}}
- secret:
    name: {{ include "gitlab.clickhouse.main.password.secret" . }}
    items:
      - key: {{ include "gitlab.clickhouse.main.password.key" . }}
        path: clickhouse/.main_password
{{- end }}
