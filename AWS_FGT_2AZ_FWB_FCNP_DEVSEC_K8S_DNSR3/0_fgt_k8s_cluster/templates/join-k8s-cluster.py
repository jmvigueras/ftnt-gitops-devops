# --------------------------------------------------------------------------------------------
# Retrieves necessary parameters from AWS SSM to join a K8S cluster.
#
# jvigueras@fortinet.com
# --------------------------------------------------------------------------------------------
import base64
import boto3
from botocore.config import Config
import os
import time

def get_parameter(ssm, parameter_name, with_decryption=False):
    """ Retrieves a parameter from the AWS Systems Manager Parameter Store """
    try:
        response = ssm.get_parameter(Name=parameter_name, WithDecryption=with_decryption)
        return response['Parameter']['Value']
    except Exception as e:
        print(f"Failed to retrieve parameter {parameter_name}: {e}")
        return None

def wait_for_param(ssm, parameter_name, with_decryption=True):
    """ Waits for a parameter in the AWS Systems Manager Parameter Store to have a value that is not "default" """
    while True:
        parameter_value = get_parameter(ssm, parameter_name, with_decryption=with_decryption)
        if parameter_value != "default":
            return parameter_value
        # Wait for 10 seconds before checking again
        time.sleep(10)

def write_to_file(file_path, content):
    """ Writes content to a file """
    try:
        with open(file_path, "w") as f:
            f.write(content)
    except Exception as e:
        print(f"Failed to write content to file {file_path}: {e}")

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

def main():
    # Set AWS SSM parameter names
    master_host_param_name = "${param_path}/master_private_host"
    token_param_name = "${param_path}/master_token"
    cert_param_name = "${param_path}/master_ca_cert"
    
    # Initialize the AWS SDK boto3 client
    ssm = initialize_aws_sdk()

    # Retrieve master host variable from Parameter Store
    master_host_param = get_parameter(ssm, master_host_param_name)
    if not master_host_param:
        return
    # Write value to file
    write_to_file("/tmp/master", master_host_param)

    # Loop until parameters token and cert won't be "default"
    token_param = wait_for_param(ssm, token_param_name)
    if not token_param:
        return

    # Write value to file
    write_to_file("/tmp/token", token_param)

     # Retrieve master host variable from Parameter Store
    cert_param = get_parameter(ssm, cert_param_name, with_decryption=True)
    if not cert_param:
        return
    
    # Write value to file
    cert_param_decode = base64.b64decode(cert_param).decode()
    write_to_file("/tmp/cert.crt", cert_param_decode)

if __name__ == "__main__":
    main()