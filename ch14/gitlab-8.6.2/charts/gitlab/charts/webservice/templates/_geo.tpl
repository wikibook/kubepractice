{{/*
Renders the ingress class annotation for Ingresses to handle Geo traffic.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "webservice.geo.ingress.class.annotation" -}}
{{- $apiVersion := include "gitlab.ingress.apiVersion" . -}}
{{- $class := include "gitlab.geo.ingress.class.name" .context -}}
{{- if and (not (eq $apiVersion "networking.k8s.io/v1")) (not (eq $class "none")) -}}
kubernetes.io/ingress.class: {{ $class | quote }}
{{- end -}}
{{- end -}}

{{/*
Renders the ingress class field for Ingresses to handle Geo traffic.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "webservice.geo.ingress.class.field" -}}
{{- $apiVersion := include "gitlab.ingress.apiVersion" . -}}
{{- $class := include "gitlab.geo.ingress.class.name" .context -}}
{{- if and (eq $apiVersion "networking.k8s.io/v1") (not (eq $class "none")) -}}
ingressClassName: {{ $class | quote }}
{{- end -}}
{{- end -}}
