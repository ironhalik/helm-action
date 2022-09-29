#!/bin/bash
set -e
set -o pipefail

[ -n "${INPUT_DEBUG}" ] && RUNNER_DEBUG=1

log_debug() {
    if [ -n "${RUNNER_DEBUG}" ]; then
        echo -e "${*}" | sed 's/^/[debug] /g'
    fi
}

echo "${INPUT_CONFIG}" > /tmp/config
if [ -n "${INPUT_CONTEXT}" ]; then
    kubectl config set-context "${INPUT_CONTEXT}"
fi
log_debug "Current kubectl context: $(kubectl config current-context)"

HELM_ARGS="--namespace ${INPUT_NAMESPACE}"
[ "${INPUT_CREATE_NAMESPACE}" == "true" ] && HELM_ARGS="${HELM_ARGS} --create-namespace"
[ "${INPUT_ATOMIC}" == "true" ] && HELM_ARGS="${HELM_ARGS} --atomic"
[ "${INPUT_WAIT}" == "true" ] && HELM_ARGS="${HELM_ARGS} --wait"
[ -n "${INPUT_TIMEOUT}" ] && HELM_ARGS="${HELM_ARGS} --timeout ${INPUT_TIMEOUT}"
[ -n "${INPUT_VALUES_FILES}" ] && for file in "${INPUT_VALUES_FILES//,/}"; do HELM_ARGS="${HELM_ARGS} --values ${file}"; done
[ -n "${INPUT_VALUES}" ] && echo "${INPUT_VALUES}" > /tmp/gha_input_values.yaml && HELM_ARGS="${HELM_ARGS} --values /tmp/gha_input_values.yaml"
[ -n "${RUNNER_DEBUG}" ] && HELM_ARGS="${HELM_ARGS} --debug"
HELM_ARGS="${HELM_ARGS} ${INPUT_CHART}"

[ -n "${INPUT_VALUES}" ] && log_debug "Values:\n$(cat /tmp/gha_input_values.yaml)"
log_debug "Running: helm template ${HELM_ARGS})\n"
log_debug "$(helm template ${HELM_ARGS})"

echo "Running: helm upgrade ${INPUT_RELEASE} --install ${HELM_ARGS}"
helm upgrade ${INPUT_RELEASE} --install ${HELM_ARGS}
