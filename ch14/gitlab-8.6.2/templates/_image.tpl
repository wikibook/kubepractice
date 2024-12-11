{{/*
Returns a image tag from the passed in app version or branchname
Usage:
{{ include "gitlab.parseAppVersion" (    \
     dict                                \
         "appVersion" .Chart.AppVersion  \
         "prepend" "false"               \
     ) }}
1. If the version is a semver version, we check the prepend flag.
   1. If it is true, we prepend a `v` and return `vx.y.z` image tag.
   2. If it is false, we do not prepend a `v` and just use the input version
2. Else we just use the version passed as the image tag
*/}}
{{- define "gitlab.parseAppVersion" -}}
{{- $appVersion := coalesce .appVersion "master" -}}
{{- if regexMatch "^\\d+\\.\\d+\\.\\d+(-rc\\d+)?(-pre)?$" $appVersion -}}
{{-   if eq .prepend "true" -}}
{{-      printf "v%s" $appVersion -}}
{{-   else -}}
{{-      $appVersion -}}
{{-   end -}}
{{- else -}}
{{- $appVersion -}}
{{- end -}}
{{- end -}}

{{/*
  A helper template for collecting and inserting the imagePullSecrets.

  It expects a dictionary with two entries:
    - `global` which contains global image settings, e.g. .Values.global.image
    - `local` which contains local image settings, e.g. .Values.image
*/}}
{{- define "gitlab.image.pullSecrets" -}}
{{- $pullSecrets := default (list) .global.pullSecrets -}}
{{- if .local.pullSecrets -}}
{{-   $pullSecrets = concat $pullSecrets .local.pullSecrets -}}
{{- end -}}
{{- if $pullSecrets }}
imagePullSecrets:
{{-   range $index, $entry := $pullSecrets }}
- name: {{ $entry.name }}
{{-   end }}
{{- end }}
{{- end -}}

{{/*
  A helper template for inserting imagePullPolicy.

  It expects a dictionary with two entries:
    - `global` which contains global image settings, e.g. .Values.global.image
    - `local` which contains local image settings, e.g. .Values.image
*/}}
{{- define "gitlab.image.pullPolicy" -}}
{{- $pullPolicy := coalesce .local.pullPolicy .global.pullPolicy -}}
{{- if $pullPolicy }}
imagePullPolicy: {{ $pullPolicy | quote }}
{{- end -}}
{{- end -}}

{{/*
Allow configuring a standard suffix on all images in chart
*/}}
{{- define "gitlab.image.tagSuffix" -}}
{{- if hasKey . "Values" -}}
{{ .Values.global.image.tagSuffix }}
{{- else if hasKey . "global" -}}
{{ .global.image.tagSuffix }}
{{- else }}
""
{{- end -}}
{{- end -}}

{{/*
Constructs helper image value.
Format:
  {{ include "gitlab.helper.image" (dict "context" . "image" "<image context>") }}
*/}}
{{- define "gitlab.helper.image" -}}
{{- $gitlabVersion := "" -}}
{{- if .context.Values.global.gitlabVersion -}}
{{-   $gitlabVersion = include "gitlab.parseAppVersion" (dict "appVersion" .context.Values.global.gitlabVersion "prepend" "true") -}}
{{- end -}}
{{- $tag := coalesce .image.tag $gitlabVersion "master" -}}
{{- $tagSuffix := include "gitlab.image.tagSuffix" .context -}}
{{- printf "%s:%s%s" .image.repository $tag $tagSuffix -}}
{{- end -}}

{{/*
Constructs kubectl image value.
*/}}
{{- define "gitlab.kubectl.image" -}}
{{- include "gitlab.helper.image" (dict "context" . "image" .Values.global.kubectl.image) -}}
{{- end -}}

{{/*
Constructs certificates image value.
*/}}
{{- define "gitlab.certificates.image" -}}
{{- include "gitlab.helper.image" (dict "context" . "image" .Values.global.certificates.image) -}}
{{- end -}}

{{/*
Constructs selfsign image value.
*/}}
{{- define "gitlab.selfsign.image" -}}
{{- $image := index .Values "shared-secrets" "selfsign" "image" -}}
{{- include "gitlab.helper.image" (dict "context" . "image" $image) -}}
{{- end -}}

{{/*
Constructs the GitLab base image used for the configure container.

It expects a dictionary with two entries:
  - `root` which contains the root context
  - `image` which contains overrides for the GitLab base image

Format:
  {{ include "gitlab.configure.image" (dict "root" $ "image" "<override image context>") }}
*/}}
{{- define "gitlab.configure.image" -}}
{{- $image := mergeOverwrite (deepCopy .root.Values.global.gitlabBase.image) .image }}
{{- include "gitlab.helper.image" (dict "context" .root "image" $image) -}}
{{- end -}}

{{/*
Constructs the image configuration for the `configure` container.
*/}}
{{- define "gitlab.configure.config" -}}
{{- dict "global" .global.gitlabBase.image "local" .init.image | toYaml }}
{{- end -}}

{{/*
Return the version tag used to fetch the GitLab images
Defaults to using the information from the chart appVersion field, but can be
overridden using the global.gitlabVersion field in values.
*/}}
{{- define "gitlab.versionTag" -}}
{{- template "gitlab.parseAppVersion" (dict "appVersion" (coalesce .Values.global.gitlabVersion .Chart.AppVersion) "prepend" "true") -}}
{{- end -}}

{{/*
Returns the image repository depending on the value of global.edition.

Used to switch the deployment from Enterprise Edition (default) to Community
Edition. If global.edition=ce, returns the Community Edition image repository
set in the Gitlab values.yaml, otherwise returns the Enterprise Edition
image repository.
*/}}
{{- define "image.repository" -}}
{{- if eq "ce" .Values.global.edition -}}
{{ index .Values "global" "communityImages" .Chart.Name "repository" }}
{{- else -}}
{{ index .Values "global" "enterpriseImages" .Chart.Name "repository" }}
{{- end -}}
{{- end -}}



{{/*
New image templates that will eventually replace those above.
See https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2859.
*/}}

{{/*
Defines the registry for a given image.
*/}}
{{- define "gitlab.image.registry" -}}
{{-   coalesce .local.registry .global.registry "none" -}}
{{- end -}}

{{/*
Defines the repository for a given image.
*/}}
{{- define "gitlab.image.repository" -}}
{{-   coalesce .local.repository .global.repository -}}
{{- end -}}

{{/*
Return the version tag used to fetch the GitLab images
Defaults to using the information from the chart appVersion field, but can be
overridden using the global.gitlabVersion field in values.
*/}}
{{- define "gitlab.image.tag" -}}
{{-   $prepend := coalesce .local.prepend "false" -}}
{{-   $appVersion := include "gitlab.parseAppVersion" (dict "appVersion" .context.Chart.AppVersion "prepend" $prepend) -}}
{{-   coalesce .local.tag .global.tag $appVersion }}
{{- end -}}

{{/*
Allow configuring a standard suffix on all images in chart
*/}}
{{- define "gitlab.image.tag.suffix" -}}
{{- if hasKey . "Values" -}}
{{ .Values.global.tagSuffix }}
{{- else if hasKey . "global" -}}
{{ .global.tagSuffix }}
{{- else }}
""
{{- end -}}
{{- end -}}

{{/*
Return the image digest to use.
*/}}
{{- define "gitlab.image.digest" -}}
{{-   if .local.digest -}}
{{-     printf "@%s" .local.digest -}}
{{-   end -}}
{{- end -}}

{{/*
Creates the full image path for use in manifests.
Will replace the `-ee` edition suffix if `global.edition=ce`.
*/}}
{{- define "gitlab.image.fullPath" -}}
{{-   $registry := include "gitlab.image.registry" . -}}
{{-   $repository := include "gitlab.image.repository" . -}}
{{-   $tag := include "gitlab.image.tag" . -}}
{{-   $tagSuffix := include "gitlab.image.tag.suffix" . -}}
{{-   $digest := include "gitlab.image.digest" . -}}
{{-   if hasSuffix "-ee" $repository -}}
{{-      if eq .context.Values.global.edition "ce" -}}
{{-        $repository = print $repository | replace "-ee" "-ce" -}}
{{-      end -}}
{{-   end -}}
{{-   if eq $registry "none" -}}
{{-     printf "%s:%s%s%s" $repository $tag $tagSuffix $digest | quote -}}
{{-   else -}}
{{-     printf "%s/%s:%s%s%s" $registry $repository $tag $tagSuffix $digest | quote -}}
{{-   end -}}
{{- end -}}
