{{/*
Expand the name of the chart.
*/}}
{{- define "uptime-private-location.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "uptime-private-location.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "uptime-private-location.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "uptime-private-location.labels" -}}
helm.sh/chart: {{ include "uptime-private-location.chart" . }}
{{ include "uptime-private-location.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "uptime-private-location.selectorLabels" -}}
app.kubernetes.io/name: {{ include "uptime-private-location.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "uptime-private-location.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "uptime-private-location.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding the API token.
Either an external one (apiToken.secretName) or the one this chart creates.
*/}}
{{- define "uptime-private-location.secretName" -}}
{{- if .Values.apiToken.secretName }}
{{- .Values.apiToken.secretName }}
{{- else }}
{{- printf "%s-token" (include "uptime-private-location.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Key inside the Secret.
*/}}
{{- define "uptime-private-location.secretKey" -}}
{{- default "UPTIME_API_TOKEN" .Values.apiToken.secretKey }}
{{- end }}
