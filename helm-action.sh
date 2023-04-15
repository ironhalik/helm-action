# shellcheck shell=bash
# This code is meant to be used with
# https://github.com/ironhalik/kubectl-action-base
if [ -z "${IS_KUBECTL_ACTION_BASE}" ]; then
    echo "::error:: The script is not meant to be used on it's own."
    exit 1
fi

# helm-action specific code
get_inputs CREATE_NAMESPACE RELEASE CHART APP_VERSION VALUES VALUES_FILES ATOMIC WAIT TIMEOUT GITHUB_SUMMARY GITHUB_SUMMARY_STRIP_COMMANDS 

HELM_ARGS="${HELM_ARGS} --namespace ${NAMESPACE}"
[ "${CREATE_NAMESPACE}" == "true" ] && HELM_ARGS="${HELM_ARGS} --create-namespace"
[ "${ATOMIC}" == "true" ] && HELM_ARGS="${HELM_ARGS} --atomic"
[ "${WAIT}" == "true" ] && HELM_ARGS="${HELM_ARGS} --wait"
[ -n "${TIMEOUT}" ] && HELM_ARGS="${HELM_ARGS} --timeout ${TIMEOUT}"
[ -n "${VALUES_FILES}" ] && for file in ${VALUES_FILES//,/}; do HELM_ARGS="${HELM_ARGS} --values ${file}"; done
[ -n "${VALUES}" ] && echo "${VALUES}" > /tmp/gha_input_values.yaml && HELM_ARGS="${HELM_ARGS} --values /tmp/gha_input_values.yaml"
[ -n "${IS_DEBUG}" ] && HELM_ARGS="${HELM_ARGS} --debug"
HELM_ARGS="${HELM_ARGS} ${CHART}"

[ -n "${APP_VERSION}" ] && yq -i ".appVersion = \"${APP_VERSION}\"" "${CHART}/Chart.yaml"

[ -n "${VALUES}" ] && log debug "Values:\n$(cat /tmp/gha_input_values.yaml)"
log debug "Running: helm template ${RELEASE} ${HELM_ARGS}\n"
# shellcheck disable=SC2086
log debug "$(helm template ${RELEASE} ${HELM_ARGS})"

log info "Running: helm upgrade ${RELEASE} --install ${HELM_ARGS}"
set +e
# shellcheck disable=SC2086
helm upgrade "${RELEASE}" --install ${HELM_ARGS}
helm_status="${?}"
log debug "Helm exited with status ${helm_status}"

if [ "${GITHUB_SUMMARY}" == "true" ]; then
    log debug "Writing helm status to ${GITHUB_STEP_SUMMARY}"
    if [ "${GITHUB_SUMMARY_STRIP_COMMANDS}" == "true" ]; then
        helm status --namespace "${NAMESPACE}" "${RELEASE}" | grep -Ev '^::.+::.+' >> "${GITHUB_STEP_SUMMARY}"
    else
        helm status --namespace "${NAMESPACE}" "${RELEASE}" >> "${GITHUB_STEP_SUMMARY}"
    fi
fi

exit "${helm_status}"
