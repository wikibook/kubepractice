{{/*
Return the appropriate apiVersion for Traefik.

It expects a dictionary with three entries:
  - `global` which contains global Traefik settings, e.g. .Values.global.traefik
  - `local` which contains local Traefik settings, e.g. .Values.traefik
  - `context` which is the parent context (either `.` or `$`)

Example usage:
{{- $traefikApiVersion := dict "global" .Values.global.traefik "local" .Values.traefik "context" . -}}
apiVersion: "{{ template "traefik.apiVersion" $traefikApiVersion }}"
*/}}
{{- define "traefik.apiVersion" -}}
{{-   if .local.apiVersion -}}
{{-     .local.apiVersion -}}
{{-   else if .global.apiVersion -}}
{{-     .global.apiVersion -}}
{{-   else if .context.Capabilities.APIVersions.Has "traefik.io/v1alpha1/IngressRouteTCP" -}}
{{-     print "traefik.io/v1alpha1" -}}
{{-   else -}}
{{-     print "traefik.containo.us/v1alpha1" -}}
{{-   end -}}
{{- end -}}
