{{- define "gitlab.checkConfig.ingress.alternatives" -}}
{{-   if and (index $.Values "nginx-ingress").enabled $.Values.haproxy.install -}}
ingress:
  HAProxy is also enabled via `haproxy.install=true`.
  Please disable NGINX via `nginx-ingress.enabled=false`.
{{-   end -}}
{{-   if and (index $.Values "nginx-ingress").enabled $.Values.traefik.install -}}
ingress:
  Traefik is also enabled via `traefik.install=true`.
  Please disable NGINX via `nginx-ingress.enabled=false`.
{{-   end -}}
{{- end -}}

{{- define "gitlab.checkConfig.ingress.class" -}}
{{-   if $.Values.traefik.install -}}
{{-     if ne $.Values.global.ingress.class "traefik" -}}
ingress:
  Traefik is enabled.
  Please set `global.ingress.class=traefik`.
{{-     end -}}
{{-   end -}}
{{-   if $.Values.haproxy.install -}}
{{-     if ne $.Values.global.ingress.class "haproxy" -}}
ingress:
  HAProxy is enabled.
  Please set `global.ingress.class=haproxy`.
{{-     end -}}
{{-   end -}}
{{- end -}}
