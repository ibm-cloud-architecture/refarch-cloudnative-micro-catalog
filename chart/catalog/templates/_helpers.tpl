{{- define "catalog.fullname" -}}
  {{- .Release.Name }}-{{ .Chart.Name -}}
{{- end -}}

{{/* MySQL Init Container Template */}}
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
  {{- if and .Values.catalogelasticsearch.username .Values.catalogelasticsearch.password }}
  - "set -x; until curl -k ${ES_PROTOCOL}://${ES_USER}:${ES_PASSWORD}@${ES_HOST}:${ES_PORT}/${ES_HEALTH} | {{ template "catalog.elasticsearch.test" . }}"
  {{- else if and .Values.catalogelasticsearch.username }}
  - "set -x; until curl -k ${ES_PROTOCOL}://${ES_USER}@${ES_HOST}:${ES_PORT}/${ES_HEALTH} | {{ template "catalog.elasticsearch.test" . }}"
  {{- else }}
  - "set -x; until curl -k ${ES_PROTOCOL}://${ES_HOST}:${ES_PORT}/${ES_HEALTH} | {{ template "catalog.elasticsearch.test" . }}"
  {{- end }}
  env:
  {{- include "catalog.elasticsearch.environmentvariables" . | indent 2 }}
{{- end }}

{{/* Catalog Elasticsearch Environment Variables */}}
{{- define "catalog.elasticsearch.environmentvariables" }}
{{- if .Values.catalogelasticsearch.enabled }}
- name: ES_HOST
  value: "{{ .Values.catalogelasticsearch.fullnameOverride }}-client"
{{- else }}
- name: ES_HOST
  value: {{ .Values.catalogelasticsearch.fullnameOverride | quote }}
{{- end }}
- name: ES_PROTOCOL
  value: {{ .Values.catalogelasticsearch.protocol | quote }}
- name: ES_PORT
  value: {{ .Values.catalogelasticsearch.port | quote }}
- name: ES_HEALTH
  value: {{ .Values.catalogelasticsearch.healthcheck | quote }}
{{- if .Values.catalogelasticsearch.username }}
- name: ES_USER
  value: {{ .Values.catalogelasticsearch.username | quote }}
{{- end }}
{{- if .Values.catalogelasticsearch.password }}
- name: ES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.catalogelasticsearch.fullnameOverride | quote }}
      key: elasticsearch-password
{{- end }}
{{- if .Values.catalogelasticsearch.cacertificatebase64 }}
- name: ES_CA_CERTIFICATE_BASE64
  valueFrom:
    secretKeyRef:
      name: {{ .Values.catalogelasticsearch.fullnameOverride | quote }}
      key: elasticsearch-ca-certificate
{{- end }}
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
  {{- if .Values.inventory.enabled -}}
    {{- printf "http://%s-inventory:8080" .Release.Name -}}
  {{- else if .Values.inventory.url -}}
    {{ .Values.inventory.url }}
  {{- else -}}
    {{/* assume one is installed with release */}}
    {{- printf "http://%s-inventory:8080" .Release.Name -}}
  {{- end }}
{{- end -}}