### Credentials

* The service account provided muse have the Owner role, since it is creating a bunch of resource

    > gcloud projects add-iam-policy-binding <PROJECT_ID> \
        --member serviceAccount:<SERVICE_ACCOUNT_NAME> \
        --role roles/Owner

* For security considerations, only enable the Owner role to the service account when scaffolding new resources

* And when editing current resources, enable the Editor role

    > gcloud projects remove-iam-policy-binding <PROJECT_ID> \
    --member serviceAccount:<SERVICE_ACCOUNT_NAME> \
    --role roles/Owner

    > gcloud projects add-iam-policy-binding <PROJECT_ID> \
    --member serviceAccount:<SERVICE_ACCOUNT_NAME> \
    --role roles/Editor


### Services

The following services should be enabled in the project

 - servicenetworking.googleapis.com (Service Networking)
 - container.googleapis.com (Kubernetes Engine)
 - cloudresourcemanager.googleapis.com (Resource Manager)
 - sqladmin.googleapis.com (Cloud SQL)
 - compute.googleapis.com (Compute Services)
 - cloudkms.googleapis.com (KMS)


For convenience, an enable services [script](./enable_service.sh) is provided.

> enable_services.sh <project-id>

### Credentials
Run the following command.
> gcloud container clusters get-credentials <ClusterName> --zone <Zone of Cluster >

you should see the output of the following command
> kubectl config current-context

to be something similar to
> gke_<cluster_name>_<region>

... now kubectl works with the new cluster!
