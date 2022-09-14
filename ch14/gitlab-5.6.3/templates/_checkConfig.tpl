{{/*
Template for checking configuration

The messages templated here will be combined into a single `fail` call. This creates a means for the user to receive all messages at one time, instead of a frustrating iterative approach.

- `define` a new template, prefixed `gitlab.checkConfig.`
- Check for known problems in configuration, and directly output messages (see message format below)
- Add a line to `gitlab.checkConfig` to include the new template.

Message format:

**NOTE**: The `if` statement preceding the block should _not_ trim the following newline (`}}` not `-}}`), to ensure formatting during output.

```
chart:
    MESSAGE
```
*/}}
{{/*
Compile all warnings into a single message, and call fail.

Due to gotpl scoping, we can't make use of `range`, so we have to add action lines.
*/}}
{{- define "gitlab.checkConfig" -}}
{{- $messages := list -}}
{{/* add templates here */}}
{{- $messages = append $messages (include "gitlab.checkConfig.contentSecurityPolicy" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.gitaly.storageNames" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.praefect.storageNames" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.gitaly.tls" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.sidekiq.queues.mixed" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.sidekiq.queues" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.sidekiq.timeout" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.sidekiq.routingRules" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.appConfig.maxRequestDurationSeconds" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.gitaly.extern.repos" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.geo.database" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.geo.secondary.database" .) -}}
{{- $messages = append $messages (include "gitlab.toolbox.replicas" .) -}}
{{- $messages = append $messages (include "gitlab.toolbox.backups.objectStorage.config.secret" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.multipleRedis" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.hostWhenNoInstall" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.postgresql.deprecatedVersion" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.postgresql.noPasswordFile" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.database.externalLoadBalancing" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.incomingEmail.microsoftGraph" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.serviceDesk" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.serviceDesk.microsoftGraph" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.sentry" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.registry.sentry.dsn" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.registry.notifications" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.registry.database" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.registry.gc" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.registry.migration" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.webservice.gracePeriod" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.objectStorage.consolidatedConfig" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.objectStorage.typeSpecificConfig" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.nginx.controller.extraArgs" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.nginx.clusterrole.scope" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.webservice.loadBalancer" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.smtp.openssl_verify_mode" .) -}}
{{- $messages = append $messages (include "gitlab.checkConfig.geo.registry.replication.primaryApiUrl" .) -}}
{{- /* prepare output */}}
{{- $messages = without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- /* print output */}}
{{- if $message -}}
{{-   printf "\nCONFIGURATION CHECKS:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Ensure that content_security_policy.directives is not empty
*/}}
{{- define "gitlab.checkConfig.contentSecurityPolicy" -}}
{{-   if eq true $.Values.global.appConfig.contentSecurityPolicy.enabled }}
{{-     if not (hasKey $.Values.global.appConfig.contentSecurityPolicy "directives") }}
contentSecurityPolicy:
    When configuring Content Security Policy, you must also configure its Directives.
    set `global.appConfig.contentSecurityPolicy.directives`
    See https://docs.gitlab.com/charts/charts/globals#content-security-policy
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.contentSecurityPolicy */}}

{{/*
Protect against problems in storage names within repositories configuration.
- Ensure that one (and only one) storage is named 'default'.
- Ensure no duplicates

Collects the list of storage names by rendering the 'gitlab.appConfig.repositories'
template, and grabbing any lines that start with exactly 4 spaces.
*/}}
{{- define "gitlab.checkConfig.gitaly.storageNames" -}}
{{- $errorMsg := list -}}
{{- $config := include "gitlab.appConfig.repositories" $ -}}
{{- $storages := list }}
{{- range (splitList "\n" $config) -}}
{{-   if (regexMatch "^    [^ ]" . ) -}}
{{-     $storages = append $storages (trim . | trimSuffix ":") -}}
{{-   end }}
{{- end }}
{{- if gt (len $storages) (len (uniq $storages)) -}}
{{-   $errorMsg = append $errorMsg (printf "Each storage name must be unique. Current storage names: %s" $storages | sortAlpha | join ", ") -}}
{{- end -}}
{{- if not (has "default" $storages) -}}
{{-   $errorMsg = append $errorMsg ("There must be one (and only one) storage named 'default'.") -}}
{{- end }}
{{- if not (empty $errorMsg) }}
gitaly:
{{- range $msg := $errorMsg }}
    {{ $msg }}
{{- end }}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.storageNames -}}

{{/*
Ensure that if a user is migrating to Praefect, none of the Praefect virtual storage
names are 'default', as it should already be used by the non-Praefect storage configuration.
*/}}
{{- define "gitlab.checkConfig.praefect.storageNames" -}}
{{- if and $.Values.global.gitaly.enabled $.Values.global.praefect.enabled (not $.Values.global.praefect.replaceInternalGitaly) -}}
{{-   range $i, $vs := $.Values.global.praefect.virtualStorages -}}
{{-     if eq $vs.name "default" -}}
praefect:
    Praefect is enabled, but `global.praefect.replaceInternalGitaly=false`. In this scenario,
    none of the Praefect virtual storage names can be 'default'. Please modify
    `global.praefect.virtualStorages[{{ $i }}].name`.
{{-     end }}
{{-   end }}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.praefect.storageNames" -}}

{{/*
Ensure a certificate is provided when Gitaly is enabled and is instructed to
listen over TLS */}}
{{- define "gitlab.checkConfig.gitaly.tls" -}}
{{- $errorMsg := list -}}
{{- if and $.Values.global.gitaly.enabled $.Values.global.gitaly.tls.enabled -}}
{{-   if $.Values.global.praefect.enabled -}}
{{-     range $i, $vs := $.Values.global.praefect.virtualStorages -}}
{{-       if not $vs.tlsSecretName }}
{{-         $errorMsg = append $errorMsg (printf "global.praefect.virtualStorages[%d].tlsSecretName not specified ('%s')" $i $vs.name) -}}
{{-       end }}
{{-     end }}
{{-   else }}
{{-     if not $.Values.global.gitaly.tls.secretName -}}
{{-       $errorMsg = append $errorMsg ("global.gitaly.tls.secretName not specified") -}}
{{-     end }}
{{-   end }}
{{- end }}
{{- if not (empty $errorMsg) }}
gitaly:
{{- range $msg := $errorMsg }}
    {{ $msg }}
{{- end }}
    This configuration is not supported.
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.tls */}}

{{/*
Ensure a certificate is provided when Praefect is enabled and is instructed to listen over TLS
*/}}
{{- define "gitlab.checkConfig.praefect.tls" -}}
{{- if and (and $.Values.global.praefect.enabled $.Values.global.praefect.tls.enabled) (not $.Values.global.praefect.tls.secretName) }}
praefect: server enabled with TLS, no TLS certificate provided
    It appears Praefect is specified to listen over TLS, but no certificate was specified.
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.praefect.tls */}}

{{/* Check configuration of Sidekiq - don't supply queues and negateQueues */}}
{{- define "gitlab.checkConfig.sidekiq.queues.mixed" -}}
{{- if .Values.gitlab.sidekiq.pods -}}
{{-   range $pod := .Values.gitlab.sidekiq.pods -}}
{{-     if and (hasKey $pod "queues") (hasKey $pod "negateQueues") }}
sidekiq: mixed queues
    It appears you've supplied both `queues` and `negateQueues` for the pod definition of `{{ $pod.name }}`. `negateQueues` is not usable if `queues` is provided. Please use only one.
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.queues.mixed */}}

{{/* Check configuration of Sidekiq - queues must be a string */}}
{{- define "gitlab.checkConfig.sidekiq.queues" -}}
{{- if .Values.gitlab.sidekiq.pods -}}
{{-   range $pod := .Values.gitlab.sidekiq.pods -}}
{{-     if and (hasKey $pod "queues") (ne (kindOf $pod.queues) "string") }}
sidekiq:
    The `queues` in pod definition `{{ $pod.name }}` is not a string.
{{-     else if and (hasKey $pod "negateQueues") (ne (kindOf $pod.negateQueues) "string") }}
sidekiq:
    The `negateQueues` in pod definition `{{ $pod.name }}` is not a string.
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.queues */}}

{{/*
Ensure that Sidekiq timeout is less than terminationGracePeriodSeconds
*/}}
{{- define "gitlab.checkConfig.sidekiq.timeout" -}}
{{-   range $i, $pod := $.Values.gitlab.sidekiq.pods -}}
{{-     $activeTimeout := int (default $.Values.gitlab.sidekiq.timeout $pod.timeout) }}
{{-     $activeTerminationGracePeriodSeconds := int (default $.Values.gitlab.sidekiq.deployment.terminationGracePeriodSeconds $pod.terminationGracePeriodSeconds) }}
{{-     if gt $activeTimeout $activeTerminationGracePeriodSeconds }}
sidekiq:
  You must set `terminationGracePeriodSeconds` ({{ $activeTerminationGracePeriodSeconds }}) longer than `timeout` ({{ $activeTimeout }}) for pod `{{ $pod.name }}`.
{{-     end }}
{{-   end }}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.timeout */}}

{{/*
Ensure that Sidekiq routingRules configuration is in a valid format
*/}}
{{- define "gitlab.checkConfig.sidekiq.routingRules" -}}
{{- $validRoutingRules := true -}}
{{- with $.Values.global.appConfig.sidekiq.routingRules }}
{{-   if not (kindIs "slice" .) }}
{{-     $validRoutingRules = false }}
{{-   else -}}
{{-     range $rule := . }}
{{-       if (not (kindIs "slice" $rule)) }}
{{-         $validRoutingRules = false }}
{{-       else if (ne (len $rule) 2) }}
{{-         $validRoutingRules = false }}
{{/*      The first item (routing query) must be a string */}}
{{-       else if not (kindIs "string" (index $rule 0)) }}
{{-         $validRoutingRules = false }}
{{/*      The second item (queue name) must be either a string or null */}}
{{-       else if not (or (kindIs "invalid" (index $rule 1)) (kindIs "string" (index $rule 1))) -}}
{{-         $validRoutingRules = false }}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- if eq false $validRoutingRules }}
sidekiq:
    The Sidekiq's routing rules list must be an ordered array of tuples of query and corresponding queue.
    See https://docs.gitlab.com/charts/charts/globals.html#sidekiq-routing-rules-settings
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sidekiq.routingRules */}}

{{/*
Ensure a database is configured when using Geo
listen over TLS */}}
{{- define "gitlab.checkConfig.geo.database" -}}
{{- with $.Values.global -}}
{{- if eq true .geo.enabled -}}
{{-   if not .psql.host }}
geo: no database provided
    It appears Geo was configured but no database was provided. Geo behaviors require external databases. Ensure `global.psql.host` is set.
{{    end -}}
{{-   if not .psql.password.secret }}
geo: no database password provided
    It appears Geo was configured, but no database password was provided. Geo behaviors require external databases. Ensure `global.psql.password.secret` is set.
{{   end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.geo.database */}}

{{/*
Ensure a database is configured when using Geo secondary
listen over TLS */}}
{{- define "gitlab.checkConfig.geo.secondary.database" -}}
{{- with $.Values.global.geo -}}
{{- if include "gitlab.geo.secondary" $ }}
{{-   if not .psql.host }}
geo: no secondary database provided
    It appears Geo was configured with `role: secondary`, but no database was provided. Geo behaviors require external databases. Ensure `global.geo.psql.host` is set.
{{    end -}}
{{-   if not .psql.password.secret }}
geo: no secondary database password provided
    It appears Geo was configured with `role: secondary`, but no database password was provided. Geo behaviors require external databases. Ensure `global.geo.psql.password.secret` is set.
{{    end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.geo.secondary.database */}}

{{/*
Ensure the provided global.appConfig.maxRequestDurationSeconds value is smaller than
webservice's worker timeout */}}
{{- define "gitlab.checkConfig.appConfig.maxRequestDurationSeconds" -}}
{{- $maxDuration := $.Values.global.appConfig.maxRequestDurationSeconds }}
{{- if $maxDuration }}
{{- $workerTimeout := $.Values.global.webservice.workerTimeout }}
{{- if not (lt $maxDuration $workerTimeout) }}
gitlab: maxRequestDurationSeconds should be smaller than Webservice's worker timeout
        The current value of global.appConfig.maxRequestDurationSeconds ({{ $maxDuration }}) is greater than or equal to global.webservice.workerTimeout ({{ $workerTimeout }}) while it should be a lesser value.
{{- end }}
{{- end }}
{{- end }}
{{/* END gitlab.checkConfig.appConfig.maxRequestDurationSeconds */}}

{{/* Check configuration of Gitaly external repos*/}}
{{- define "gitlab.checkConfig.gitaly.extern.repos" -}}
{{-   if (and (not .Values.global.gitaly.enabled) (not .Values.global.gitaly.external) ) }}
gitaly:
    external Gitaly repos needs to be specified if global.gitaly.enabled is not set
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.extern.repos */}}

{{/*
Ensure that a valid object storage config secret is provided.
*/}}
{{- define "gitlab.toolbox.backups.objectStorage.config.secret" -}}
{{-   if or .Values.gitlab.toolbox.backups.objectStorage.config (not (or .Values.global.minio.enabled .Values.global.appConfig.object_store.enabled)) (eq .Values.gitlab.toolbox.backups.objectStorage.backend "gcs") }}
{{-     if not .Values.gitlab.toolbox.backups.objectStorage.config.secret -}}
toolbox:
    A valid object storage config secret is needed for backups.
    Please configure it via `gitlab.toolbox.backups.objectStorage.config.secret`.
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.toolbox.backups.objectStorage.config.secret */}}

{{/*
Ensure that gitlab/toolbox is not configured with `replicas` > 1 if
persistence is enabled.
*/}}
{{- define "gitlab.toolbox.replicas" -}}
{{-   $replicas := index $.Values.gitlab "toolbox" "replicas" | int -}}
{{-   if and (gt $replicas 1) (index $.Values.gitlab "toolbox" "persistence" "enabled") -}}
toolbox: replicas is greater than 1, with persistence enabled.
    It appear that `gitlab/toolbox` has been configured with more than 1 replica, but also with a PersistentVolumeClaim. This is not supported. Please either reduce the replicas to 1, or disable persistence.
{{-   end -}}
{{- end -}}
{{/* END gitlab.toolbox.replicas */}}

{{/*
Ensure that `redis.install: false` if configuring multiple Redis instances
*/}}
{{- define "gitlab.checkConfig.multipleRedis" -}}
{{/* "cache" "sharedState" "queues" "actioncable" */}}
{{- $x := dict "count" 0 -}}
{{- range $redis := list "cache" "sharedState" "queues" "actioncable" -}}
{{-   if hasKey $.Values.global.redis $redis -}}
{{-     $_ := set $x "count" ( add1 $x.count ) -}}
{{-    end -}}
{{- end -}}
{{- if and .Values.redis.install ( lt 0 $x.count ) }}
redis:
  If configuring multiple Redis servers, you can not use the in-chart Redis server. Please see https://docs.gitlab.com/charts/charts/globals#configure-redis-settings
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.multipleRedis */}}

{{/*
Ensure that `global.redis.host: <hostname>` is present if `redis.install: false`
*/}}
{{- define "gitlab.checkConfig.hostWhenNoInstall" -}}
{{-   if and (not .Values.redis.install) (not .Values.global.redis.host) }}
redis:
  You've disabled the installation of Redis. When using an external Redis, you must populate `global.redis.host`. Please see https://docs.gitlab.com/charts/advanced/external-redis/
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.hostWhenNoInstall */}}

{{/*
Ensure that `postgresql.image.tag` meets current requirements
*/}}
{{- define "gitlab.checkConfig.postgresql.deprecatedVersion" -}}
{{-   $imageTag := .Values.postgresql.image.tag -}}
{{-   $majorVersion := (split "." (split "-" ($imageTag | toString))._0)._0 | int -}}
{{-   if or (eq $majorVersion 0) (lt $majorVersion 12) -}}
postgresql:
  Image tag is "{{ $imageTag }}".
{{-     if (eq $majorVersion 0) }}
  Image tag is malformed. It should begin with the numeric major version.
{{-     else if (lt $majorVersion 12) }}
  PostgreSQL 11 and earlier is not supported in GitLab 14. The minimum required version is PostgreSQL 12.
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.postgresql.deprecatedVersion */}}


{{/*
Ensure that if `psql.password.useSecret` is set to false, a path to the password file is provided
*/}}
{{- define "gitlab.checkConfig.postgresql.noPasswordFile" -}}
{{- $errorMsg := list -}}
{{- $subcharts := pick .Values.gitlab "geo-logcursor" "gitlab-exporter" "migrations" "sidekiq" "toolbox" "webservice" -}}
{{- range $name, $sub := $subcharts -}}
{{-   $useSecret := include "gitlab.boolean.local" (dict "local" (pluck "useSecret" (index $sub "psql" "password") | first) "global" $.Values.global.psql.password.useSecret "default" true) -}}
{{-   if and (not $useSecret) (not (pluck "file" (index $sub "psql" "password") ($.Values.global.psql.password) | first)) -}}
{{-      $errorMsg = append $errorMsg (printf "%s: If `psql.password.useSecret` is set to false, you must specify a value for `psql.password.file`." $name) -}}
{{-   end -}}
{{-   if and (not $useSecret) ($.Values.postgresql.install) -}}
{{-      $errorMsg = append $errorMsg (printf "%s: PostgreSQL can not be deployed with this chart when using `psql.password.useSecret` is false." $name) -}}
{{-   end -}}
{{- end -}}
{{- if not (empty $errorMsg) }}
postgresql:
{{- range $msg := $errorMsg }}
    {{ $msg }}
{{- end }}
    This configuration is not supported.
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.postgresql.noPasswordFile */}}

{{/*
Ensure that `postgresql.install: false` when `global.psql.load_balancing` defined
*/}}
{{- define "gitlab.checkConfig.database.externalLoadBalancing" -}}
{{- if hasKey .Values.global.psql "load_balancing" -}}
{{-   with .Values.global.psql.load_balancing -}}
{{-     if and $.Values.postgresql.install (kindIs "map" .) }}
postgresql:
    It appears PostgreSQL is set to install, but database load balancing is also enabled. This configuration is not supported.
    See https://docs.gitlab.com/charts/charts/globals#configure-postgresql-settings
{{-     end -}}
{{-     if not (kindIs "map" .) }}
postgresql:
    It appears database load balancing is desired, but the current configuration is not supported.
    See https://docs.gitlab.com/charts/charts/globals#configure-postgresql-settings
{{-     end -}}
{{-     if and (not (hasKey . "discover") ) (not (hasKey . "hosts") ) }}
postgresql:
    It appears database load balancing is desired, but the current configuration is not supported.
    You must specify `load_balancing.hosts` or `load_balancing.discover`.
    See https://docs.gitlab.com/charts/charts/globals#configure-postgresql-settings
{{-     end -}}
{{-     if and (hasKey . "hosts") (not (kindIs "slice" .hosts) ) }}
postgresql:
    Database load balancing using `hosts` is configured, but does not appear to be a list.
    See https://docs.gitlab.com/charts/charts/globals#configure-postgresql-settings
    Current format: {{ kindOf .hosts }}
{{-     end -}}
{{-     if and (hasKey . "discover") (not (kindIs "map" .discover)) }}
postgresql:
    Database load balancing using `discover` is configured, but does not appear to be a map.
    See https://docs.gitlab.com/charts/charts/globals#configure-postgresql-settings
    Current format: {{ kindOf .discover }}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.database.externalLoadBalancing */}}

{{/*
Ensure that tenantId and clientId are set if Microsoft Graph settings are used in incomingEmail
*/}}
{{- define "gitlab.checkConfig.incomingEmail.microsoftGraph" -}}
{{- with $.Values.global.appConfig.incomingEmail }}
{{-   if (and .enabled (eq .inboxMethod "microsoft_graph")) }}
{{-     if not .tenantId }}
incomingEmail:
    When configuring incoming email with Microsoft Graph, be sure to specify the tenant ID.
    See https://docs.gitlab.com/ee/administration/incoming_email.html#microsoft-graph
{{-     end -}}
{{-     if not .clientId }}
incomingEmail:
    When configuring incoming email with Microsoft Graph, be sure to specify the client ID.
    See https://docs.gitlab.com/ee/administration/incoming_email.html#microsoft-graph
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.incomingEmail.microsoftGraph */}}

{{/*
Ensure that incomingEmail is enabled too if serviceDesk is enabled
*/}}
{{- define "gitlab.checkConfig.serviceDesk" -}}
{{-   if $.Values.global.appConfig.serviceDeskEmail.enabled }}
{{-     if not $.Values.global.appConfig.incomingEmail.enabled }}
serviceDesk:
    When configuring Service Desk email, you must also configure incoming email.
    See https://docs.gitlab.com/charts/charts/globals#incoming-email-settings
{{-     end -}}
{{-     if (not (and (contains "+%{key}@" $.Values.global.appConfig.incomingEmail.address) (contains "+%{key}@" $.Values.global.appConfig.serviceDeskEmail.address))) }}
serviceDesk:
    When configuring Service Desk email, both incoming email and Service Desk email address must contain the "+%{key}" tag.
    See https://docs.gitlab.com/ee/user/project/service_desk.html#using-custom-email-address
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.serviceDesk */}}

{{/*
Ensure that tenantId and clientId are set if Microsoft Graph settings are used in serviceDesk
*/}}
{{- define "gitlab.checkConfig.serviceDesk.microsoftGraph" -}}
{{- with $.Values.global.appConfig.serviceDesk }}
{{-   if (and .enabled (eq .inboxMethod "microsoft_graph")) }}
{{-     if not .tenantId }}
incomingEmail:
    When configuring Service Desk with Microsoft Graph, be sure to specify the tenant ID.
    See https://docs.gitlab.com/ee/user/project/service_desk.html#microsoft-graph
{{-     end -}}
{{-     if not .clientId }}
incomingEmail:
    When configuring Service Desk with Microsoft Graph, be sure to specify the client ID.
    See https://docs.gitlab.com/ee/user/project/service_desk.html#microsoft-graph
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.serviceDesk.microsoftGraph */}}

{{/*
Ensure that sentry has a DSN configured if enabled
*/}}
{{- define "gitlab.checkConfig.sentry" -}}
{{-   if $.Values.global.appConfig.sentry.enabled }}
{{-     if (not (or $.Values.global.appConfig.sentry.dsn $.Values.global.appConfig.sentry.clientside_dsn)) }}
sentry:
    When enabling sentry, you must configure at least one DSN.
    See https://docs.gitlab.com/charts/charts/globals.html#sentry-settings
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.sentry */}}

{{/*
Ensure that registry's sentry has a DSN configured if enabled
*/}}
{{- define "gitlab.checkConfig.registry.sentry.dsn" -}}
{{-   if $.Values.registry.reporting.sentry.enabled }}
{{-     if not $.Values.registry.reporting.sentry.dsn }}
registry:
    When enabling sentry, you must configure at least one DSN.
    See https://docs.gitlab.com/charts/charts/registry#reporting
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.sentry.dsn */}}

{{/*
Ensure Registry notifications settings are in global scope
*/}}
{{- define "gitlab.checkConfig.registry.notifications" }}
{{- if hasKey $.Values.registry "notifications" }}
Registry: Notifications should be defined in the global scope. Use `global.registry.notifications` setting instead of `registry.notifications`.
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.notifications */}}

{{/*
Ensure Registry database is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.database" -}}
{{-   if $.Values.registry.database.enabled }}
{{-     $validSSLModes := list "require" "disable" "allow" "prefer" "require" "verify-ca" "verify-full" -}}
{{-     if not (has $.Values.registry.database.sslmode $validSSLModes) }}
registry:
    Invalid SSL mode "{{ .Values.registry.database.sslmode }}".
    Valid values are: {{ join ", " $validSSLModes }}.
    See https://docs.gitlab.com/charts/charts/registry#database
{{-     end -}}
{{-     $pgImageTag := .Values.postgresql.image.tag -}}
{{-     $pgMajorVersion := (split "." (split "-" ($pgImageTag | toString))._0)._0 | int -}}
{{-     if lt $pgMajorVersion 12 -}}
registry:
    Invalid PostgreSQL version "{{ $pgImageTag }}".
    PostgreSQL 12 is the minimum required version for the registry database.
    See https://docs.gitlab.com/charts/charts/registry#database
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.database */}}

{{/*
Ensure Registry migration is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.migration" -}}
{{-   if and $.Values.registry.migration.enabled (not $.Values.registry.database.enabled) }}
registry:
    Enabling migration mode requires the metadata database to be enabled.
    See https://docs.gitlab.com/charts/charts/registry#migration
{{-   end -}}
{{-   if and $.Values.registry.migration.disablemirrorfs (not $.Values.registry.database.enabled) }}
registry:
    Disabling filesystem metadata requires the metadata database to be enabled.
    See https://docs.gitlab.com/charts/charts/registry#migration
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.migration */}}

{{/*
Ensure Registry online garbage collection is configured properly and dependencies are met
*/}}
{{- define "gitlab.checkConfig.registry.gc" -}}
{{-   if not (or $.Values.registry.gc.disabled $.Values.registry.database.enabled) }}
registry:
    Enabling online garbage collection requires the metadata database to be enabled.
    See https://docs.gitlab.com/charts/charts/registry#gc
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.registry.gc */}}

{{/*
Ensure terminationGracePeriodSeconds is longer than blackoutSeconds
*/}}
{{- define "gitlab.checkConfig.webservice.gracePeriod" -}}
{{-   $terminationGracePeriodSeconds := default 30 .Values.gitlab.webservice.deployment.terminationGracePeriodSeconds | int -}}
{{-   $blackoutSeconds := .Values.gitlab.webservice.shutdown.blackoutSeconds | int -}}
{{- if lt $terminationGracePeriodSeconds $blackoutSeconds }}
You must set terminationGracePeriodSeconds ({{ $terminationGracePeriodSeconds }}) longer than blackoutSeconds ({{ $blackoutSeconds }})
{{  end -}}
{{- end -}}
{{/* END gitlab.checkConfig.webservice.gracePeriod */}}

{{/*
Ensure consolidate and type-specific object store configuration are not mixed.
*/}}
{{- define "gitlab.checkConfig.objectStorage.consolidatedConfig" -}}
{{-   if $.Values.global.appConfig.object_store.enabled -}}
{{-     $problematicTypes := list -}}
{{-     range $objectTypes := list "artifacts" "lfs" "uploads" "packages" "externalDiffs" "terraformState" "pseudonymizer" "dependencyProxy" -}}
{{-       if hasKey $.Values.global.appConfig . -}}
{{-         $objectProps := index $.Values.global.appConfig . -}}
{{-         if (and (index $objectProps "enabled") (or (not (empty (index $objectProps "connection"))) (empty (index $objectProps "bucket")))) -}}
{{-           $problematicTypes = append $problematicTypes . -}}
{{-         end -}}
{{-       end -}}
{{-     end -}}
{{-     if not (empty $problematicTypes) -}}
When consolidated object storage is enabled, for each item `bucket` must be specified and the `connection` must be empty. Check the following object storage configuration(s): {{ join "," $problematicTypes }}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.objectStorage.consolidatedConfig */}}

{{- define "gitlab.checkConfig.objectStorage.typeSpecificConfig" -}}
{{-   if and (not $.Values.global.minio.enabled) (not $.Values.global.appConfig.object_store.enabled) -}}
{{-     $problematicTypes := list -}}
{{-     range $objectTypes := list "artifacts" "lfs" "uploads" "packages" "externalDiffs" "terraformState" "pseudonymizer" "dependencyProxy" -}}
{{-       if hasKey $.Values.global.appConfig . -}}
{{-         $objectProps := index $.Values.global.appConfig . -}}
{{-         if and (index $objectProps "enabled") (empty (index $objectProps "connection")) -}}
{{-           $problematicTypes = append $problematicTypes . -}}
{{-         end -}}
{{-       end -}}
{{-     end -}}
{{-     if not (empty $problematicTypes) -}}
When type-specific object storage is enabled the `connection` property can not be empty. Check the following object storage configuration(s): {{ join "," $problematicTypes }}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.objectStorage.typeSpecificConfig */}}

{{- define "gitlab.checkConfig.nginx.controller.extraArgs" -}}
{{-   if (index $.Values "nginx-ingress").enabled -}}
{{-     if hasKey (index $.Values "nginx-ingress").controller.extraArgs "force-namespace-isolation" -}}
nginx-ingress:
  `nginx-ingress.controller.extraArgs.force-namespace-isolation` was previously set by default in the GitLab chart's values.yaml file,
  but has since been deprecated upon the upgrade to NGINX 0.41.2 (upstream chart version 3.11.1).
  Please remove the `force-namespace-isolation` key.
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END "gitlab.checkConfig.nginx.controller" */}}

{{- define "gitlab.checkConfig.nginx.clusterrole.scope" -}}
{{-   if (index $.Values "nginx-ingress").rbac.scope -}}
nginx-ingress:
  'rbac.scope' should be false. Namespaced IngressClasses do not exist.
  See https://github.com/kubernetes/ingress-nginx/issues/7519
{{-   end -}}
{{- end -}}
{{/* END "gitlab.checkConfig.nginx.clusterrole" */}}

{{/*
Ensure that when type is set to LoadBalancer that loadBalancerSourceRanges are set
*/}}
{{- define "gitlab.checkConfig.webservice.loadBalancer" -}}
{{-   if .Values.gitlab.webservice.enabled -}}
{{-     $serviceType := .Values.gitlab.webservice.service.type -}}
{{-     $numDeployments := len .Values.gitlab.webservice.deployments -}}
{{-     if (and (eq $serviceType "LoadBalancer") (gt $numDeployments 1)) }}
webservice:
    It is not currently recommended to set a service type of `LoadBalancer` with multiple deployments defined.
    Instead, use a global `service.type` of `ClusterIP` and override `service.type` in each deployment.
{{-     end -}}
{{-     range $name, $deployment := .Values.gitlab.webservice.deployments -}}
{{-     $serviceType := $deployment.service.type -}}
{{-     $loadBalancerSourceRanges := $deployment.service.loadBalancerSourceRanges -}}
{{-       if (and (eq $serviceType "LoadBalancer") (empty ($loadBalancerSourceRanges))) }}
webservice:
    It is not currently recommended to set a service type of `{{ $serviceType }}` on a public exposed network without restrictions, please add `service.loadBalancerSourceRanges` to limit access to the service of the `{{ $name }}` deployment.
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.webservice.loadBalancer */}}

{{/*
Ensure that a correct value is provided for
`global.smtp.openssl_verify_mode`.
*/}}
{{- define "gitlab.checkConfig.smtp.openssl_verify_mode" -}}
{{-   $opensslVerifyModes := list "none" "peer" "client_once" "fail_if_no_peer_cert" -}}
{{-   if .Values.global.smtp.openssl_verify_mode -}}
{{-     if not (has .Values.global.smtp.openssl_verify_mode $opensslVerifyModes) }}
smtp:
    "{{ .Values.global.smtp.openssl_verify_mode }}" is not a valid value for `global.smtp.openssl_verify_mode`.
    Valid values are: {{ join ", " $opensslVerifyModes }}.
{{-     end }}
{{-   end }}
{{- end -}}
{{/* END gitlab.checkConfig.smtp.openssl_verify_mode */}}


{{/*
Ensure that when Registry replication is enabled for Geo, a primary API URL is specified.
*/}}
{{- define "gitlab.checkConfig.geo.registry.replication.primaryApiUrl" -}}
{{- if and (eq true .Values.global.geo.enabled) (and (eq .Values.global.geo.role "secondary") (eq true .Values.global.geo.registry.replication.enabled)) -}}
{{-   if not .Values.global.geo.registry.replication.primaryApiUrl }}
geo:
    Registry replication is enabled for GitLab Geo, but no primary API URL is specified. Please specify a value for `global.geo.registry.replication.primaryApiUrl`.
{{-   end -}}
{{- end -}}
{{- end -}}
