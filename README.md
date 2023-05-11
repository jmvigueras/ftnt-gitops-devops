# GitOps and DevSecOps project with Fortinet
## Introduction
This project provides an illustration of how an environment can be utilized to establish a comprehensive CICD (Continuous Integration and Continuous Deployment) cycle for an application utilizing an Agile methodology and GitOps. The security aspect has been given due consideration throughout the application's life cycle, from coding to runtime with Fortinet security services solutions as FortiDevSec, FortiCNP, FortiWeb Cloud SaaS and Fortigate NGFW. 

## Overview

- [AWS_FGT_1AZ_FWB_FCNP_DEVSEC_K8S](./AWS_FGT_1AZ_FWB_FCNP_DEVSEC_K8S): you can find here:
  * 0 day deployment of all necessary infrastructure in AWS: Kuberntes cluster, Fortigate cluster, VPC ...
  * N day deployment of two new application from Operations/Security teams providing Github repository with configured Github Actions workflow to seamlessly deploy application
  * N day deployment of two new application form Developer perspective.  

- [AWS_FGT_2AZ_FWB_FCNP_DEVSEC_K8S_DNSR3](./AWS_FGT_2AZ_FWB_FCNP_DEVSEC_K8S_DNSR3): 
  * 0 day deployment of all necessary infrastructure in AWS: Kuberntes cluster, Fortigate cluster, VPC, AWS Route 53 ...
  * N day deployment of three new applications from Operations/Security teams providing Github repository with configured Actions workflow to seamlessly deploy application
  * N day deployment of three new applications form Developer perspective.  

- [AWS-GCP-AZ_SDWAN_FTNT-SaaS-SEC](./AWS-GCP-AZ_SDWAN_FTNT-SaaS-SEC): 
  * 0 day deployment of all necessary infrastructure in AWS (FGT onramp, K8S cluster, VPC, TGW), GCP (FGT SDWAN HUB) and Azure (site SDWAN)
  * N day deployment of two new applications (FrontEnd and Backend) from Operations/Security teams providing Github repository with configured Actions workflow to seamlessly deploy application
  * N day deployment of two new applications form Developer perspective.  
