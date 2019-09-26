# DeployTag

DeployTag uses AWS Secret Manager, Kubernetes and Helm to deploy complete
isolated application with full environments.

# Description

-   Terminology
    1.  Kubernetes:
        -   Namespace: Isolated Cluster Resource
        -   Secrets: Holds environment variables that are pulled for
            deployment.
    2.  Helm: Kubernetes Package Manager
    3.  AWS Secret Manager: Secrets Manager holding environment
        variables

-   DeployTag uses `helm`, `git` and AWS Secrets Manager for
    deployment of services.
    -   Helm is a Package Manager for Kubernetes that allows us to
        deploy a service and also include other dependencies such as
        Redis using helm dependenices
    -   Git is used to deploy. Every branch that has `epic/*`,
        `bug/*`, and `feature/*` will be deployed into a new
        Kubernetes Namespace.
        -   This keeps each deployment isolated and self-contained for
            development.
    -   AWS Secrets Manager is used to pull Environment Variables that
        then get populated as secrets with each environment.
-   What Happens when we git push to an appropriate branch: `git push -u origin feature/test`
    1.  We run the tests first.
    2.  We look for Dockerfile.base. This file is all the generic Linux
        dependencies that don't usually change. This file is used to
        speed up builds as installing this dependenices can take a while
        at times.
        -   If the file has changed a new version is created and pushed.
    3.  We build the image used for deployment.
        -   We pull the secrets from AWS Secret Manager looking for the
            appropriate Secrets Manager environment. i.e \`staging/app\`
        -   We update the the environment variables within the Docker
            image with the variables we pull from Secrets Manager.
    4.  We create a database if it doesn't exist based on the git branch
        name.
        -   It creates the database if it doesn't exist if it is a
            staging build.
        -   If it is configured it runs the migrations.
    5.  We deploy the applications as a \`helm\` chart which is a
        package of your applications and any other infrastructure
        dependencies.
        -   If a namespace doesn't exist in Kubernetes for your branch
            it is created
        -   The application is deployed into this namespace.
        -   A new Kubernetes Service LoadBalancer is created so that we
            can access the application.
-   Configuring the Helm Chart
    1.  Most of the configuration for the application happens in the
        helm chart.
    2. This is located within the application repository.
    3. Since they are just yaml templates we can add new things like
        cronjobs, additional containers and dependencies from helm
        charts.
