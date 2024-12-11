{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified job name.
*/}}
{{- define "migrations.jobname" -}}
{{- $name := include "fullname" . | trunc 55 | trimSuffix "-" -}}
{{- printf "%s-%s" $name ( include "gitlab.jobNameSuffix" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
