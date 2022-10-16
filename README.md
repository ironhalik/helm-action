An action providing helm with its configuration.  

----
### Example usage:
```
steps:
- name: Deploy
  uses: ironhalik/helm-action@v1
  with:
    config: ${{ secrets.CONFIG }} # base64 encoded or neat
    namespace: my-awesome-app
    release: my-awesome-app
    chart: ./
    app_version: ${{ github.sha }}
    values_files: values.yaml
    values: |
      commit: ${{ github.sha }}
      github:
        runId: ${{ github.run_id }}-${{ github.run_attempt }}
```

Supported inputs are: 
- `debug` can be enabled explicitly via action input, or is implicitly enabled when a job is rerun with debug enabled. Will make kubectl and related scripts verbose.
- `config` kubectl config file. Can be either a whole config file (e.g. via ${{ secrets.CONFIG }}), or base64 encoded.
- `eks_cluster` The name of the EKS cluster to get config for. Will use AWS CLI to generate a valid config. Will need standard `aws-cli` env vars and eks:DescribeCluster permission. Mutually exclusive with `config`.
- `context` kubectl config context to use. Not needed if the config has a context already selected.
- `eks_role_arn` IAM role ARN that should be assumed by `aws-cli` when interacting with EKS cluster.
- `namespace` namespace to deploy to. You can use env vars here.
- `create_namespace` should we create the specified namespace.
- `release` helm release name. You can use env vars here.
- `chart` helm chart path.
- `app_version` the version to set AppVersion in Chart.yaml
- `values` helm values to be used in addition to the values file. Will get merged on top of any values_files provided.
- `values_files` helm values files paths, comma separated. Will be used in the order provided.
- `atomic` adds --atomic flag to helm.
- `wait` adds --wait flag to helm.
- `timeout` adds --timeout flag to helm.
- `github_summary` should we write helm status to github step summary.
- `github_summary_strip_commands` should we remove any ::github::commands from the summary.

Many thanks to the creators of the tools included:  
[kubectl](https://github.com/kubernetes/kubectl), [helm](https://github.com/helm/helm), [stern](https://github.com/wercker/stern), [aws-cli](https://github.com/aws/aws-cli)