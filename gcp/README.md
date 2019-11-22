### Credentials

* The service account provided muse have the Owner role, since it is creating a bunch of resource
    
* For security considerations, only enable the Owner role to the service account when scaffolding new resources
    
* And when editing current resources, enable the Editor role
    
### Services

* the following services should be enabled in the project
    *  servicenetworking.googleapis.com (Service Networking)
    *  container.googleapis.com (kubernetes engine)
    *  cloudresourcemanager.googleapis.com (resource manager)
    *  sqladmin.googleapis.com (cloud sql)
    *  compute.googleapis.com (compute services)

* for convenience, an enable services script is provided in enable_services.sh

### Credentials
Run the following command.  
> gcloud container clusters get-credentials <ClusterName> --zone <Zone of Cluster >
    
you should see the output of the following command
> kubectl config current-context

to be something similar to 
> gke_<cluster_name>_<region>

... now kubectl works with the new cluster! 