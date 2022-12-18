# This code is meant to be used with
# https://github.com/ironhalik/kubectl-action-base
if [ ! -n "${IS_KUBECTL_ACTION_BASE}" ]; then
    echo "::error:: The script is not meant to be used on it's own."
    exit 1
fi

# helm-action specific code
HELM_ARGS="--namespace ${INPUT_NAMESPACE}"
[ "${INPUT_CREATE_NAMESPACE}" == "true" ] && HELM_ARGS="${HELM_ARGS} --create-namespace"
[ "${INPUT_ATOMIC}" == "true" ] && HELM_ARGS="${HELM_ARGS} --atomic"
[ "${INPUT_WAIT}" == "true" ] && HELM_ARGS="${HELM_ARGS} --wait"
[ -n "${INPUT_TIMEOUT}" ] && HELM_ARGS="${HELM_ARGS} --timeout ${INPUT_TIMEOUT}"
[ -n "${INPUT_VALUES_FILES}" ] && for file in "${INPUT_VALUES_FILES//,/}"; do HELM_ARGS="${HELM_ARGS} --values ${file}"; done
[ -n "${INPUT_VALUES}" ] && echo "${INPUT_VALUES}" > /tmp/gha_input_values.yaml && HELM_ARGS="${HELM_ARGS} --values /tmp/gha_input_values.yaml"
[ -n "${IS_DEBUG}" ] && HELM_ARGS="${HELM_ARGS} --debug"
HELM_ARGS="${HELM_ARGS} ${INPUT_CHART}"

[ -n "${INPUT_APP_VERSION}" ] && yq -i ".appVersion = \"${INPUT_APP_VERSION}\"" ${INPUT_CHART}/Chart.yaml

[ -n "${INPUT_VALUES}" ] && log debug "Values:\n$(cat /tmp/gha_input_values.yaml)"
log debug "Running: helm template ${INPUT_RELEASE} ${HELM_ARGS})\n"
log debug "$(helm template ${INPUT_RELEASE} ${HELM_ARGS})"

log info "Running: helm upgrade ${INPUT_RELEASE} --install ${HELM_ARGS}"
set +e
helm upgrade ${INPUT_RELEASE} --install ${HELM_ARGS}
helm_status="${?}"
log debug "Helm exited with status ${helm_status}"

if [ "${INPUT_GITHUB_SUMMARY}" == "true" ]; then
    log debug "Writing helm status to ${GITHUB_STEP_SUMMARY}"
    if [ "${INPUT_GITHUB_SUMMARY_STRIP_COMMANDS}" == "true" ]; then
        helm status --namespace "${INPUT_NAMESPACE}" "${INPUT_RELEASE}" | grep -Ev '^::.+::.+' >> "${GITHUB_STEP_SUMMARY}"
    else
        helm status --namespace "${INPUT_NAMESPACE}" "${INPUT_RELEASE}" >> "${GITHUB_STEP_SUMMARY}"
    fi
fi

exit "${helm_status}"
