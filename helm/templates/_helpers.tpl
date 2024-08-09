{{/*
Pod name generator
*/}}
{{- define "helm.podName" -}}
{{ printf "%s-%s-toolkit" .Release.Name .Values.toolkit.name }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default (include "helm.podName" .) .Values.nameOverride }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image name
*/}}
{{- define "helm.image" -}}
{{- .Values.image.repository }}/{{ .Values.image.prefix }}{{ .Values.toolkit.name }}{{ .Values.image.suffix }}:{{ .Values.toolkit.tag }}
{{- end }}
