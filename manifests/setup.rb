require "erb"
require "fileutils"

PROJECT=ENV["PROJECT"] || "matchingv2"
SERVICES=ENV["SERVICES"] || "web"
DEPLOYMENTS=ENV["DEPLOYMENTS"] || ""
PROD_CLUSTER=ENV["PROD_CLUSTER"] || "prod05072018"
STAGING_CLUSTER=ENV["STAGING_CLUSTER"] || "staging04022018"
ORG=ENV["ORG"] || "rivierapartners"
DIR=ENV["DIR"] || "../../#{ORG}/#{PROJECT}"
REGION=ENV["REGION"] || "us-west-2"
#ENV=ENV["ENV"] || "staging"
ECR=ENV["ECR"] || "937487381041.dkr.ecr.us-west-2.amazonaws.com"
BASE="base"
PORT=ENV["PORT"] || "80"
CLUSTER=ENV["CLUSTER"] || "${CLUSTER_NAME}.rivi-infra.com"
AWS_KUBECONFIG=ENV["AWS_KUBECONFIG"] || "rivi-infra.com/kubectl/${CLUSTER}.config"

class String
  def to_kube
    self.gsub('_','-')
  end
end
def base_name
  "#{PROJECT}_#{BASE}"
end
def kube_name(name)
  "#{PROJECT.to_kube}-#{name.to_kube}"
end

def tag_name(name)
  "#{PROJECT}_#{name}"
end

def secrets_name
  "#{PROJECT.to_kube}"
end

def services
  @services ||= SERVICES.split(" ")
end

def deployments
  @deployments ||= DEPLOYMENTS.split(" ")
end

def apps
  @apps ||= deployments + services
end

def write_template(template, file)
  File.open(file, "w") do |f|
    f.write(ERB.new(File.read(template), nil, '-').result)
  end
end

def image_name(name)
  File.join(ECR, ORG, tag_name(name))
end
FileUtils.mkdir_p(File.join(DIR, "deploy", "kubernetes"))
write_template("manifests/templates/Makefile.erb", File.join(DIR, "Makefile"))

[
  "envkubesecret.py",
  "kube-deploy",
  "kube-context",
  "namespace.json",
  "deploy_feature.sh"
].each do |f|
  write_template("manifests/templates/deploy/#{f}.erb", File.join(DIR, "deploy", f))
end

services.each do |app|
  @app = app
  write_template("manifests/templates/deploy/kubernetes/service.yml.erb", File.join(DIR, "deploy", "kubernetes", "#{tag_name(app)}.yml"))
end
deployments.each do |app|
  @app = app
  write_template("manifests/templates/deploy/kubernetes/deployment.yml.erb", File.join(DIR, "deploy", "kubernetes", "#{tag_name(app)}.yml"))
end



