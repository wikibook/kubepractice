{{/*
Ensure the provided global.appConfig.omniauth.provider value is in expected format */}}
{{- define "gitlab.checkConfig.omniauth.providerFormat" -}}
{{-   range $index, $provider := .Values.global.appConfig.omniauth.providers }}
{{-     $badKeys := omit $provider "secret" "key" "name" "label" "icon" }}
{{-     $secretAndOther := and (hasKey $provider "secret") (omit $provider "secret" "key") }}
{{-     $nameAndOther := and (hasKey $provider "name") (omit $provider "name" "label" "icon") }}
{{-     if or $badKeys $secretAndOther $nameAndOther }}
omniauth.providers: each provider should only contain either:
        a) 'secret', and optionally 'key', or
        b) 'name', and optionally 'icon', and `label`
        A current value of global.appConfig.omniauth.providers[{{ $index }}] must be updated.
        Please see https://docs.gitlab.com/charts/charts/globals.html#providers
{{-     end }}
{{-   end }}
{{- end }}
{{/* END gitlab.checkConfig.omniauth.providerFormat */}}
