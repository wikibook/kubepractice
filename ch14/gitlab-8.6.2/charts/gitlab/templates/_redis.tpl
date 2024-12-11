{{/* ######### Redis related templates */}}

{{/*
Return the redis hostname
If the redis host is provided, it will use that, otherwise it will fallback
to the service name
*/}}
{{- define "gitlab.redis.host" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- if .redisMergedConfig.host -}}
{{-   .redisMergedConfig.host -}}
{{- else -}}
{{-   $name := default "redis" .Values.redis.serviceName -}}
{{-   $redisRelease := .Release.Name -}}
{{-   if contains $name $redisRelease -}}
{{-     $redisRelease = .Release.Name | trunc 63 | trimSuffix "-" -}}
{{-   else -}}
{{-     $redisRelease = printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{-   end -}}
{{-   printf "%s-master.%s.svc" $redisRelease .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Return the redis port
If the redis port is provided, it will use that, otherwise it will fallback
to 6379 default
*/}}
{{- define "gitlab.redis.port" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default 6379 .redisMergedConfig.port -}}
{{- end -}}

{{/*
Return the redis scheme, or redis. Allowing people to use rediss clusters
*/}}
{{- define "gitlab.redis.scheme" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- $valid := list "redis" "rediss" "tcp" -}}
{{- $name := default "redis" .redisMergedConfig.scheme -}}
{{- if has $name $valid -}}
{{    $name }}
{{- else -}}
{{    cat "Invalid redis scheme" $name | fail }}
{{- end -}}
{{- end -}}

{{/*
Return the redis url.
*/}}
{{- define "gitlab.redis.url" -}}
{{ template "gitlab.redis.scheme" . }}://{{ template "gitlab.redis.url.user" . }}{{ template "gitlab.redis.url.password" . }}{{ template "gitlab.redis.host" . }}:{{ template "gitlab.redis.port" . }}
{{- end -}}

{{/*
Return the Redis connection timeout.
*/}}
{{- define "gitlab.redis.connectTimeout" -}}
{{- if .Values.global.redis.connectTimeout -}}
{{ .Values.global.redis.connectTimeout }}
{{- end -}}
{{- end -}}

{{/*
Return the Redis read timeout.
*/}}
{{- define "gitlab.redis.readTimeout" -}}
{{- if .Values.global.redis.readTimeout -}}
{{ .Values.global.redis.readTimeout }}
{{- end -}}
{{- end -}}

{{/*
Return the Redis write timeout.
*/}}
{{- define "gitlab.redis.writeTimeout" -}}
{{- if .Values.global.redis.writeTimeout -}}
{{ .Values.global.redis.writeTimeout }}
{{- end -}}
{{- end -}}

{{/*
Return the user section of the Redis URI, if needed.
*/}}
{{- define "gitlab.redis.url.user" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{ .redisMergedConfig.user }}
{{- end -}}

{{/*
Return the password section of the Redis URI, if needed.
*/}}
{{- define "gitlab.redis.url.password" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- $password := printf "%s-%spassword" (default "redis" .redisConfigName) (ternary "override-" "" (default false .usingOverride)) -}}
{{- if .redisMergedConfig.password.enabled -}}:<%= ERB::Util::url_encode(File.read("/etc/gitlab/redis/{{ $password }}").strip) %>@{{- end -}}
{{- end -}}

{{/*
Return the Sentinel password, if available.
*/}}
{{- define "gitlab.redis.sentinel.password" -}}
{{- if $.Values.global.redis.sentinelAuth.enabled -}}<%= File.read("/etc/gitlab/redis-sentinel/redis-sentinel-password").strip %>{{- end -}}
{{- end -}}

{{/*
Build the structure describing sentinels
*/}}
{{- define "gitlab.redis.sentinelsList" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
{{- if .redisMergedConfig.sentinels -}}
{{- range $i, $entry := .redisMergedConfig.sentinels }}
- host: {{ $entry.host }}
  port: {{ default 26379 $entry.port }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "gitlab.redis.sentinels" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
{{- if .redisMergedConfig.sentinels -}}
sentinels:
{{- include "gitlab.redis.sentinelsList" . | nindent 2 }}
{{- end }}
{{- end -}}

{{/*Set redisMergedConfig*/}}
{{- define "gitlab.redis.selectedMergedConfig" -}}
{{- if .redisConfigName }}
{{-   $_ := set . "redisMergedConfig" ( index .Values.global.redis .redisConfigName ) -}}
{{- else -}}
{{-   $_ := set . "redisMergedConfig" .Values.global.redis -}}
{{- end -}}
{{-   if not (kindIs "map" (get $.redisMergedConfig "password")) -}}
{{-     $_ := set $.redisMergedConfig "password" $.Values.global.redis.auth -}}
{{-   end -}}
{{- range $key := keys $.Values.global.redis.auth -}}
{{-   if not (hasKey $.redisMergedConfig.password $key) -}}
{{-     $_ := set $.redisMergedConfig.password $key (index $.Values.global.redis.auth $key) -}}
{{-   end -}}
{{- end -}}
{{/* Set redisMergedConfig.sentinelAuth. */}}
{{- if not (kindIs "map" (get $.redisMergedConfig "sentinelAuth")) -}}
{{-   $_ := set $.redisMergedConfig "sentinelAuth" $.Values.global.redis.sentinelAuth -}}
{{- end -}}
{{- end -}}

{{/*
Return Sentinel list in format for Workhorse
*/}}
{{- define "gitlab.redis.workhorse.sentinel-list" }}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
{{- $sentinelList := list }}
{{- range $i, $entry := .redisMergedConfig.sentinels }}
  {{- $sentinelList = append $sentinelList (quote (print "tcp://" (trim $entry.host) ":" ( default 26379 $entry.port | int ) ) ) }}
{{- end }}
{{- $sentinelList | join "," }}
{{- end -}}


{{/*
Takes a dict with `globalContext` and `instances` as keys. The former specifies
the root context `$`, and the latter a list of instances to mount secrets for.
If instances is not specified, we mount secrets for all enabled Redis
instances.
*/}}
{{- define "gitlab.redis.secrets" -}}
{{- $ := .globalContext }}
{{- $mountRedisYmlOverrideSecrets := true }}
{{- if hasKey . "mountRedisYmlOverrideSecrets" }}
{{- $mountRedisYmlOverrideSecrets = .mountRedisYmlOverrideSecrets }}
{{- end }}
{{- $redisInstances := list "cache" "clusterCache" "sharedState" "queues" "actioncable" "traceChunks" "rateLimiting" "clusterRateLimiting" "sessions" "repositoryCache" "workhorse" }}
{{- if .instances }}
{{- $redisInstances = splitList " " .instances }}
{{- end }}
{{- range $redis := $redisInstances -}}
{{-   if index $.Values.global.redis $redis -}}
{{-     $_ := set $ "redisConfigName" $redis }}
{{      include "gitlab.redis.secret" $ }}
{{-   end }}
{{- end -}}

{{/* Include `global.redis.redisYmlOverride`'s secrets */}}
{{/* reset 'redisConfigName', to get global.redis.redisYmlOverride's Secret item */}}
{{- $_ := set $ "redisConfigName" "" }}
{{- if and $mountRedisYmlOverrideSecrets $.Values.global.redis.redisYmlOverride -}}
{{-   $_ := set $ "usingOverride" true }}
{{-   range $key, $redis := $.Values.global.redis.redisYmlOverride }}
{{-     $_ := set $ "redisConfigName" $key }}
{{      include "gitlab.redis.secret" $ }}
{{-   end }}
{{- end -}}
{{- $_ := set $ "usingOverride" false }}
{{/* Include global Redis secrets */}}
{{/* reset 'redisConfigName', to get global.redis.auth's Secret item */}}
{{- $_ := set $ "redisConfigName" "" }}
{{- if eq (include "gitlab.redis.password.enabled" $) "true" }}
{{    include "gitlab.redis.secret" $ }}
{{- end }}
{{- end -}}

{{- define "gitlab.redis.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- if .redisMergedConfig.password.enabled }}
{{-   $passwordPath := printf "%s-%spassword" (default "redis" .redisConfigName) (ternary "override-" "" (default false .usingOverride)) -}}
- secret:
    name: {{ template "gitlab.redis.password.secret" . }}
    items:
      - key: {{ template "gitlab.redis.password.key" . }}
        path: redis/{{ $passwordPath }}
{{- end }}
{{- end -}}

{{- define "gitlab.redisSentinel.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- if .redisMergedConfig.sentinelAuth.enabled }}
- secret:
    name: {{ template "gitlab.redis.sentinelAuth.secret" . }}
    items:
      - key: {{ template "gitlab.redis.sentinelAuth.key" . }}
        path: redis-sentinel/redis-sentinel-password
{{- end }}
{{- end -}}
