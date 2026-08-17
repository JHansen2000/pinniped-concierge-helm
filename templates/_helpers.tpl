{{- define "pinniped-concierge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pinniped-concierge.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "pinniped-concierge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pinniped-concierge.labels" -}}
{{ include "pinniped-concierge.selectorLabels" . }}
helm.sh/chart: {{ include "pinniped-concierge.chart" . }}
app.kubernetes.io/name: {{ include "pinniped-concierge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "pinniped-concierge.selectorLabels" -}}
app: pinniped-concierge
{{- end -}}

{{- define "pinniped-concierge.deploymentSelectorLabels" -}}
deployment.pinniped.dev: concierge
{{- end -}}

{{- define "pinniped-concierge.podLabels" -}}
{{ include "pinniped-concierge.selectorLabels" . }}
{{ include "pinniped-concierge.deploymentSelectorLabels" . }}
{{- end -}}

{{- define "pinniped-concierge.serviceAccountName.concierge" -}}
{{- .Values.serviceAccount.concierge.name | default (include "pinniped-concierge.fullname" .) -}}
{{- end -}}

{{- define "pinniped-concierge.serviceAccountName.kubeCertAgent" -}}
{{- .Values.serviceAccount.kubeCertAgent.name | default (printf "%s-kube-cert-agent" (include "pinniped-concierge.fullname" .)) -}}
{{- end -}}

{{- define "pinniped-concierge.serviceAccountName.impersonationProxy" -}}
{{- .Values.serviceAccount.impersonationProxy.name | default (printf "%s-impersonation-proxy" (include "pinniped-concierge.fullname" .)) -}}
{{- end -}}

{{- define "pinniped-concierge.image" -}}
{{- $tag := .Values.image.tag | default (printf "v%s" .Chart.AppVersion) -}}
{{- if .Values.image.digest -}}
{{- printf "%s:%s@%s" .Values.image.repository $tag .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end -}}
