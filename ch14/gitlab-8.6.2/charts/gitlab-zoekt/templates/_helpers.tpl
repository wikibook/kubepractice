{{/*
Expand the name of the chart.
*/}}
{{- define "gitlab-zoekt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gitlab-zoekt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gitlab-zoekt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Cluster domain
*/}}
{{- define "gitlab-zoekt.clusterDomain" -}}
{{- $dnsResolver := .Values.gateway.dnsResolver }}
{{- $dnsArr := splitList "." $dnsResolver }}
{{- $arrLen := len $dnsArr }}
{{- join "." (slice $dnsArr (sub $arrLen 2) $arrLen) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gitlab-zoekt.labels" -}}
helm.sh/chart: {{ include "gitlab-zoekt.chart" . }}
{{ include "gitlab-zoekt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gitlab-zoekt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitlab-zoekt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Gateway selector labels
*/}}
{{- define "gitlab-zoekt.gatewaySelectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-gateway" (include "gitlab-zoekt.name" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Gateway image
*/}}
{{- define "gitlab-zoekt.gatewayImage" -}}
{{- if .Values.gateway.image.digest }}
{{- printf "%s@%s" .Values.gateway.image.repository .Values.gateway.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.gateway.image.repository .Values.gateway.image.tag }}
{{- end }}
{{- end}}

{{/*
External Gateway svc name
*/}}
{{- define "gitlab-zoekt.gatewaySvc" -}}
{{- printf "%s-gateway" (include "gitlab-zoekt.fullname" .) }}
{{- end }}

{{/*
External Gateway svc fqdn
*/}}
{{- define "gitlab-zoekt.gatewaySvcFqdn" -}}
{{- include "gitlab-zoekt.gatewaySvc" . }}.{{ .Release.Namespace }}.svc.{{ include "gitlab-zoekt.clusterDomain" . }}
{{- end }}

{{/*
External Gateway svc URL
*/}}
{{- define "gitlab-zoekt.gatewaySvcUrl" -}}
http{{ .Values.gateway.tls.certificate.enabled | ternary "s" "" }}://{{ include "gitlab-zoekt.gatewaySvcFqdn" . }}:{{ .Values.gateway.listen.port }}
{{- end }}

{{/*
Backend svc name
Should be set to gitlab-zoekt.fullname. Otherwise, stateful set's DNS stops working correctly
*/}}
{{- define "gitlab-zoekt.backendSvc" -}}
{{- include "gitlab-zoekt.fullname" . }}
{{- end }}

{{/*
Backend svc fqdn
*/}}
{{- define "gitlab-zoekt.backendSvcFqdn" -}}
{{- include "gitlab-zoekt.backendSvc" . }}.{{ .Release.Namespace }}.svc.{{ include "gitlab-zoekt.clusterDomain" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gitlab-zoekt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gitlab-zoekt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Placeholder label definitions.
These are overridden when this chart is used as a sub-chart of gitlab/gitlab
*/}}
{{- define "gitlab.standardLabels" -}}
{{- end -}}
{{- define "gitlab.commonLabels" -}}
{{- end -}}
{{- define "gitlab.serviceLabels" -}}
{{- end -}}

{{/*
Create the name of the map to use for external deployment gateway
*/}}
{{- define "gitlab-zoekt.configExternalGatewayMapName" -}}
{{- printf "%s-gateway-nginx-conf" (include "gitlab-zoekt.fullname" .) }}
{{- end }}

{{/*
Create the name of the map to use for zoekt gateway
*/}}
{{- define "gitlab-zoekt.configZoektGatewayMapName" -}}
{{- printf "%s-nginx-conf" (include "gitlab-zoekt.fullname" .) }}
{{- end }}

{{- define "gitlab-zoekt.basicAuth.secretName" -}}
{{- if .Values.gateway.basicAuth.secretName }}
{{- printf "%s" (tpl .Values.gateway.basicAuth.secretName $) -}}
{{- else -}}
{{- printf "%s-basicauth" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "gitlab-zoekt.internalApi.secretName" -}}
{{- if .Values.indexer.internalApi.secretName }}
{{- printf "%s" (tpl .Values.indexer.internalApi.secretName $) -}}
{{- else -}}
{{- printf "%s-internal-api-secret-name" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "gitlab-zoekt.internalApi.secretKey" -}}
{{- if .Values.indexer.internalApi.secretKey }}
{{- printf "%s" (tpl .Values.indexer.internalApi.secretKey $) -}}
{{- else -}}
{{- printf "%s-internal-api-secret-key" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "gitlab-zoekt.internalApi.gitlabUrl" -}}
{{- if .Values.indexer.internalApi.gitlabUrl }}
{{- printf "%s" (tpl .Values.indexer.internalApi.gitlabUrl $) -}}
{{- end -}}
{{- end -}}

{{- define "gitlab-zoekt.internalApi.serviceUrl" -}}
{{- if .Values.indexer.internalApi.serviceUrl }}
{{- printf "%s" (tpl .Values.indexer.internalApi.serviceUrl $) -}}
{{- else }}
{{- include "gitlab-zoekt.gatewaySvcUrl" .}}
{{- end -}}
{{- end -}}

{{/*
Template used in NOTES.txt for the default pod name
*/}}
{{- define "gitlab-zoekt.notesDefaultPodName" -}}
{{ printf "%s-0" (include "gitlab-zoekt.backendSvc" .) }}
{{- end }}