#!/bin/bash
set -e
set -o pipefail

[ -n "${INPUT_DEBUG}" ] && RUNNER_DEBUG=1

log_debug() {
    echo -e "${*}" | sed 's/^/::debug:: /g'
}

if [ -n "${INPUT_CONFIG}" ]; then
    if [[ "${INPUT_CONFIG}" =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$ ]]; then
        log_debug "Looks like config is in base64. Decoding."
        echo "${INPUT_CONFIG}" | base64 -d > /tmp/config
    else
        log_debug "Looks like config is plain yaml. Using it like it."
        echo "${INPUT_CONFIG}" > /tmp/config
    fi
elif [ -n "${INPUT_EKS_CLUSTER}" ]; then
    log_debug "Using AWS CLI to get the cluster config..."
    aws_output=$(aws eks update-kubeconfig --name "${INPUT_EKS_CLUSTER}")
    log_debug "${aws_output}"
else
    echo "::error:: Either config or eks_cluster must be specified."
    exit 1
fi
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

[ -n "${INPUT_APP_VERSION}" ] && yq -i ".appVersion = \"${INPUT_APP_VERSION}\"" ${INPUT_CHART}/Chart.yaml

[ -n "${INPUT_VALUES}" ] && log_debug "Values:\n$(cat /tmp/gha_input_values.yaml)"
log_debug "Running: helm template ${HELM_ARGS})\n"
log_debug "$(helm template ${HELM_ARGS})"

echo "Running: helm upgrade ${INPUT_RELEASE} --install ${HELM_ARGS}"
set +e
helm upgrade ${INPUT_RELEASE} --install ${HELM_ARGS}
helm_status="${?}"

if [ "${INPUT_GITHUB_SUMMARY}" == "true" ]; then
    log_debug "Writing helm status to ${GITHUB_STEP_SUMMARY}"
    if [ "${INPUT_GITHUB_SUMMARY_STRIP_COMMANDS}" == "true" ]; then
        helm status --namespace "${INPUT_NAMESPACE}" "${INPUT_RELEASE}" | grep -Ev '^::.+::.+' >> "${GITHUB_STEP_SUMMARY}"
    else
        helm status --namespace "${INPUT_NAMESPACE}" "${INPUT_RELEASE}" >> "${GITHUB_STEP_SUMMARY}"
    fi
fi

exit "${helm_status}"
