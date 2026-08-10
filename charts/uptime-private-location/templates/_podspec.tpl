{{/*
Shared pod spec for Deployment and StatefulSet.
*/}}
{{- define "uptime-private-location.podSpec" -}}
serviceAccountName: {{ include "uptime-private-location.serviceAccountName" . }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.priorityClassName }}
priorityClassName: {{ . }}
{{- end }}
terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
volumes:
  - name: ramdisk
    emptyDir:
      medium: Memory
      sizeLimit: {{ .Values.ramdisk.sizeLimit }}
  - name: tmpfs
    emptyDir:
      medium: Memory
      sizeLimit: {{ .Values.tmpfs.sizeLimit }}
  {{- if and .Values.persistence.enabled (eq .Values.kind "Deployment") }}
  - name: nagios-var
    persistentVolumeClaim:
      claimName: {{ include "uptime-private-location.fullname" . }}-nagios-var
  - name: uptime-var
    persistentVolumeClaim:
      claimName: {{ include "uptime-private-location.fullname" . }}-uptime-var
  - name: uptime-logs
    persistentVolumeClaim:
      claimName: {{ include "uptime-private-location.fullname" . }}-uptime-logs
  {{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- with .Values.securityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    ports:
      - name: nagios
        containerPort: 8443
        protocol: TCP
    env:
      - name: UPTIME_API_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ include "uptime-private-location.secretName" . }}
            key: {{ include "uptime-private-location.secretKey" . }}
      {{- if .Values.config.availableCpuCores }}
      - name: UPTIME_AVAILABLE_CPU_CORES
        value: {{ .Values.config.availableCpuCores | quote }}
      {{- end }}
      {{- if .Values.config.txnLimitBrowsers }}
      - name: UPTIME_TXN_LIMIT_BROWSERS
        value: {{ .Values.config.txnLimitBrowsers | quote }}
      {{- end }}
      {{- if .Values.config.txnMaxExecTime }}
      - name: UPTIME_TXN_MAX_EXEC_TIME
        value: {{ .Values.config.txnMaxExecTime | quote }}
      {{- end }}
      {{- if .Values.config.maxExecTime }}
      - name: UPTIME_MAX_EXEC_TIME
        value: {{ .Values.config.maxExecTime | quote }}
      {{- end }}
      {{- with .Values.extraEnv }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    volumeMounts:
      - name: ramdisk
        mountPath: /dev/shm
      - name: tmpfs
        mountPath: /home/uptime/run
      {{- if .Values.persistence.enabled }}
      - name: nagios-var
        mountPath: {{ .Values.persistence.nagiosVar.mountPath }}
      - name: uptime-var
        mountPath: {{ .Values.persistence.uptimeVar.mountPath }}
      - name: uptime-logs
        mountPath: {{ .Values.persistence.uptimeLogs.mountPath }}
      {{- end }}
    {{- if .Values.livenessProbe.enabled }}
    livenessProbe:
      tcpSocket:
        port: nagios
      initialDelaySeconds: 60
      periodSeconds: 30
    {{- end }}
    {{- if .Values.readinessProbe.enabled }}
    readinessProbe:
      tcpSocket:
        port: nagios
      initialDelaySeconds: 30
      periodSeconds: 15
    {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
