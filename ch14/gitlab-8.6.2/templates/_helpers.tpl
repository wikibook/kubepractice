{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Run "fullname" as if it was in another chart. This is an imperfect emulation, but close.

This is especially useful when you reference "fullname" services/pods which may or may not be easy to reconstruct.

Call:

```
{{- include "gitlab.other.fullname" ( dict "context" . "chartName" "name-of-other-chart" ) -}}
```
*/}}
{{- define "gitlab.other.fullname" -}}
{{- $Chart := dict "Name" .chartName -}}
{{- $Release := .context.Release -}}
{{- $localNameOverride :=  (pluck "nameOverride" (pluck .chartName .context.Values | first) | first) -}}
{{- $globalNameOverride :=  (pluck "nameOverride" (pluck .chartName .context.Values.global | first) | first) -}}
{{- $nameOverride :=  coalesce $localNameOverride $globalNameOverride -}}
{{- $Values := dict "nameOverride" $nameOverride "global" .context.Values.global -}}
{{- include "fullname" (dict "Chart" $Chart "Release" $Release "Values" $Values) -}}
{{- end -}}

{{/* ######### Hostname templates */}}

{{/*
Returns the hostname.
If the hostname is set in `global.hosts.gitlab.name`, that will be returned,
otherwise the hostname will be assembled using `gitlab` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "gitlab.gitlab.hostname" -}}
{{- coalesce .Values.global.hosts.gitlab.name (include "gitlab.assembleHost"  (dict "name" "gitlab" "context" . )) -}}
{{- end -}}

{{/*
Returns the GitLab Url, ex: `http://gitlab.example.com`
If `global.hosts.https` or `global.hosts.gitlab.https` is true, it uses https, otherwise http.
Calls into the `gitlab.gitlabHost` function for the hostname part of the url.
*/}}
{{- define "gitlab.gitlab.url" -}}
{{- if or .Values.global.hosts.https .Values.global.hosts.gitlab.https -}}
{{-   printf "https://%s" (include "gitlab.gitlab.hostname" .) -}}
{{- else -}}
{{-   printf "http://%s" (include "gitlab.gitlab.hostname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Returns the minio hostname.
If the hostname is set in `global.hosts.minio.name`, that will be returned,
otherwise the hostname will be assembled using `minio` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "gitlab.minio.hostname" -}}
{{- coalesce .Values.global.hosts.minio.name (include "gitlab.assembleHost"  (dict "name" "minio" "context" . )) -}}
{{- end -}}

{{/*
Returns the minio url.
*/}}

{{- define "gitlab.minio.url" -}}
{{- if or .Values.global.hosts.https .Values.global.hosts.minio.https -}}
{{-   printf "https://%s" (include "gitlab.minio.hostname" .) -}}
{{- else -}}
{{-   printf "http://%s" (include "gitlab.minio.hostname" .) -}}
{{- end -}}
{{- end -}}

{{/* ######### Utility templates */}}

{{/*
  A helper function for assembling a hostname using the base domain specified in `global.hosts.domain`
  Takes a `Map/Dictonary` as an argument. Where key `name` is the domain to build, and `context` should be a
  reference to the chart's $ object.
  eg: `template "assembleHost" (dict "name" "minio" "context" .)`

  The hostname will be the combined name with the domain. eg: If domain is `example.com`, it will produce `minio.example.com`
  Additionally if `global.hosts.hostSuffix` is set, it will append a hyphen, then the suffix to the name:
  eg: If hostSuffix is `beta` it will produce `minio-beta.example.com`
*/}}
{{- define "gitlab.assembleHost" -}}
{{- $name := .name -}}
{{- $context := .context -}}
{{- $result := dict -}}
{{- if $context.Values.global.hosts.domain -}}
{{-   $_ := set $result "domainHost" (printf ".%s" $context.Values.global.hosts.domain) -}}
{{-   if $context.Values.global.hosts.hostSuffix -}}
{{-     $_ := set $result "domainHost" (printf "-%s%s" $context.Values.global.hosts.hostSuffix $result.domainHost) -}}
{{-   end -}}
{{-   $_ := set $result "domainHost" (printf "%s%s" $name $result.domainHost) -}}
{{- end -}}
{{- $result.domainHost -}}
{{- end -}}

{{/* ######### cert-manager templates */}}

{{- define "gitlab.certmanager_annotations" -}}
{{- if (pluck "configureCertmanager" .Values.ingress .Values.global.ingress (dict "configureCertmanager" false) | first) -}}
cert-manager.io/issuer: "{{ .Release.Name }}-issuer"
{{-   if not .Values.global.ingress.useNewIngressForCerts }}
acme.cert-manager.io/http01-edit-in-place: "true"
{{-   end -}}
{{- end -}}
{{- end -}}

{{/* ######### postgresql templates */}}

{{/*
Return the db hostname
If an external postgresl host is provided, it will use that, otherwise it will fallback
to the service name. Failing a specified service name it will fall back to the default service name.

This overrides the upstream postegresql chart so that we can deterministically
use the name of the service the upstream chart creates
*/}}
{{- define "gitlab.psql.host" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- coalesce (pluck "host" $local .Values.global.psql | first) (printf "%s.%s.svc" (include "postgresql.primary.fullname" .) $.Release.Namespace) -}}
{{- end -}}

{{/*
Return the configmap for initializing the PostgreSQL database. This is used to enable the
necessary postgres extensions for Gitlab to work
This overrides the upstream postegresql chart so that we can deterministically
use the name of the initdb scripts ConfigMap the upstream chart creates
*/}}
{{- define "gitlab.psql.initdbscripts" -}}
{{- printf "%s-%s-%s" .Release.Name "postgresql" "init-db" -}}
{{- end -}}

{{/*
Overrides the full name of PostegreSQL in the upstream chart.
*/}}
{{- define "postgresql.primary.fullname" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- coalesce (pluck "serviceName" $local .Values.global.psql | first) (printf "%s-%s" $.Release.Name "postgresql") -}}
{{- end -}}

{{/*
Overrides the username of PostegreSQL in the upstream chart.

Alias of gitlab.psql.username
*/}}
{{- define "postgresql.username" -}}
{{- template "gitlab.psql.username" . -}}
{{- end -}}

{{/*
Overrides the database name of PostegreSQL in the upstream chart.

Alias of gitlab.psql.database
*/}}
{{- define "postgresql.database" -}}
{{- template "gitlab.psql.database" . -}}
{{- end -}}


{{/*
Return the db database name
*/}}
{{- define "gitlab.psql.database" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- coalesce (pluck "database" $local .Values.global.psql | first) "gitlabhq_production" -}}
{{- end -}}

{{/*
Return the db username
If the postgresql username is provided, it will use that, otherwise it will fallback
to "gitlab" default
*/}}
{{- define "gitlab.psql.username" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- coalesce (pluck "username" $local .Values.global.psql | first) "gitlab" -}}
{{- end -}}

{{/*
Return the db port
If the postgresql port is provided in subchart values or global values, it will use that, otherwise it will fallback
to 5432 default
*/}}
{{- define "gitlab.psql.port" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- default 5432 (pluck "port" $local $.Values.global.psql | first ) | int -}}
{{- end -}}

{{/*
Return the secret name
Defaults to a release-based name and falls back to .Values.global.psql.secretName
  when using an external PostgreSQL
*/}}
{{- define "gitlab.psql.password.secret" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- $localPass := pluck "password" $local | first -}}
{{- default (printf "%s-%s" .Release.Name "postgresql-password") (pluck "secret" $localPass $.Values.global.psql.password | first ) | quote -}}
{{- end -}}

{{/*
Return the name of the key in a secret that contains the postgres password
Uses `postgresql-password` to match upstream postgresql chart when not using an
  external postegresql
*/}}
{{- define "gitlab.psql.password.key" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- $localPass := pluck "password" $local | first -}}
{{- default "postgresql-password" (pluck "key" $localPass $.Values.global.psql.password | first ) | quote -}}
{{- end -}}

{{/*
Return the application name that should be presented to PostgreSQL.
A blank string tells the client NOT to send an application name.
A nil value will use the process name by default.
See https://github.com/Masterminds/sprig/issues/53 for how we distinguish these.
Defaults to nil.
*/}}
{{- define "gitlab.psql.applicationName" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- $appname := pluck "applicationName" $local .Values.global.psql | first -}}
{{- if not ( kindIs "invalid" $appname ) -}}
{{- $appname | quote -}}
{{- end -}}
{{- end -}}

{{/*
Return if prepared statements should be used by PostgreSQL.
Defaults to false
*/}}
{{- define "gitlab.psql.preparedStatements" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{- eq true (default false (pluck "preparedStatements" $local .Values.global.psql | first)) -}}
{{- end -}}

{{/*
Return if database tasks should be used by GitLab Rails for a given configuration.
Defaults to true
*/}}
{{- define "gitlab.psql.databaseTasks" -}}
{{-   $local := pluck "psql" $.Values | first -}}
{{-   $databaseTasks := pluck "databaseTasks" $local .Values.global.psql | first -}}
{{-   if not ( kindIs "invalid" $databaseTasks ) -}}
{{-     eq true $databaseTasks -}}
{{-   else -}}
{{-     true -}}
{{-   end -}}
{{- end -}}

{{/*
Return connect_timeout value
Defaults to nil
*/}}
{{- define "gitlab.psql.connectTimeout" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{ pluck "connectTimeout" $local .Values.global.psql | first -}}
{{- end -}}

{{/*
Return keepalives value
Defaults to nil
*/}}
{{- define "gitlab.psql.keepalives" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{ pluck "keepalives" $local .Values.global.psql | first -}}
{{- end -}}

{{/*
Return keepalives_idle value
Defaults to nil
*/}}
{{- define "gitlab.psql.keepalivesIdle" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{ pluck "keepalivesIdle" $local .Values.global.psql | first -}}
{{- end -}}

{{/*
Return keepalives_interval value
Defaults to nil
*/}}
{{- define "gitlab.psql.keepalivesInterval" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{ pluck "keepalivesInterval" $local .Values.global.psql | first -}}
{{- end -}}

{{/*
Return keepalives_count value
Defaults to nil
*/}}
{{- define "gitlab.psql.keepalivesCount" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{ pluck "keepalivesCount" $local .Values.global.psql | first -}}
{{- end -}}

{{/*
Return tcp_user_timeout value
Defaults to nil
*/}}
{{- define "gitlab.psql.tcpUserTimeout" -}}
{{- $local := pluck "psql" $.Values | first -}}
{{ pluck "tcpUserTimeout" $local .Values.global.psql | first -}}
{{- end -}}

{{/* ######### annotations */}}

{{/*
Handles merging a set of service annotations
*/}}
{{- define "gitlab.serviceAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.service).annotations) .Values.global.service.annotations -}}
{{- if $allAnnotations }}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of deployment annotations
*/}}
{{- define "gitlab.deploymentAnnotations" -}}
{{- $allAnnotations := merge (default (dict) (default (dict) .Values.deployment).annotations) .Values.global.deployment.annotations -}}
{{- if $allAnnotations -}}
{{- toYaml $allAnnotations -}}
{{- end -}}
{{- end -}}

{{/* ######### labels */}}

{{/*
Handles merging a set of non-selector labels
*/}}
{{- define "gitlab.podLabels" -}}
{{- $allLabels := merge (default (dict) .Values.podLabels) .Values.global.pod.labels -}}
{{- if $allLabels -}}
{{-   range $key, $value := $allLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/*
Handles merging a set of labels for services
*/}}
{{- define "gitlab.serviceLabels" -}}
{{- $allLabels := merge (default (dict) .Values.serviceLabels) .Values.global.service.labels -}}
{{- if $allLabels -}}
{{-   range $key, $value := $allLabels }}
{{ $key }}: {{ $value | quote }}
{{-   end }}
{{- end -}}
{{- end -}}

{{/* selfsigned cert for when other options aren't provided */}}
{{- define "gitlab.wildcard-self-signed-cert-name" -}}
{{- default (printf "%s-wildcard-tls" .Release.Name) .Values.global.ingress.tls.secretName -}}
{{- end -}}

{{/*
Detect if `x.ingress.tls.secretName` are set
Return value if either `global.ingress.tls.secretName` or all components have `x.ingress.tls.secretName` set.
Return empty if not.

We're explicitly checking for an actual value being present, not the existence of map.
*/}}
{{- define "gitlab.ingress.tls.configured" -}}
{{/* Pull the value, if it exists */}}
{{- $global      := pluck "secretName" (default (dict) $.Values.global.ingress.tls) | first -}}
{{- $webservice  := pluck "secretName" $.Values.gitlab.webservice.ingress.tls | first -}}
{{- $registry    := pluck "secretName" $.Values.registry.ingress.tls | first -}}
{{- $minio       := pluck "secretName" $.Values.minio.ingress.tls | first -}}
{{- $pages       := pluck "secretName" ((index $.Values.gitlab "gitlab-pages").ingress).tls | first -}}
{{- $kas         := pluck "secretName" $.Values.gitlab.kas.ingress.tls | first -}}
{{- $smartcard   := pluck "smartcardSecretName" $.Values.gitlab.webservice.ingress.tls | first -}}
{{/* Set each item to configured value, or !enabled
     This works because `false` is the same as empty, so we'll use the value when `enabled: true`
     - default "" (not true) => ''
     - default "" (not false) => 'true'
     - default "valid" (not true) => 'valid'
     - default "valid" (not false) => 'true'
     Now, disabled sub-charts won't block this template from working properly.
*/}}
{{- $webservice  :=  default $webservice (not $.Values.gitlab.webservice.enabled) -}}
{{- $registry    :=  default $registry (not $.Values.registry.enabled) -}}
{{- $minio       :=  default $minio (not $.Values.global.minio.enabled) -}}
{{- $pages       :=  default $pages (not $.Values.global.pages.enabled) -}}
{{- $kas         :=  default $kas (not $.Values.global.kas.enabled) -}}
{{- $smartcard   :=  default $smartcard (not $.Values.global.appConfig.smartcard.enabled) -}}
{{/* Check that all enabled items have been configured */}}
{{- if or $global (and $webservice $registry $minio $pages $kas $smartcard) -}}
true
{{- end -}}
{{- end -}}

{{/*
Detect if `.Values.ingress.tls.enabled` is set
Returns `ingress.tls.enabled` if it is a boolean,
Returns `global.ingress.tls.enabled` if it is a boolean, and `ingress.tls.enabled` is not.
Return true in any other case.
*/}}
{{- define "gitlab.ingress.tls.enabled" -}}
{{- $globalSet := and (hasKey .Values.global.ingress "tls") (and (hasKey .Values.global.ingress.tls "enabled") (kindIs "bool" .Values.global.ingress.tls.enabled)) -}}
{{- $localSet := and (hasKey .Values.ingress "tls") (and (hasKey .Values.ingress.tls "enabled") (kindIs "bool" .Values.ingress.tls.enabled)) -}}
{{- if $localSet }}
{{-   .Values.ingress.tls.enabled }}
{{- else if $globalSet }}
{{-  .Values.global.ingress.tls.enabled }}
{{- else }}
{{-   true }}
{{- end -}}
{{- end -}}

{{/*
Detect if `.Values.ingress.enabled` is set
Returns `ingress.enabled` if it is a boolean,
Returns `global.ingress.enabled` if it is a boolean, and `ingress.enabled` is not.
Return true in any other case.
*/}}
{{- define "gitlab.ingress.enabled" -}}
{{- $globalSet := and (hasKey .Values.global.ingress "enabled") (kindIs "bool" .Values.global.ingress.enabled) -}}
{{- $localSet := and (hasKey .Values.ingress "enabled") (kindIs "bool" .Values.ingress.enabled) -}}
{{- if $localSet }}
{{-   .Values.ingress.enabled }}
{{- else if $globalSet }}
{{-  .Values.global.ingress.enabled }}
{{- else }}
{{-   true }}
{{- end -}}
{{- end -}}

{{/*
Override upstream redis chart naming
*/}}
{{- define "redis.secretName" -}}
{{ template "gitlab.redis.password.secret" . }}
{{- end -}}

{{/*
Override upstream redis secret key name
*/}}
{{- define "redis.secretPasswordKey" -}}
{{ template "gitlab.redis.password.key" . }}
{{- end -}}

{{/*
Return the fullname template for shared-secrets job.
*/}}
{{- define "shared-secrets.fullname" -}}
{{- printf "%s-shared-secrets" .Release.Name -}}
{{- end -}}

{{/*
Return the name template for shared-secrets job.
*/}}
{{- define "shared-secrets.name" -}}
{{- $sharedSecretValues := index .Values "shared-secrets" -}}
{{- default "shared-secrets" $sharedSecretValues.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified job name for shared-secrets.
*/}}
{{- define "shared-secrets.jobname" -}}
{{- $name := include "shared-secrets.fullname" . | trunc 55 | trimSuffix "-" -}}
{{- printf "%s-%s" $name ( include "gitlab.jobNameSuffix" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use for shared-secrets job
*/}}
{{- define "shared-secrets.serviceAccountName" -}}
{{- $sharedSecretValues := index .Values "shared-secrets" -}}
{{- if $sharedSecretValues.serviceAccount.create -}}
    {{ default (include "shared-secrets.fullname" .) $sharedSecretValues.serviceAccount.name }}
{{- else -}}
    {{ coalesce $sharedSecretValues.serviceAccount.name .Values.global.serviceAccount.name "default" }}
{{- end -}}
{{- end -}}

{{/*
Set if the default ServiceAccount token should be mounted by Kubernetes or not.

Default is 'false'
*/}}
{{- define "gitlab.automountServiceAccountToken" -}}
automountServiceAccountToken: {{ pluck "automountServiceAccountToken" .Values.serviceAccount .Values.global.serviceAccount | first }}
{{- end -}}

{{/*
Return a emptyDir definition for Volume declarations

Scope is the configuration of that emptyDir.
Only accepts sizeLimit and/or medium
*/}}
{{- define "gitlab.volume.emptyDir" -}}
{{- $values := pick . "sizeLimit" "medium" -}}
{{- if not $values -}}
emptyDir: {}
{{- else -}}
emptyDir: {{ toYaml $values | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Return upgradeCheck container specific securityContext template
*/}}
{{- define "upgradeCheck.containerSecurityContext" }}
{{- if .Values.upgradeCheck.containerSecurityContext }}
securityContext:
  {{- toYaml .Values.upgradeCheck.containerSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Return init container specific securityContext template
*/}}
{{- define "gitlab.init.containerSecurityContext" }}
{{- if .Values.init.containerSecurityContext }}
securityContext:
  {{- toYaml .Values.init.containerSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Return container specific securityContext template
*/}}
{{- define "gitlab.containerSecurityContext" }}
{{- if .Values.containerSecurityContext }}
securityContext:
  {{- toYaml .Values.containerSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Return a PodSecurityContext definition.

Usage:
  {{ include "gitlab.podSecurityContext" .Values.securityContext }}
*/}}
{{- define "gitlab.podSecurityContext" -}}
{{- $psc := . }}
{{- if $psc }}
securityContext:
{{-   if not (empty $psc.runAsUser) }}
  runAsUser: {{ $psc.runAsUser }}
{{-   end }}
{{-   if not (empty $psc.runAsGroup) }}
  runAsGroup: {{ $psc.runAsGroup }}
{{-   end }}
{{-   if not (empty $psc.fsGroup) }}
  fsGroup: {{ $psc.fsGroup }}
{{-   end }}
{{-   if not (empty $psc.fsGroupChangePolicy) }}
  fsGroupChangePolicy: {{ $psc.fsGroupChangePolicy }}
{{-   end }}
{{-   if $psc.seccompProfile }}
  seccompProfile:
    {{- toYaml $psc.seccompProfile | nindent 4 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return a PodSecurityContext definition that allows to it to run as root.

Usage:
  {{ include "gitlab.podSecurityContextRoot" .Values.securityContext }}
*/}}
{{- define "gitlab.podSecurityContextRoot" -}}
{{- $psc := . }}
{{- if $psc }}
securityContext:
{{-   if not (eq $psc.runAsUser nil) }}
  runAsUser: {{ $psc.runAsUser }}
{{-   end }}
{{-   if not (eq $psc.runAsGroup nil) }}
  runAsGroup: {{ $psc.runAsGroup }}
{{-   end }}
{{-   if not (eq $psc.fsGroup nil) }}
  fsGroup: {{ $psc.fsGroup }}
{{-   end }}
{{-   if not (eq $psc.fsGroupChangePolicy nil) }}
  fsGroupChangePolicy: {{ $psc.fsGroupChangePolicy }}
{{-   end }}
{{- end }}
{{- end -}}

{{/*
Returns `.Values.global.job.nameSuffixOverride` if set.

If `.Values.global.job.nameSuffixOverride` is not set, job names will be
suffixed by a hash that is based on the chart's app version and the chart's
values (which also might contain the global.gitlabVersion) to make sure that
the job is run at least once everytime GitLab is updated.

In order to make sure that the hash is stable for `helm template`
and `helm upgrade --install`, we need to remove the `local` block injected
by the template file `charts/gitlab/templates/_databaseDatamodel.tpl`.

This local block contains the values of the Helm "built-in object"
(see https://helm.sh/docs/chart_template_guide/builtin_objects) which would
result in different hash values due to fields like `Release.IsUpgrade`,
`Release.IsInstall` and especially `Release.Revision`.
*/}}
{{- define "gitlab.jobNameSuffix" -}}
{{-   if .Values.global.job.nameSuffixOverride -}}
{{-     tpl .Values.global.job.nameSuffixOverride . -}}
{{-   else -}}
{{-     $values := unset ( deepCopy .Values ) "local" -}}
{{-     printf "%s-%s-%s" .Chart.Version .Chart.AppVersion ( $values | toYaml | b64enc ) | sha256sum | trunc 7 -}}
{{-   end -}}
{{- end -}}

{{/*
Return a boolean value that indicates whether a given key exists in the provided environment
variables.

Usage: {{- include checkDuplicateKeyFromEnv (dict "keyToFind" "MY_KEY", "extraEnv" .Values.extraEnv, "extraEnvFrom"
.Values.extraEnvFrom) -}}
*/}}
{{- define "checkDuplicateKeyFromEnv" -}}
  {{- $keyToFind := .keyToFind -}}
  {{- $extraEnv := .extraEnv -}}
  {{- $extraEnvFrom := .extraEnvFrom -}}
  {{- $combinedKeys := merge $extraEnv $extraEnvFrom -}}
  
  {{ hasKey $combinedKeys $keyToFind }}
{{- end -}}