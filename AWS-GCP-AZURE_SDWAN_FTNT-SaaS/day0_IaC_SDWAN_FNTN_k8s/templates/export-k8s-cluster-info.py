# --------------------------------------------------------------------------------------------
# Populate on AWS SSM K8S cluster parameters
#
# jvigueras@fortinet.com
# --------------------------------------------------------------------------------------------
import base64
import boto3
import kubernetes
from kubernetes import client, config
from botocore.config import Config

def get_bootstrap_token():
    """ Get the token id from the Kubernetes cluster """
    kube_client = client.CoreV1Api()
    master_tokens = kube_client.list_namespaced_secret("kube-system", field_selector='type=bootstrap.kubernetes.io/token').items
    master_token_id = base64.b64decode(master_tokens[0].data["token-id"]).decode()
    master_token_secret = base64.b64decode(master_tokens[0].data["token-secret"]).decode()
    return  master_token_id + "." + master_token_secret

def get_cicd_token():
    """ Get the CICD token from the Kubernetes cluster """
    kube_client = client.CoreV1Api()
    cicd_token = kube_client.read_namespaced_secret(name="cicd-access", namespace="default").data["token"]
    cicd_token_decode = base64.b64decode(cicd_token).decode()
    return cicd_token_decode

def get_cicd_cert():
    """ Get the CICD certificate from the Kubernetes cluster """
    kube_client = client.CoreV1Api()
    cicd_cert = kube_client.read_namespaced_secret(name="cicd-access", namespace="default").data["ca.crt"]
    return cicd_cert

def initialize_aws_sdk():
    """ Initialize the AWS SDK """
    my_config = Config(
        region_name = '${region}',
        signature_version = 'v4',
        retries = {
            'max_attempts': 10,
            'mode': 'standard'
        }
    )
    ssm = boto3.client("ssm", config=my_config)
    return ssm

def put_parameters(ssm, cicd_token, cicd_cert, master_token):
    """ Export the tokens and certificate to AWS Parameter Store """
    try:
        ssm.put_parameter(
            Name="${param_path}/cicd-access_token",
            Value=cicd_token,
            Type="SecureString",
            Overwrite=True
        )
        ssm.put_parameter(
            Name="${param_path}/master_ca_cert",
            Value=cicd_cert,
            Type="SecureString",
            Overwrite=True
        )
        ssm.put_parameter(
            Name="${param_path}/master_token",
            Value=master_token,
            Type="SecureString",
            Overwrite=True
        )
    except Exception as e:
        print(f"Failed to put parameters to AWS Parameter Store: {e}")

def main():
    try:
        # Load the Kubernetes configuration
        config.load_kube_config()

        # Get the tokens and certificate from Kubernetes
        cicd_token = get_cicd_token()
        cicd_cert = get_cicd_cert()
        master_token = get_bootstrap_token()

        # Initialize the AWS SDK
        ssm = initialize_aws_sdk()

        # Export the tokens and certificate to AWS Parameter Store
        put_parameters(ssm, cicd_token, cicd_cert, master_token)

    except Exception as e:
        print(f"Failed to execute main function: {e}")

if __name__ == '__main__':
    main()