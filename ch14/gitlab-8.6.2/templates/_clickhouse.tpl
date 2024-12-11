{{- define "gitlab.clickhouse.main.password.secret" -}}
{{- .Values.global.clickhouse.main.password.secret | quote -}}
{{- end -}}

{{- define "gitlab.clickhouse.main.password.key" -}}
{{- coalesce .Values.global.clickhouse.main.key "password" | quote -}}
{{- end -}}
