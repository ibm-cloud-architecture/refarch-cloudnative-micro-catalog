{{- define "catalog.fullname" -}}
  {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name .Chart.Name -}}
  {{- end -}}
{{- end -}}

{{/* Catalog Labels Template */}}
{{- define "catalog.labels" }}
app: bluecompute
micro: catalog
tier: backend
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/* Catalog Elasticsearch Init Container Template */}}
{{- define "catalog.elasticsearch.initcontainer" }}
- name: test-elasticsearch
  image: {{ .Values.curl.image }}:{{ .Values.curl.imageTag }}
  imagePullPolicy: {{ .Values.curl.imagePullPolicy }}
  command:
  - "/bin/sh"
  - "-c"
  {{- if and .Values.elasticsearch.username .Values.elasticsearch.password }}
  - "set -x; until curl -k ${ES_PROTOCOL}://${ES_USER}:${ES_PASSWORD}@${ES_HOST}:${ES_PORT}/${ES_HEALTH} | {{ template "catalog.elasticsearch.test" . }}"
  {{- else if and .Values.elasticsearch.username }}
  - "set -x; until curl -k ${ES_PROTOCOL}://${ES_USER}@${ES_HOST}:${ES_PORT}/${ES_HEALTH} | {{ template "catalog.elasticsearch.test" . }}"
  {{- else }}
  - "set -x; until curl -k ${ES_PROTOCOL}://${ES_HOST}:${ES_PORT}/${ES_HEALTH} | {{ template "catalog.elasticsearch.test" . }}"
  {{- end }}
  env:
  {{- include "catalog.elasticsearch.environmentvariables" . | indent 2 }}
{{- end }}

{{/* Catalog Elasticsearch Environment Variables */}}
{{- define "catalog.elasticsearch.environmentvariables" }}
- name: ES_HOST
  value: {{ .Values.elasticsearch.host | quote }}
- name: ES_PROTOCOL
  value: {{ .Values.elasticsearch.protocol | quote }}
- name: ES_PORT
  value: {{ .Values.elasticsearch.port | quote }}
- name: ES_HEALTH
  value: {{ .Values.elasticsearch.healthcheck | quote }}
{{- if .Values.elasticsearch.username }}
- name: ES_USER
  value: {{ .Values.elasticsearch.username | quote }}
{{- end }}
{{- if .Values.elasticsearch.password }}
- name: ES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "catalog.elasticsearch.secretName" . }}
      key: elasticsearch-password
{{- end }}
{{- if .Values.elasticsearch.cacertificatebase64 }}
- name: ES_CA_CERTIFICATE_BASE64
  valueFrom:
    secretKeyRef:
      name: {{ template "catalog.elasticsearch.secretName" . }}
      key: elasticsearch-ca-certificate
{{- end }}
{{- end }}

{{/* Catalog Elasticsearch Secret Name */}}
{{- define "catalog.elasticsearch.secretName" }}
  {{ template "catalog.fullname" . }}-elasticsearch-secret
{{- end }}

{{/* Catalog Elasticsearch Health Check */}}
{{- define "catalog.elasticsearch.test" -}}
  {{- printf "grep green; do echo waiting for elasticsearch; sleep 1; done; echo elasticsearch is ready" -}}
{{- end -}}

{{/* Inventory Init Container Template */}}
{{- define "catalog.inventory.initcontainer" }}
- name: test-inventory
  image: {{ .Values.curl.image }}:{{ .Values.curl.imageTag }}
  imagePullPolicy: {{ .Values.curl.imagePullPolicy }}
  command:
  - "/bin/sh"
  - "-c"
  - "until curl ${INVENTORY_URL}; do echo waiting for inventory-service at ${INVENTORY_URL}; sleep 1; done; echo inventory is ready"
  env:
  {{- include "catalog.inventory.environmentvariables" . | indent 2 }}
{{- end }}

{{/* Inventory Environment Variables */}}
{{- define "catalog.inventory.environmentvariables" }}
- name: INVENTORY_URL
  value: {{ template "catalog.inventory" . }}
{{- end }}

{{/* Inventory URL */}}
{{- define "catalog.inventory" -}}
  {{- if .Values.inventory.url -}}
    {{ .Values.inventory.url }}
  {{- else -}}
    {{/* assume one is installed with release */}}
    {{- printf "http://%s-inventory:8080" .Release.Name -}}
  {{- end }}
{{- end -}}