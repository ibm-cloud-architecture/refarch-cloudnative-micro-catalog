{{/* Catalog */}}
{{- define "catalog.labels" }}
{{- range $key, $value := .Values.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
app.kubernetes.io/name: {{ .Release.Name }}-catalog
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/* Catalog Resources */}}
{{- define "catalog.resources" }}
requests:
  cpu: {{ .Values.image.resources.requests.cpu }}
  memory: {{ .Values.image.resources.requests.memory }}
{{- end }}