
{{/* ######### ingress templates */}}

{{/*
Return the appropriate apiVersion for Ingress.

It expects a dictionary with three entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `local` which contains local ingress settings, e.g. .Values.ingress
  - `context` which is the parent context (either `.` or `$`)

Example usage:
{{- $ingressCfg := dict "global" .Values.global.ingress "local" .Values.ingress "context" . -}}
kubernetes.io/ingress.provider: "{{ template "gitlab.ingress.provider" $ingressCfg }}"
*/}}
{{- define "gitlab.ingress.apiVersion" -}}
{{-   if .local.apiVersion -}}
{{-     .local.apiVersion -}}
{{-   else if .global.apiVersion -}}
{{-     .global.apiVersion -}}
{{-   else if .context.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
{{-     print "networking.k8s.io/v1" -}}
{{-   else if .context.Capabilities.APIVersions.Has "networking.k8s.io/v1beta1/Ingress" -}}
{{-     print "networking.k8s.io/v1beta1" -}}
{{-   else -}}
{{-     print "extensions/v1beta1" -}}
{{-   end -}}
{{- end -}}

{{/*
Returns the ingress provider

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `local` which contains local ingress settings, e.g. .Values.ingress
*/}}
{{- define "gitlab.ingress.provider" -}}
{{- default .global.provider .local.provider -}}
{{- end -}}

{{/*
Overrides the ingress-nginx template to make sure gitlab-shell name matches
*/}}
{{- define "ingress-nginx.tcp-configmap" -}}
{{ .Release.Name}}-nginx-ingress-tcp
{{- end -}}

{{/*
Adds `ingress.class` annotation based on the API version of Ingress.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "ingress.class.annotation" -}}
{{-   if not (eq (default "" .global.class) "none" ) -}}
{{-     $apiVersion := include "gitlab.ingress.apiVersion" . -}}
{{-     $className := include "ingress.class.name" . -}}
{{-       if not (eq $apiVersion "networking.k8s.io/v1") -}}
kubernetes.io/ingress.class: {{ $className | quote }}
{{-       end -}}
{{-   end -}}
{{- end -}}

{{/*
Calculates the IngressClass name.

It expects either:
  - a dictionary with two entries:
    - `global` which contains global ingress settings, e.g. .Values.global.ingress
    - `context` which is the parent context (either `.` or `$`)
  - the parent context ($ from caller)
    - This detected by access to both `.Capabilities` and `.Release`

If the value is not set or is set to nil, then it provides a default.
Otherwise, it will use the given value (even an empty string "").
*/}}
{{- define "ingress.class.name" -}}
{{-   $here := dict }}
{{-   if and (hasKey $ "Release") (hasKey $ "Capabilities") -}}
{{-     $here = dict "global" $.Values.global.ingress "context" $ -}}
{{-   else -}}
{{-     $here = . -}}
{{-   end -}}
{{-   if kindIs "invalid" $here.global.class -}}
{{-     printf "%s-nginx" $here.context.Release.Name -}}
{{-   else -}}
{{-     $here.global.class -}}
{{-   end -}}
{{- end -}}

{{/*
Sets `ingressClassName` based on the API version of Ingress.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "ingress.class.field" -}}
{{-   if not (eq (default "" .global.class) "none" ) -}}
{{-     $apiVersion := include "gitlab.ingress.apiVersion" . -}}
{{-     if eq $apiVersion "networking.k8s.io/v1" -}}
ingressClassName: {{ include "ingress.class.name" . | quote }}
{{-     end -}}
{{-   end -}}
{{- end -}}
