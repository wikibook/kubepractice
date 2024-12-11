{{/* Common templates for KEDA */}}

{{/*
Check if KEDA is enabled and any ScaledObject trigger can be set

It expects a dictionary with two entries:
  - `global` which contains global settings, e.g. .Values.global
  - `hpa` which contains HPA settings, e.g. .Values.sidekiq.hpa
  - `keda` which contains KEDA settings, e.g. .Values.sidekiq.keda
  - `resources` (optional) which is the resource configuration for the main container
*/}}
{{- define "gitlab.keda.scaledobject.enabled" -}}
{{-   $cpuTrigger := and .hpa.cpu .resources.requests.cpu -}}
{{-   $memoryTrigger := and .hpa.memory .resources.requests.memory -}}
{{-   if and (default .global.keda.enabled .keda.enabled) (or .keda.triggers $cpuTrigger $memoryTrigger) -}}
true
{{-   end -}}
{{- end -}}

{{/*
Returns a ScaledObject spec, defaulting to the HPA behavior configuration where applicable if set

It expects a dictionary with four entries:
  - `hpa` which contains HPA settings, e.g. .Values.sidekiq.hpa
  - `keda` which contains KEDA settings, e.g. .Values.sidekiq.keda
  - `minReplicas` (optional) which is the minimum replica count if not set in `hpa`
  - `maxReplicas` (optional) which is the maximum replica count if not set in `hpa`
  - `resources` (optional) which is the resource configuration for the main container
*/}}
{{- define "gitlab.keda.scaledobject.spec" -}}
{{- $behavior := .keda.behavior | default .hpa.behavior -}}
pollingInterval: {{ .keda.pollingInterval }}
cooldownPeriod: {{ .keda.cooldownPeriod }}
minReplicaCount: {{ coalesce .keda.minReplicaCount .hpa.minReplicas .minReplicas }}
maxReplicaCount: {{ coalesce .keda.maxReplicaCount .hpa.maxReplicas .maxReplicas }}
{{- if or .keda.restoreToOriginalReplicaCount $behavior }}
advanced:
  {{- if .keda.restoreToOriginalReplicaCount }}
  restoreToOriginalReplicaCount: {{ .keda.restoreToOriginalReplicaCount }}
  {{- end -}}
  {{- if or $behavior .keda.hpaName }}
  horizontalPodAutoscalerConfig:
    {{- if .keda.hpaName }}
    name: {{ .keda.hpaName }}
    {{- end -}}
    {{- if $behavior }}
    behavior: {{ toYaml $behavior | nindent 6 }}
    {{- end -}}
  {{- end -}}
{{- end }}
{{- if .keda.fallback }}
fallback: {{ toYaml .keda.fallback | nindent 2 }}
{{- end }}
triggers:
{{- if .keda.triggers }}
  {{- toYaml .keda.triggers | nindent 2 }}
{{- else -}}
  {{- if .resources.requests.cpu -}}
    {{- with .hpa.cpu -}}
      {{- $targetType := default "Utilization" .targetType }}
  - type: cpu
    metricType: {{ $targetType }}
    metadata:
      {{- if eq $targetType "Utilization" }}
      value: {{ quote .targetAverageUtilization }}
      {{- else }}
      value: {{ quote .targetAverageValue }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if .resources.requests.memory -}}
    {{- with .hpa.memory -}}
    {{- $targetType := default "Utilization" .targetType }}
  - type: memory
    metricType: {{ $targetType }}
    metadata:
      {{- if eq $targetType "Utilization" }}
      value: {{ quote .targetAverageUtilization }}
      {{- else }}
      value: {{ quote .targetAverageValue }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
