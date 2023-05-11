name: FortiDevSec Scanner CI 
on:
  push:
   branches: [ master ]
  pull_request:
   branches: [ master ]
 
jobs:  
  scanning:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: SAST
      run: |
       docker pull registry.fortidevsec.forticloud.com/fdevsec_sast:latest
       docker run -i --mount type=bind,source="$(pwd)",target=/scan  registry.fortidevsec.forticloud.com/fdevsec_sast:latest
  
  kubescape:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: kubescape/github-action@main
        continue-on-error: true
        with:
          format: sarif
          outputFile: results.sarif
          files: "manifest/*.yaml"

  deployk8s:
    name: Deployk8s
    runs-on: ubuntu-latest
    needs: kubescape
    steps:
    - uses: actions/checkout@v2
    - uses: actions-hub/kubectl@master
      env:
        KUBE_TOKEN: $${{ secrets.KUBE_TOKEN }}
        KUBE_HOST: $${{ secrets.KUBE_HOST }}
        KUBE_CERTIFICATE: $${{ secrets.KUBE_CERTIFICATE }}
      with:
        # First deployment
        args: apply -f manifest/*.yaml
        # First deployment without checking API CA certificate
        # args: --insecure-skip-tls-verify apply -f manifest/*.yaml
        # Used if previous deployment exists
        # args: --insecure-skip-tls-verify set image deployment/${app_name}-deployment  ${app_name}=${dockerhub_username}/${dockerhub_image_name}:$${{ github.run_id }}
        # args: set image deployment/${app_name}-deployment ${app_name}=${dockerhub_username}/${dockerhub_image_name}:$${{ github.run_id }}