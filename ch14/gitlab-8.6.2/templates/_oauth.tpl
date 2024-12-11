{{- define "oauth.gitlab-pages.secret" -}}
{{ default (printf "%s-oauth-gitlab-pages-secret" .Release.Name) (index $.Values.global.oauth "gitlab-pages" "secret") }}
{{- end -}}

{{- define "oauth.gitlab-pages.appIdKey" -}}
{{ default "appid" (index $.Values.global.oauth "gitlab-pages" "appIdKey") }}
{{- end -}}

{{- define "oauth.gitlab-pages.appSecretKey" -}}
{{ default "appsecret" (index $.Values.global.oauth "gitlab-pages" "appSecretKey") }}
{{- end -}}

{{- define "oauth.gitlab-pages.authScope" -}}
{{ default "api" (index $.Values.global.oauth "gitlab-pages" "authScope") }}
{{- end -}}

{{- define "oauth.gitlab-pages.authRedirectUri" -}}
{{- if (index $.Values.global.oauth "gitlab-pages" "redirectUri") -}}
{{   (index $.Values.global.oauth "gitlab-pages" "redirectUri") }}
{{- else -}}
{{-   if eq "true" (include "gitlab.pages.https" $) -}}
{{-     if $.Values.global.pages.namespaceInPath -}}
https://{{ template "gitlab.pages.hostname" . }}/projects/auth
{{-     else -}}
https://projects.{{ template "gitlab.pages.hostname" . }}/auth
{{-     end -}}
{{-   else -}}
{{-     if $.Values.global.pages.namespaceInPath -}}
http://{{ template "gitlab.pages.hostname" . }}/projects/auth
{{-     else -}}
http://projects.{{ template "gitlab.pages.hostname" . }}/auth
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
