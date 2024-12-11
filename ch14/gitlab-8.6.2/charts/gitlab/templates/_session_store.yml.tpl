{{- define "gitlab.session_store.yml" -}}
production:
    session_cookie_token_prefix: {{ .Values.global.rails.sessionStore.sessionCookieTokenPrefix | quote }}
{{- end }}
