# Plaform Engineering with Fortinet
## Introduction

Platform Engineering involves creating and maintaining the underlying infrastructure and tools that support software development and deployment. This project provides an illustration of a deployment of such a platform on public Cloud. The security aspect has been given due consideration throughout the application's life cycle, from coding to runtime with Fortinet security services solutions as FortiDevSec, FortiCNP, FortiWeb Cloud SaaS and Fortigate NGFW. 

## Overview

- [AWS_1AZ_FGT_FWB_FCNP_DEVSEC_K8S](./AWS_1AZ_FGT_FWB_FCNP_DEVSEC_K8S):
  * 0 day deployment of all necessary infrastructure in AWS: Kuberntes cluster, Fortigate (FGT) cluster acting as HUB and FGT cluster as onramp on AWS 1AZ VPC deployment
  * N day deployment of two new applications (FrontEnd and Backend) from Operations/Security teams providing Github repository with configured Actions workflow to seamlessly deploy application
  * N day deployment of two new applications form Developer perspective.  

- [AWS_2AZ_FGT_FWB_FCNP_DEVSEC_K8S_DNSR3](./AWS_2AZ_FGT_FWB_FCNP_DEVSEC_K8S_DNSR3): 
  * 0 day deployment of all necessary infrastructure in AWS: Kuberntes cluster, Fortigate (FGT) cluster acting as HUB and FGT cluster as onramp on AWS 1AZ VPC deployment. This deployments needs a DNS zone configured on AWS Route53.
  * N day deployment of two new applications (FrontEnd and Backend) from Operations/Security teams providing Github repository with configured Actions workflow to seamlessly deploy application
  * N day deployment of two new applications form Developer perspective.  

- [AWS-GCP-AZURE_SDWAN_FTNT-SaaS](./AWS-GCP-AZURE_SDWAN_FTNT-SaaS): 
  * 0 day deployment of all necessary infrastructure in AWS (FGT onramp, K8S cluster, VPC, TGW), GCP (FGT SDWAN HUB) and Azure (site SDWAN). This deployments needs a DNS zone configured on AWS Route53.
  * N day deployment of two new applications (FrontEnd and Backend) from Operations/Security teams providing Github repository with configured Actions workflow to seamlessly deploy application
  * N day deployment of two new applications form Developer perspective.  
