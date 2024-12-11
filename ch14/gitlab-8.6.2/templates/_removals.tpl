{{/*
Template for blocking upgrades if removed features are configured.

The messages templated here will be combined into a single `fail` call. This creates a means for the user to receive all messages at one time, in place a frustrating iterative approach.

- `define` a new template, prefixed `gitlab.removal.`
- Check for deprecated values / patterns, and directly output messages (see message format below)
- Add a line to `gitlab.removals` to include the new template.

Message format:

**NOTE**: The `if` statement preceding the block should _not_ trim the following newline (`}}` not `-}}`), to ensure formatting during output.

```
chart:
    MESSAGE
```
*/}}
{{/*
Compile all deprecations into a single message, and call fail.

Due to gotpl scoping, we can't make use of `range`, so we have to add action lines.
*/}}
{{- define "gitlab.removals" -}}
{{- $removals := list -}}
{{/* add templates here */}}
{{- $removals = append $removals (include "gitlab.removal.rails.appConfig" .) -}}
{{- $removals = append $removals (include "gitlab.removal.minio" .) -}}
{{- $removals = append $removals (include "gitlab.removal.registryStorage" .) -}}
{{- $removals = append $removals (include "gitlab.removal.registryHttpSecret" .) -}}
{{- $removals = append $removals (include "gitlab.removal.registry.replicas" .) -}}
{{- $removals = append $removals (include "gitlab.removal.registry.updateStrategy" .) -}}
{{- $removals = append $removals (include "gitlab.removal.webservice.omniauth" .) -}}
{{- $removals = append $removals (include "gitlab.removal.webservice.ldap" .) -}}
{{- $removals = append $removals (include "gitlab.removal.webservice.webServer.unicorn" .) -}}
{{- $removals = append $removals (include "gitlab.removal.global.appConfig.ldap.password" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.cronJobs" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.updateStrategy" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.pods.updateStrategy" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.cluster" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.pods.cluster" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.queueSelector" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.pods.queueSelector" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.negateQueues" .) -}}
{{- $removals = append $removals (include "gitlab.removal.sidekiq.pods.negateQueues" .) -}}
{{- $removals = append $removals (include "gitlab.removal.local.kubectl" .) -}}
{{- $removals = append $removals (include "gitlab.removal.gitlab.gitaly.enabled" .) -}}
{{- $removals = append $removals (include "gitlab.removal.initContainerImage" .) -}}
{{- $removals = append $removals (include "external.removal.initContainerImage" .) -}}
{{- $removals = append $removals (include "external.removal.initContainerPullPolicy" .) -}}
{{- $removals = append $removals (include "gitlab.removal.redis-ha.enabled" .) -}}
{{- $removals = append $removals (include "gitlab.removal.redis.enabled" .) -}}
{{- $removals = append $removals (include "gitlab.removal.gitlab.webservice.service.configuration" .) -}}
{{- $removals = append $removals (include "gitlab.removal.gitlab.gitaly.serviceName" .) -}}
{{- $removals = append $removals (include "gitlab.removal.global.psql.pool" .) -}}
{{- $removals = append $removals (include "gitlab.removal.global.appConfig.extra.piwik" .) -}}
{{- $removals = append $removals (include "gitlab.removal.global.geo.registry.syncEnabled" .) -}}
{{- $removals = append $removals (include "certmanager.removal.createCustomResource" .) -}}
{{- $removals = append $removals (include "gitlab.removal.global.imagePullPolicy" .) -}}
{{- $removals = append $removals (include "gitlab.removal.task-runner" .) -}}
{{- $removals = append $removals (include "gitlab.removal.gitaly-gitconfig-volume" .) -}}
{{- $removals = append $removals (include "gitlab.removal.hpa.legacyCpuTarget" .) -}}
{{- $removals = append $removals (include "gitlab.removal.hpa.behaviorMispell" .) -}}
{{- $removals = append $removals (include "gitlab.removal.global.grafana" .) -}}
{{- $removals = append $removals (include "gitlab.removal.busybox" .) -}}
{{- $removals = append $removals (include "gitlab.removal.kas.privateApi.tls" .) -}}

{{- /* we're ready to deprecate top-level registry entries for workhorse and sidekiq, but not enforcing yet */ -}}
{{- /* $removals = append $removals (include "gitlab.removal.registry.topLevel" .) */ -}}

{{- /* prepare output */}}
{{- $removals = without $removals "" -}}
{{- $message := join "\n" $removals -}}

{{- /* print output */}}
{{- if $message -}}
{{-   printf "\nREMOVALS:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Migration of rails shared lfs/artifacts/uploads blocks to globals */}}
{{- define "gitlab.removal.rails.appConfig" -}}
{{- range $chart := list "webservice" "sidekiq" "toolbox" -}}
{{-   if index $.Values.gitlab $chart -}}
{{-     range $i, $block := list "lfs" "artifacts" "uploads" -}}
{{-       if hasKey (index $.Values.gitlab $chart) $block }}
{{-         with $config := index $.Values.gitlab $chart $block -}}
{{-           range $item := list "enabled" "bucket" "proxy_download" -}}
{{-             if hasKey $config $item }}
gitlab.{{ $chart }}:
    `{{ $block }}.{{ $item }}` has been moved to global. Please remove `{{ $block }}.{{ $item }}` from your properties, and set `global.appConfig.{{ $block }}.{{ $item }}`
{{-             end -}}
{{-           end -}}
{{-           if .connection -}}
{{-             if without (keys .connection) "secret" "key" | len | ne 0 }}
gitlab.{{ $chart }}:
    The `{{ $block }}.connection` declarations have been moved into a secret. Please create a secret with these contents, and set `global.appConfig.{{ $block }}.connection.secret`
{{-             end -}}
{{-           end -}}
{{-         end -}}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}

{{/* Deprecation behaviors for global configuration of Minio */}}
{{- define "gitlab.removal.minio" -}}
{{- if ( hasKey .Values.minio "enabled" ) }}
minio:
    Chart-local `enabled` property has been moved to global. Please remove `minio.enabled` from your properties, and set `global.minio.enabled` instead.
{{- end -}}
{{- if .Values.registry.minio -}}
{{-   if ( hasKey .Values.registry.minio "enabled" ) }}
registry:
    Chart-local configuration of Minio features has been moved to global. Please remove `registry.minio.enabled` from your properties, and set `global.minio.enabled` instead.
{{-   end -}}
{{- end -}}
{{- if .Values.gitlab.webservice.minio -}}
{{-   if ( hasKey .Values.gitlab.webservice.minio "enabled" ) }}
gitlab.webservice:
    Chart-local configuration of Minio features has been moved to global. Please remove `gitlab.webservice.minio.enabled` from your properties, and set `global.minio.enabled` instead.
{{-   end -}}
{{- end -}}
{{- if .Values.gitlab.sidekiq.minio -}}
{{-   if ( hasKey .Values.gitlab.sidekiq.minio "enabled" ) }}
gitlab.sidekiq:
    Chart-local configuration of Minio features has been moved to global. Please remove `gitlab.sidekiq.minio.enabled` from your properties, and set `global.minio.enabled` instead.
{{-   end -}}
{{- end -}}
{{- if index .Values.gitlab "toolbox" "minio" -}}
{{-   if ( hasKey ( index .Values.gitlab "toolbox" "minio" ) "enabled" ) }}
gitlab.toolbox:
    Chart-local configuration of Minio features has been moved to global. Please remove `gitlab.toolbox.minio.enabled` from your properties, and set `global.minio.enabled` instead.
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END deprecate.minio */}}

{{/* Migration of Registry `storage` dict to a secret */}}
{{- define "gitlab.removal.registryStorage" -}}
{{- if .Values.registry.storage -}}
{{-   $keys := without (keys .Values.registry.storage) "secret" "key" "extraKey" "redirect" -}}
{{-   if len $keys | ne 0 }}
registry:
    The `storage` property has been moved into a secret. Please create a secret with these contents, and set `storage.secret`.
{{-   end -}}
{{- end -}}
{{- end -}}

{{/* Migration of Registry `httpSecret` property to secret */}}
{{- define "gitlab.removal.registryHttpSecret" -}}
{{- if .Values.registry.httpSecret -}}
registry:
    The `httpSecret` property has been moved into a secret. Please create a secret with these contents, and set `global.registry.httpSecret.secret` and `global.registry.httpSecret.key`.
{{- end -}}
{{- end -}}

{{/* Migration of Registry `minReplicas` and `maxReplicas` to `hpa.*` */}}
{{- define "gitlab.removal.registry.replicas" -}}
{{- if or (hasKey .Values.registry "minReplicas") (hasKey .Values.registry "maxReplicas") -}}
registry:
    The `minReplicas` property has been moved under the hpa object. Please create a configuration with the new path: `registry.hpa.minReplicas`.
    The `maxReplicas` property has been moved under the hpa object. Please create a configuration with the new path: `registry.hpa.maxReplicas`.
{{- end -}}
{{- end -}}
{{/* END deprecate.registry.replicas */}}

{{/* Deprecation behaviors for configuration of Omniauth */}}
{{- define "gitlab.removal.webservice.omniauth" -}}
{{- if hasKey .Values.gitlab.webservice "omniauth" -}}
webservice:
    Chart-local configuration of Omniauth has been moved to global. Please remove `webservice.omniauth.*` settings from your properties, and set `global.appConfig.omniauth.*` instead.
{{- end -}}
{{- end -}}
{{/* END deprecate.webservice.omniauth */}}

{{/* Deprecation behaviors for configuration of LDAP */}}
{{- define "gitlab.removal.webservice.ldap" -}}
{{- if hasKey .Values.gitlab.webservice "ldap" -}}
webservice:
    Chart-local configuration of LDAP has been moved to global. Please remove `webservice.ldap.*` settings from your properties, and set `global.appConfig.ldap.*` instead.
{{- end -}}
{{- end -}}
{{/* END deprecate.webservice.ldap */}}

{{- define "gitlab.removal.global.appConfig.ldap.password" -}}
{{- if .Values.global.appConfig.ldap.servers -}}
{{-   $hasPlaintextPassword := dict -}}
{{-   range $name, $config := .Values.global.appConfig.ldap.servers -}}
{{-     if and (hasKey $config "password") (kindIs "string" $config.password) -}}
{{-       $_ := set $hasPlaintextPassword "true" "true" -}}
{{-     end -}}
{{-   end -}}
{{-   if hasKey $hasPlaintextPassword "true" -}}
global.appConfig.ldap:
     Plain-text configuration of LDAP passwords has been removed in favor of secret configuration. Please create a secret containing the password, and set `password.secret` and `password.key`.
{{-   end -}}
{{- end -}}
{{- end -}}{{/* "gitlab.removal.global.appConfig.ldap.password" */}}

{{/* Deprecation behaviors for configuration of cron jobs */}}
{{- define "gitlab.removal.sidekiq.cronJobs" -}}
{{- if hasKey .Values.gitlab.sidekiq "cron_jobs" -}}
sidekiq:
    Chart-local configuration of cron jobs has been moved to global. Please remove `sidekiq.cron_jobs.*` settings from your properties, and set `global.appConfig.cron_jobs.*` instead.
{{- end -}}
{{- end -}}
{{/* END deprecate.sidekiq.cronJobs */}}

{{/* Deprecation behaviors for configuration of local kubectl images */}}
{{- define "gitlab.removal.local.kubectl" -}}
{{- range $chart := list "certmanager-issuer" "shared-secrets" -}}
{{-   if hasKey (index $.Values $chart) "image" -}}
{{ $chart }}:
    Chart-local configuration of kubectl image has been moved to global. Please remove `{{ $chart }}.image.*` settings from your properties, and set `global.kubectl.image.*` instead.
{{-     if and (eq $chart "shared-secrets") (hasKey (index $.Values $chart "image") "pullSecrets") }}
    If you need to set `pullSecrets` of the self-sign image, please use `shared-secrets.selfsign.image.pullSecrets` instead.
{{     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.local.kubectl */}}

{{/* Deprecation behaviors for configuration of Gitaly */}}
{{- define "gitlab.removal.gitlab.gitaly.enabled" -}}
{{-   if hasKey .Values.gitlab.gitaly "enabled" -}}
gitlab:
    Chart-local configuration of Gitaly features has been moved to global. Please remove `gitlab.gitaly.enabled` from your properties, and set `global.gitaly.enabled` instead.
{{-   end -}}
{{- end -}}
{{/* END gitlab.removal.gitaly.enabled */}}

{{/* Deprecation behavious for configuration of initContainer images of gitlab sub-charts */}}
{{- define "gitlab.removal.initContainerImage" -}}
{{- range $chart:= list "geo-logcursor" "gitaly" "gitlab-exporter" "gitlab-shell" "mailroom" "migrations" "sidekiq" "toolbox" "webservice" }}
{{-     if hasKey (index $.Values.gitlab $chart) "init" -}}
{{-         with $config := index $.Values.gitlab $chart "init" -}}
{{-             if or (and (hasKey $config "image") (kindIs "string" $config.image)) (hasKey $config "tag") }}
gitlab.{{ $chart }}:
    Configuring image for initContainers using gitlab.{{ $chart }}.init.image and gitlab.{{ $chart }}.init.tag has been removed. Please use gitlab.{{ $chart }}.init.image.repository and gitlab.{{ $chart }}.init.image.tag for that.
{{-             end -}}
{{-         end -}}
{{-     end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.initContainerImage */}}

{{/* Deprecation behavious for configuration of initContainer images of external charts */}}
{{- define "external.removal.initContainerImage" -}}
{{- range $chart:= list "minio" "registry" "redis" "redis-ha" }}
{{-     if hasKey (index $.Values $chart) "init" -}}
{{-         with $config := index $.Values $chart "init" -}}
{{-             if or (and (hasKey $config "image") (kindIs "string" $config.image)) (hasKey $config "tag") }}
{{ $chart }}:
    Configuring image for initContainers using {{ $chart }}.init.image and {{ $chart }}.init.tag has been removed. Please use {{ $chart }}.init.image.repository and {{ $chart }}.init.image.tag for that.
{{-             end -}}
{{-         end -}}
{{-     end -}}
{{- end -}}
{{- end -}}
{{/* END external.removal.initContainerImage */}}

{{/* Deprecation behavious for configuration of initContainer image pull policy of external charts */}}
{{- define "external.removal.initContainerPullPolicy" -}}
{{- range $chart:= list "minio" "registry" }}
{{-     if hasKey (index $.Values $chart) "init" -}}
{{-         with $config := index $.Values $chart "init" -}}
{{-             if hasKey $config "pullPolicy" }}
{{ $chart }}:
    Configuring pullPolicy for initContainer images using {{ $chart }}.init.pullPolicy has been removed. Please use {{ $chart }}.init.image.pullPolicy for that.
{{-             end -}}
{{-         end -}}
{{-     end -}}
{{- end -}}
{{- end -}}
{{/* END external.removal.initContainerPullPolicy*/}}

{{/* Deprecation behaviors for redis-ha.enabled */}}
{{- define "gitlab.removal.redis-ha.enabled" -}}
{{-   if hasKey (index .Values "redis-ha") "enabled" -}}
redis-ha:
    The `redis-ha.enabled` has been removed. Redis HA is now implemented by the Redis chart.
{{-   end -}}
{{- end -}}
{{/* END gitlab.removal.redis-ha.enabled */}}

{{/* Deprecation behaviors for redis.enabled */}}
{{- define "gitlab.removal.redis.enabled" -}}
{{-   if hasKey .Values.redis "enabled" -}}
redis:
    The `redis.enabled` has been removed. Please use `redis.install` to install the Redis service.
{{-   end -}}
{{- end -}}
{{/* END gitlab.removal.redis.enabled */}}

{{- define "gitlab.removal.gitlab.webservice.service.configuration" -}}
{{-   range $chart := list "gitaly" "gitlab-shell" -}}
{{-     if index $.Values.gitlab $chart -}}
{{-       if hasKey (index $.Values.gitlab $chart) "webservice" }}
gitlab.{{ $chart }}:
    webservice:
      The configuration of 'gitlab.{{ $chart }}.webservice' has been moved to 'gitlab.{{ $chart }}.workhorse' to better reflect the underlying architecture. Please relocate this property.
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.removal.gitlab.webservice.service.configuration */}}

{{- define "gitlab.removal.gitlab.gitaly.serviceName" -}}
{{-   if hasKey $.Values.gitlab.gitaly "serviceName" -}}
gitlab.gitaly.serviceName:
      The configuration of 'gitlab.gitaly.serviceName' has been moved to 'global.gitaly.serviceName' to fix an issue with consistent templating. Please relocate this property.
{{-   end -}}
{{- end -}}
{{/* END gitlab.removal.gitlab.gitaly.serviceName */}}

{{- define "gitlab.removal.global.psql.pool" -}}
{{-   if hasKey $.Values.global "psql" -}}
{{-     if hasKey $.Values.global.psql "pool" }}
global.psql.pool:
      Manually configuring the database connection pool has been removed. The application now manages the connection pool size.
{{-     end -}}
{{-   end -}}

{{-   range $chart := list "webservice" "sidekiq" "toolbox" -}}
{{-     if index $.Values.gitlab $chart -}}
{{-       if hasKey (index $.Values.gitlab $chart) "psql" -}}
{{-         with $localConfig := index $.Values.gitlab $chart "psql" -}}
{{-           if hasKey $localConfig "pool" }}
gitlab.{{ $chart }}.psql.pool:
      Manually configuring the database connection pool has been removed. The application now manages the connection pool size.
{{-           end -}}
{{-         end -}}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.removal.global.psql.pool */}}

{{- define "gitlab.removal.global.appConfig.extra.piwik" -}}
{{- if .Values.global.appConfig.extra.piwikSiteId }}
global.appConfig.extra.piwikSiteId:
      Piwik config keys have been renamed to reflect the rebranding to Matomo. Please rename `piwikSiteId` to `matomoSiteId`.
{{- end -}}
{{- if .Values.global.appConfig.extra.piwikUrl }}
global.appConfig.extra.piwikUrl:
      Piwik config keys have been renamed to reflect the rebranding to Matomo. Please rename `piwikUrl` to `matomoUrl`
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.global.appConfig.extra.piwik */}}

{{/* Migration from `updateStrategy` to `deployment.strategy` for Deployment Kubernetes type */}}
{{- define "gitlab.removal.registry.updateStrategy" -}}
{{- if .Values.registry.updateStrategy }}
registry:
    The configuration of `registry.updateStrategy` has moved. Please use
`registry.deployment.strategy` instead.
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.registry.updateStrategy */}}

{{- define "gitlab.removal.sidekiq.updateStrategy" -}}
{{- if hasKey .Values.gitlab.sidekiq "updateStrategy" -}}
sidekiq:
    The configuration of 'gitlab.sidekiq.updateStrategy' has moved. Please use 'gitlab.sidekiq.deployment.strategy' instead.
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.sidekiq.updateStrategy */}}

{{- define "gitlab.removal.sidekiq.pods.updateStrategy" -}}
{{- range $index, $pod := .Values.gitlab.sidekiq.pods -}}
{{-   if hasKey $pod "updateStrategy" }}
sidekiq.pods[{{ $index }}] ({{ $pod.name }}):
    The configuration of 'gitlab.sidekiq.pods[{{ $index }}].updateStrategy' has moved. Please use 'gitlab.sidekiq.pods[{{ $index }}].deployment.strategy' instead.
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.sidekiq.pods.updateStrategy */}}

{{- define "gitlab.removal.global.geo.registry.syncEnabled" -}}
{{- if and (eq true .Values.global.geo.enabled) (hasKey .Values.global.geo.registry "syncEnabled") -}}
geo:
  The configuration of `global.geo.registry.syncEnabled` has moved. Please use `global.geo.registry.replication.enabled` instead.
{{- end -}}
{{- end -}}

{{- define "gitlab.removal.webservice.webServer.unicorn" -}}
{{/* WARN: Unicorn is deprecated and is removed in 14.0 */}}
{{- if eq .Values.gitlab.webservice.webServer "unicorn" -}}
webservice:
   Starting with GitLab 14.0, Unicorn is no longer supported and users must switch to Puma by either setting `gitlab.webservice.webServer` value to `puma` or removing the setting reverting it to default (`puma`). Check https://docs.gitlab.com/ee/administration/operations/puma.html for details.
{{- end }}
{{- end }}

{{- define "gitlab.removal.sidekiq.cluster" -}}
{{- if hasKey .Values.gitlab.sidekiq "cluster" -}}
sidekiq:
    The configuration of 'gitlab.sidekiq.cluster' should be removed. Sidekiq is now always in cluster mode.
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.sidekiq.cluster */}}

{{- define "gitlab.removal.sidekiq.pods.cluster" -}}
{{- range $index, $pod := .Values.gitlab.sidekiq.pods -}}
{{-   if hasKey $pod "cluster" }}
sidekiq.pods[{{ $index }}] ({{ $pod.name }}):
    The configuration of 'gitlab.sidekiq.pods[{{ $index }}].cluster' should be removed. Sidekiq is now always in cluster mode.
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.sidekiq.pods.cluster */}}

{{- define "gitlab.removal.sidekiq.queueSelector" -}}
{{- if hasKey .Values.gitlab.sidekiq "queueSelector" }}
sidekiq:
    The configuration of 'gitlab.sidekiq.queueSelector' should be removed. Please follow the steps at https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#start-multiple-processes, to run Sidekiq with multiple processes while listening to all queues.
{{- end }}
{{- end }}
{{/* END gitlab.removal.sidekiq.queueSelector */}}

{{- define "gitlab.removal.sidekiq.pods.queueSelector" -}}
{{- range $index, $pod := .Values.gitlab.sidekiq.pods -}}
{{-   if hasKey $pod "queueSelector" }}
sidekiq.pods[{{ $index }}] ({{ $pod.name }}):
    The configuration of 'gitlab.sidekiq.pods[{{ $index }}].queueSelector' should be removed. Please follow the steps at https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#start-multiple-processes, to run Sidekiq with multiple processes while listening to all queues.
{{-   end -}}
{{- end }}
{{- end }}
{{/* END gitlab.removal.sidekiq.pods.queueSelector */}}

{{- define "gitlab.removal.sidekiq.negateQueues" -}}
{{- if hasKey .Values.gitlab.sidekiq "negateQueues" }}
sidekiq:
    The configuration of 'gitlab.sidekiq.negateQueues' should be removed. Please follow the steps at https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#start-multiple-processes, to run Sidekiq with multiple processes while listening to all queues.
{{- end }}
{{- end }}
{{/* END gitlab.removal.sidekiq.negateQueues */}}

{{- define "gitlab.removal.sidekiq.pods.negateQueues" -}}
{{- range $index, $pod := .Values.gitlab.sidekiq.pods -}}
{{-   if hasKey $pod "negateQueues" }}
sidekiq.pods[{{ $index }}] ({{ $pod.name }}):
    The configuration of 'gitlab.sidekiq.pods[{{ $index }}].negateQueues' should be removed. Please follow the steps at https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#start-multiple-processes, to run Sidekiq with multiple processes while listening to all queues.
{{-   end -}}
{{- end }}
{{- end }}
{{/* END gitlab.removal.sidekiq.pods.negateQueues */}}

{{- define "certmanager.removal.createCustomResource" -}}
{{- if hasKey .Values.certmanager "createCustomResource" -}}
certmanager:
    The configuration of 'certmanager.createCustomResource' has been renamed. Please use `certmanager.installCRDs` instead.
{{- end -}}
{{- end -}}
{{/* END certmanager.createCustomResource */}}

{{/* Deprecation behaviors for configuration of global imagePullPolicy */}}
{{- define "gitlab.removal.global.imagePullPolicy" -}}
{{- if .Values.global.imagePullPolicy }}
global.imagePullPolicy:
    The configuration of `global.imagePullPolicy` has moved. Please use `global.image.pullPolicy` instead.
{{- end -}}

{{- end -}}

{{/* Deprecation behaviors for task-runner rename to toolbox */}}
{{- define "gitlab.removal.task-runner" -}}
{{-   if index .Values.gitlab "task-runner" }}
gitlab.task-runner:
    The configuration of `gitlab.task-runner` has been renamed. Please use `gitlab.toolbox` instead.
    If you have enabled persistence for `task-runner` and/or its CronJob for backups, you may need to manually bind the new `toolbox` PVC to the previous `task-runner` PV.
{{-   end -}}
{{- end -}}

{{- define "gitlab.removal.gitaly-gitconfig-volume" -}}
{{-   if hasKey .Values.gitlab.gitaly "extraVolumes" -}}
{{-     if regexMatch "- *name:[^\n]*git-?config" .Values.gitlab.gitaly.extraVolumes -}}
gitaly:
    Git commands spawned by Gitaly have stopped reading `gitconfig` files. Please stop mounting `gitconfig` volumes and use the `git.config` value to inject Git configuration.
{{-     end -}}
{{-   end -}}
{{- end -}}

{{- define "gitlab.removal.hpa.legacyCpuTarget" -}}
{{-   range $chart := list "gitlab-pages" "gitlab-shell" "kas" "sidekiq" "spamcheck" "webservice" -}}
{{-     if and (hasKey $.Values.gitlab $chart) (hasKey (index $.Values.gitlab $chart) "hpa") -}}
{{-       if hasKey (index $.Values.gitlab $chart).hpa "targetAverageValue" }}
gitlab.{{ $chart }}:
    The configuration of `gitlab.{{ $chart }}.hpa.targetAverageValue` has moved. Please use `gitlab.{{ $chart }}.hpa.cpu.targetAverageValue` instead.
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}

{{- define "gitlab.removal.hpa.behaviorMispell" -}}
{{-   if and (hasKey $.Values.registry "hpa") (hasKey $.Values.registry.hpa "behaviour") }}
registry:
    The configuration of `registry.hpa.behaviour` has moved. Please use `registry.hpa.behavior` instead.
{{-   end -}}
{{-   range $chart := list "gitlab-pages" "gitlab-shell" "kas" "mailroom" "sidekiq" "spamcheck" "webservice" -}}
{{-     if and (hasKey $.Values.gitlab $chart) (hasKey (index $.Values.gitlab $chart) "hpa") -}}
{{-       if hasKey (index $.Values.gitlab $chart).hpa "behaviour" }}
gitlab.{{ $chart }}:
    The configuration of `gitlab.{{ $chart }}.hpa.behaviour` has moved. Please use `gitlab.{{ $chart }}.hpa.behavior` instead.
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}

{{/* Deprecation behaviors for Grafana*/}}
{{- define "gitlab.removal.global.grafana" -}}
{{- if kindIs "map" (index .Values.global "grafana") }}
{{-   if and ( hasKey .Values.global.grafana "enabled" ) (eq true .Values.global.grafana.enabled)}}
grafana:
    The bundled Grafana chart has been removed, and thus `global.grafana.enabled` does not have any effect. It is recommended that you switch to the newer chart version from Grafana Labs available at https://artifacthub.io/packages/helm/grafana/grafana or a Grafana Operator from a trusted provider. You can find instructions to integrate Grafana with GitLab at https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html.
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.removal.global.grafana */}}

{{- define "gitlab.removal.registry.topLevel" -}}
{{-   if hasKey $.Values.gitlab.webservice "registry" }}
registry:
    The configuration of `gitlab.webservice.registry` has moved. Please use `global.registry` instead
{{-   end -}}
{{-   if hasKey $.Values.gitlab.sidekiq "registry" }}
registry:
    The configuration of `gitlab.sidekiq.registry` has moved. Please use `global.registry` instead
{{-   end -}}
{{- end -}}

{{- define "gitlab.removal.busybox" -}}
{{- if hasKey .Values.global "busybox" }}
global.busybox:
    Support for busybox based based init containers was removed.
    Please use the GitLab base container (`global.gitlabBase`) instead.
{{- end -}}
{{- end -}}

{{- define "gitlab.removal.kas.privateApi.tls" -}}
{{- if hasKey $.Values.gitlab.kas.privateApi "tls" }}
kas:
    The configuration of `gitlab.kas.privateApi.tls.enabled` and `gitlab.kas.privateApi.tls.secretName` have moved.
    Please use `global.kas.tls.enabled` and `global.kas.tls.secretName` instead.
    Other components of the GitLab chart other than KAS also need to be configured to talk to KAS via TLS.
    With a global value the chart can take care of these configurations without the need for other specific values.
{{- end -}}
{{- end -}}
