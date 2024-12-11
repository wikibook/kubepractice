{{/*
Renders a Ingress for the webservice

It expects a dictionary with three entries:
  - `name` the Ingress name to use
  - `root` the root context
  - `deployment` the context of the deployment to render the Ingress for
  - `host` the host to use in the Ingress rule and TLS config
  - `tlsSecret` the tls secret to use
*/}}
{{- define "webservice.ingress.template" -}}
{{- $global := .root.Values.global }}
{{- if .ingressCfg.local.path }}
---
apiVersion: {{ template "gitlab.ingress.apiVersion" .ingressCfg }}
kind: Ingress
metadata:
  name: {{ .name }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" .root | nindent 4 }}
    {{- include "webservice.labels" .deployment | nindent 4 }}
    {{- include "webservice.commonLabels" .deployment | nindent 4 }}
  annotations:
    {{- if .ingressCfg.local.useGeoClass }}
      {{- include "webservice.geo.ingress.class.annotation" .ingressCfg | nindent 4 }}
    {{- else }}
      {{- include "ingress.class.annotation" .ingressCfg | nindent 4 }}
    {{- end }}
    kubernetes.io/ingress.provider: "{{ template "gitlab.ingress.provider" .ingressCfg }}"
    {{- if eq "nginx" (default $global.ingress.provider .ingressCfg.local.provider) }}
    {{-   if $global.workhorse.tls.enabled }}
    nginx.ingress.kubernetes.io/backend-protocol: https
    {{-     if pluck "verify" .deployment.workhorse.tls (dict "verify" true) | first }}
    nginx.ingress.kubernetes.io/proxy-ssl-verify: 'on'
    nginx.ingress.kubernetes.io/proxy-ssl-name: {{ include "webservice.fullname.withSuffix" .deployment }}.{{ .root.Release.Namespace }}.svc
    {{-       if .deployment.workhorse.tls.caSecretName }}
    nginx.ingress.kubernetes.io/proxy-ssl-secret: {{ .root.Release.Namespace }}/{{ .deployment.workhorse.tls.caSecretName }}
    {{-       end }}
    {{-     end }}
    {{-   end }}
    nginx.ingress.kubernetes.io/proxy-body-size: {{ .ingressCfg.local.proxyBodySize | quote }}
    nginx.ingress.kubernetes.io/proxy-read-timeout: {{ .ingressCfg.local.proxyReadTimeout | quote }}
    nginx.ingress.kubernetes.io/proxy-connect-timeout: {{ .ingressCfg.local.proxyConnectTimeout | quote }}
    {{- end }}
    {{- include "gitlab.certmanager_annotations" .root | nindent 4 }}
  {{- range $key, $value := merge .ingressCfg.local.annotations $global.ingress.annotations }}
    {{ $key }}: {{ $value | quote }}
  {{- end }}
spec:
  {{- if .ingressCfg.local.useGeoClass }}
    {{- include "webservice.geo.ingress.class.field" .ingressCfg | nindent 2 }}
  {{- else }}
    {{- include "ingress.class.field" .ingressCfg | nindent 2 }}
  {{- end }}
  rules:
    - host: {{ .host }}
      http:
        paths:
          - path: {{ .deployment.ingress.path }}
            {{ if or (.root.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress") (eq $global.ingress.apiVersion "networking.k8s.io/v1") -}}
            pathType: {{ default .deployment.ingress.pathType $global.ingress.pathType }}
            backend:
              service:
                  name: {{ template "webservice.fullname.withSuffix" .deployment }}
                  port:
                    number: {{ .root.Values.service.workhorseExternalPort }}
            {{- else -}}
            backend:
              serviceName: {{ template "webservice.fullname.withSuffix" .deployment }}
              servicePort: {{ .root.Values.service.workhorseExternalPort }}
            {{- end -}}
  {{- if (and .tlsSecret (eq (include "gitlab.ingress.tls.enabled" .root) "true" )) }}
  tls:
    - hosts:
      - {{ .host }}
      secretName: {{ .tlsSecret }}
  {{- else }}
  tls: []
  {{- end }}
{{- end }}
{{- end -}}

