{{/* ######### Zoekt related templates */}}

{{- define "gitlab.zoekt.mountSecrets" -}}
# mount secret for zoekt
- secret:
    name: {{ template "gitlab.zoekt.gateway.basicAuth.secretName" . }}
    optional: true
    items:
      - key: gitlab_username
        path: zoekt/.gitlab_zoekt_username
      - key: gitlab_password
        path: zoekt/.gitlab_zoekt_password
{{- end -}}{{/* "gitlab.zoekt.mountSecrets" */}}
