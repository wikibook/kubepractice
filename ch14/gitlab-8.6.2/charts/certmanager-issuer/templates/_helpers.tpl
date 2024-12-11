{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "certmanager-issuer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "certmanager-issuer.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified job name.
*/}}
{{- define "certmanager-issuer.jobname" -}}
{{- $name := printf "%s-issuer" .Release.Name | trunc 55 | trimSuffix "-" -}}
{{- printf "%s-%s" $name ( include "gitlab.jobNameSuffix" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Returns the http01 solver's ingress class field. Takes the IngressClass as paramter.
If the IngressClass is "none", the field is not set.
  See: https://cert-manager.io/docs/configuration/acme/http01/#ingressclassname

For backwards compatibility, the default is to use the legacy class attribute.
It is still required by some ingress providers, such as GKE Ingress.
  See: https://docs.gitlab.com/charts/releases/7_0.html#bundled-certmanager
*/}}
{{- define "certmanager-issuer.http01.ingress.class.spec" -}}
{{- $ingressCfg := dict "global" $.Values.global.ingress "local" .ingress "context" $ -}}
{{- $ingressClassName := include "ingress.class.name" $ingressCfg -}}
{{- if ne "none" $ingressClassName -}}
{{-   $useNewIngressClassNameField := $ingressCfg.global.useNewIngressForCerts | default false -}}
{{-   if $useNewIngressClassNameField -}}
ingressClassName: {{ $ingressClassName }}
{{-   else -}}
class: {{ $ingressClassName }}
{{-   end -}}
{{- end -}}
{{- end -}}
