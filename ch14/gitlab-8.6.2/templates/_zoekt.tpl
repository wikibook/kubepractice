{{/*
Return the Zoekt basic auth password secret name
*/}}

{{- define "gitlab.zoekt.gateway.basicAuth.secretName" -}}
{{- if .Values.global.zoekt.gateway.basicAuth.secretName }}
    {{- printf "%s" (tpl .Values.global.zoekt.gateway.basicAuth.secretName $) -}}
{{- else -}}
    {{- printf "%s-zoekt-basicauth" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Return the Zoekt internalApi password secret name
*/}}

{{- define "gitlab.zoekt.indexer.internalApi.secretName" -}}
{{- if .Values.global.zoekt.indexer.internalApi.secretName }}
    {{- printf "%s" (tpl .Values.global.zoekt.indexer.internalApi.secretName $) -}}
{{- else -}}
    {{- printf (include "gitlab.gitlab-shell.authToken.secret" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Zoekt internalApi password secret key
*/}}

{{- define "gitlab.zoekt.indexer.internalApi.secretKey" -}}
{{- if .Values.global.zoekt.indexer.internalApi.secretKey }}
    {{- printf "%s" (tpl .Values.global.zoekt.indexer.internalApi.secretKey $) -}}
{{- else -}}
    {{- printf (include "gitlab.gitlab-shell.authToken.key" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Zoekt internalApi gitlab URL
*/}}

{{- define "gitlab.zoekt.indexer.internalApi.gitlabUrl" -}}
{{- if .Values.global.zoekt.indexer.internalApi.gitlabUrl }}
    {{- printf "%s" (tpl .Values.global.zoekt.indexer.internalApi.gitlabUrl $) -}}
{{- else -}}
    {{- template "gitlab.gitlab.url" . -}}
{{- end -}}
{{- end -}}
