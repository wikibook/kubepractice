{{/* vim: set filetype=mustache: */}}

{{/*
Return the registry authEndpoint
Defaults to the globally set gitlabHostname if an authEndpoint hasn't been provided
to the chart
*/}}
{{- define "registry.authEndpoint" -}}
{{- if .Values.authEndpoint -}}
{{- .Values.authEndpoint -}}
{{- else -}}
{{- template "gitlab.gitlab.url" . -}}
{{- end -}}
{{- end -}}

{{/*
Returns the hostname.
If the hostname is set in `global.hosts.registry.name`, that will be returned,
otherwise the hostname will be assembed using `registry` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "registry.hostname" -}}
{{- coalesce .Values.global.hosts.registry.name (include "gitlab.assembleHost"  (dict "name" "registry" "context" . )) -}}
{{- end -}}

{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "registry.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-registry-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{/*
Returns the minio URL.
If `registry.redirect` is set to `true` it will return the external domain name of minio,
e.g. `https://minio.example.com`, otherwise it will fallback to the internal minio service
URL, e.g. `http://minio-svc:9000`.

For external domain name, if `global.hosts.https` or `global.hosts.minio.https` is true,
it uses https, otherwise http. Calls into the `gitlab.minio.hostname` function for the
hostname part of the url.
*/}}
{{- define "registry.minio.url" -}}
{{- if .Values.minio.redirect -}}
  {{- if or .Values.global.hosts.https .Values.global.hosts.minio.https -}}
  {{-   printf "https://%s" (include "gitlab.minio.hostname" .) -}}
  {{- else -}}
  {{-   printf "http://%s" (include "gitlab.minio.hostname" .) -}}
  {{- end -}}
{{- else -}}
  {{- include "gitlab.minio.endpoint" . -}}
{{- end -}}
{{- end -}}

{{/*
Populate registry notifications
*/}}
{{- define "registry.notifications.config" -}}
{{- $geoNotifier := include "global.geo.registry.syncNotifier" . | fromYaml -}}
{{- $notifications := merge $.Values.global.registry.notifications $geoNotifier -}}
{{- if $notifications }}
notifications:
  {{- if $notifications.events }}
  events:
    {{- toYaml $.Values.global.registry.notifications.events | nindent 4 }}
  {{- end -}}
  {{- $endpoints := concat (list) $notifications.endpoints $geoNotifier.endpoints | uniq -}}
  {{- if $endpoints }}
  endpoints:
    {{- range $endpoint := $endpoints -}}
      {{- if $endpoint.name -}}
        {{- $headers := pluck "headers" $endpoint | first -}}
        {{- $endpoint = omit $endpoint "headers" }}
        {{- toYaml (list $endpoint) | nindent 4 }}
        {{- if $headers }}
      headers:
          {{- range $header, $value := $headers -}}
            {{- if kindIs "map" $value -}}
              {{- if hasKey $value "secret" }}
        {{ $header }}: SECRET_{{ $value.secret }}_{{ default "value" $value.key }}
              {{- end -}}
            {{- else }}
        {{ $header }}: {{ $value }}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Individual secret items to be used as volumes
Usage:
{{ include "registry.notifications.secrets.item " ( \
     dict
         "value" $value
         "fileName" $fileName
     ) }}
*/}}
{{- define "registry.notifications.secrets.item" -}}
- secret:
    name: {{ .value.secret }}
    items:
      - key: {{ default "value" .value.key }}
        path: notifications/SECRET_{{ .fileName }}
{{- end }}

{{/*
Sensitive registry notification headers mounted as secrets
*/}}
{{- define "registry.notifications.secrets" -}}
{{- $geoNotifier := include "global.geo.registry.syncNotifier" . | fromYaml -}}
{{- $notifications := merge $.Values.global.registry.notifications $geoNotifier -}}
{{- if $notifications }}
  {{- $uniqSecrets := list -}}
  {{- $endpoints := concat (list) $notifications.endpoints $geoNotifier.endpoints | uniq -}}
  {{- range $endpoint := $endpoints -}}
    {{- if and $endpoint.name $endpoint.headers -}}
      {{- range $header, $value := $endpoint.headers -}}
        {{- if kindIs "map" $value -}}
          {{- if hasKey $value "secret" }}
            {{- $fileName := printf "%s_%s" $value.secret (default "value" $value.key) -}}
            {{- if not (has $fileName $uniqSecrets) }}
              {{- $uniqSecrets = append $uniqSecrets $fileName }}
{{ include "registry.notifications.secrets.item" (dict "value" $value "fileName" $fileName) }}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "registry.fullname" -}}
{{- include "fullname" $ -}}
{{- end -}}
{{/*
Return the sub-chart serviceAccount name
If that is not present it will use the global chart serviceAccount name
Failing that a serviceAccount will be generated automatically
*/}}
{{- define "registry.serviceAccount.name" -}}
{{- coalesce .Values.serviceAccount.name .Values.global.serviceAccount.name ( include "registry.fullname" . ) -}}
{{- end -}}

{{/*
Create a default fully qualified job name.
*/}}
{{- define "registry.migrations.jobname" -}}
{{- $name := include "registry.fullname" . | trunc 55 | trimSuffix "-" -}}
{{- printf "%s-migrations-%s" $name ( include "gitlab.jobNameSuffix" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Optionally create a node affinity rule to optionally deploy registry pods in a specific zone
*/}}
{{- define "registry.affinity" -}}
{{- $affinityOptions := list "hard" "soft" }}
{{- if or
  (has (default .Values.global.antiAffinity "") $affinityOptions)
  (has (default .Values.antiAffinity "") $affinityOptions)
  (has (default .Values.global.nodeAffinity "") $affinityOptions)
  (has (default .Values.nodeAffinity "") $affinityOptions)
}}
affinity:
  {{- if eq (default .Values.global.antiAffinity .Values.antiAffinity) "hard" }}
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - topologyKey: {{ default .Values.global.affinity.podAntiAffinity.topologyKey .Values.affinity.podAntiAffinity.topologyKey | quote }}
          labelSelector:
            matchLabels:
              app: {{ template "name" . }}
              release: {{ .Release.Name }}
  {{- else if eq (default .Values.global.antiAffinity .Values.antiAffinity) "soft" }}
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          podAffinityTerm:
            topologyKey: {{ default .Values.global.affinity.podAntiAffinity.topologyKey .Values.affinity.podAntiAffinity.topologyKey | quote }}
            labelSelector:
              matchLabels:
                app: {{ template "name" . }}
                release: {{ .Release.Name }}
  {{- end -}}
  {{- if eq (default .Values.global.nodeAffinity .Values.nodeAffinity) "hard" }}
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: {{ default .Values.global.affinity.nodeAffinity.key .Values.affinity.nodeAffinity.key | quote }}
                operator: In
                values: {{ default .Values.global.affinity.nodeAffinity.values .Values.affinity.nodeAffinity.values | toYaml | nindent 16 }}

  {{- else if eq (default .Values.global.nodeAffinity .Values.nodeAffinity) "soft" }}
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          nodeSelectorTerms:
            - matchExpressions:
                - key: {{ default .Values.global.affinity.nodeAffinity.key .Values.affinity.nodeAffinity.key | quote }}
                  operator: In
                  values: {{ default .Values.global.affinity.nodeAffinity.values .Values.affinity.nodeAffinity.values | toYaml | nindent 18 }}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Render the standard labels for resources related to the registry migration.
These differ from the standard labels so the migration related Pod's are not
matched by the registry PDB and Deployment selectors.
*/}}
{{- define "registry.migration.standardLabels" -}}
{{- $labels := (include "gitlab.standardLabels" .) | fromYaml }}
{{- $_ := set $labels "app" "registry-migrations" }}
{{- toYaml $labels }}
{{- end -}}
