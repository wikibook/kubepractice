{{/*
Detect if Monitoring ("monitoring.coreos.com/v1") is enabled.
Returns 'true' if either it was manually enabled via `global.monitoring.enabled`
or if the API is available via Helm's Capabilities.
*/}}
{{- define "gitlab.monitoring.enabled" -}}
{{-   $manuallyEnabled := .Values.global.monitoring.enabled -}}
{{-   $apiAvailable := .Capabilities.APIVersions.Has "monitoring.coreos.com/v1" -}}
{{-   if or $manuallyEnabled $apiAvailable -}}
{{-     true -}}
{{-   else -}}
{{-     false -}}
{{-   end -}}
{{- end -}}
