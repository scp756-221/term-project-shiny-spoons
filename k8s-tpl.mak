#
# Front-end to bring some sanity to the litany of tools and switches
# for working with a k8s cluster. Note that this file exercise core k8s
# commands that's independent of the cluster vendor.
#
# All vendor-specific commands are in the make file for that vendor:
# az.mak, eks.mak, gcp.mak, mk.mak
#
# This file addresses APPPLing the Deployment, Service, Gateway, and VirtualService
#
# Be sure to set your context appropriately for the log monitor.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.

# These will be filled in by template processor
CREG=ZZ-CR-ID
REGID=ZZ-REG-ID
AWS_REGION=ZZ-AWS-REGION

# Keep all the logs out of main directory
LOG_DIR=logs

# These should be in your search path
KC=kubectl
DK=docker
AWS=aws
IC=istioctl

# Application versions
# Override these by environment variables and `make -e`
APP_VER_TAG=v1
S2_VER=v1
S3_VER=v1
LOADER_VER=v1

# Kubernetes parameters that most of the time will be unchanged
# but which you might override as projects become sophisticated
APP_NS=c756ns
ISTIO_NS=istio-system

# this is used to switch M1 Mac to x86 for compatibility with x86 instances/students
ARCH=--platform x86_64


# ----------------------------------------------------------------------------------------
# -------  Targets to be invoked directly from command line                        -------
# ----------------------------------------------------------------------------------------

# ---  templates:  Instantiate all template files
#
# This is the only entry that *must* be run from k8s-tpl.mak
# (because it creates k8s.mak)
templates:
	tools/process-templates.sh

# --- provision: Provision the entire stack
# This typically is all you need to do to install the sample application and
# all its dependencies
#
# Preconditions:
# 1. Templates have been instantiated (make -f k8s-tpl.mak templates)
# 2. Current context is a running Kubernetes cluster (make -f {az,eks,gcp,mk}.mak start)
#
#  Nov 2021: Kiali is causing problems so do not deploy
#provision: istio prom kiali deploy
provision: istio prom deploy

# --- deploy: Deploy and monitor the three microservices
# Use `provision` to deploy the entire stack (including Istio, Prometheus, ...).
# This target only deploys the sample microservices
deploy: appns gw s1 s2 s3 db monitoring
	$(KC) -n $(APP_NS) get gw,vs,deploy,svc,pods

# --- rollout: Rollout new deployments of all microservices
rollout: rollout-s1 rollout-s2 rollout-s3 rollout-db

# --- rollout-s1: Rollout a new deployment of S1
rollout-s1: s1
	$(KC) rollout -n $(APP_NS) restart deployment/shiny-spoons-s1

# --- rollout-s2: Rollout a new deployment of S2
rollout-s2: $(LOG_DIR)/s2-$(S2_VER).repo.log  cluster/s2-dpl-$(S2_VER).yaml
	$(KC) -n $(APP_NS) apply -f cluster/s2-dpl-$(S2_VER).yaml | tee $(LOG_DIR)/rollout-s2.log
	$(KC) rollout -n $(APP_NS) restart deployment/shiny-spoons-s2-$(S2_VER) | tee -a $(LOG_DIR)/rollout-s2.log

rollout-s3: $(LOG_DIR)/s3-$(S3_VER).repo.log  cluster/s3-dpl-$(S3_VER).yaml
	$(KC) -n $(APP_NS) apply -f cluster/s3-dpl-$(S3_VER).yaml | tee $(LOG_DIR)/rollout-s3.log
	$(KC) rollout -n $(APP_NS) restart deployment/shiny-spoons-s3-$(S3_VER) | tee -a $(LOG_DIR)/rollout-s3.log

# --- rollout-db: Rollout a new deployment of DB
rollout-db: db
	$(KC) rollout -n $(APP_NS) restart deployment/shiny-spoons-db

# --- health-off: Turn off the health monitoring for the three microservices
# If you don't know exactly why you want to do this---don't
health-off:
	$(KC) -n $(APP_NS) apply -f cluster/s1-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/s2-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/s3-nohealth.yaml
	$(KC) -n $(APP_NS) apply -f cluster/db-nohealth.yaml

# --- scratch: Delete the microservices and everything else in application NS
scratch: clean
	$(KC) delete -n $(APP_NS) deploy --all
	$(KC) delete -n $(APP_NS) svc    --all
	$(KC) delete -n $(APP_NS) gw     --all
	$(KC) delete -n $(APP_NS) dr     --all
	$(KC) delete -n $(APP_NS) vs     --all
	$(KC) delete -n $(APP_NS) se     --all
	$(KC) delete -n $(ISTIO_NS) vs monitoring --ignore-not-found=true
	$(KC) get -n $(APP_NS) deploy,svc,pods,gw,dr,vs,se
	$(KC) get -n $(ISTIO_NS) vs

# --- clean: Delete all the application log files
clean:
	/bin/rm -f $(LOG_DIR)/{s1,s2,s3,db,gw,monvs}*.log $(LOG_DIR)/rollout*.log

# --- dashboard: Start the standard Kubernetes dashboard
# NOTE:  Before invoking this, the dashboard must be installed and a service account created
dashboard: showcontext
	echo Please follow instructions at https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
	echo Remember to 'pkill kubectl' when you are done!
	$(KC) proxy &
	open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login

# --- extern: Display status of Istio ingress gateway
# Especially useful for Minikube, if you can't remember whether you invoked its `lb`
# target or directly ran `minikube tunnel`
extern: showcontext
	$(KC) -n $(ISTIO_NS) get svc istio-ingressgateway

# --- log-X: show the log of a particular service
log-s1:
	$(KC) -n $(APP_NS) logs deployment/shiny-spoons-s1 --container shiny-spoons-s1

log-s2:
	$(KC) -n $(APP_NS) logs deployment/shiny-spoons-s2 --container shiny-spoons-s2

log-s3:
	$(KC) -n $(APP_NS) logs deployment/shiny-spoons-s3 --container shiny-spoons-s3

log-db:
	$(KC) -n $(APP_NS) logs deployment/shiny-spoons-db --container shiny-spoons-db


# --- shell-X: hint for shell into a particular service
shell-s1:
	@echo Use the following command line to drop into the s1 service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/shiny-spoons-s1 --container shiny-spoons-s1 -- bash

shell-s2:
	@echo Use the following command line to drop into the s2 service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/shiny-spoons-s2 --container shiny-spoons-s2 -- bash

shell-s3:
	@echo Use the following command line to drop into the s3 service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/shiny-spoons-s3 --container shiny-spoons-s3 -- bash

shell-db:
	@echo Use the following command line to drop into the db service:
	@echo   $(KC) -n $(APP_NS) exec -it deployment/shiny-spoons-db --container shiny-spoons-db -- bash

# --- lsa: List services in all namespaces
lsa: showcontext
	$(KC) get svc --all-namespaces

# --- ls: Show deploy, pods, vs, and svc of application ns
ls: showcontext
	$(KC) get -n $(APP_NS) gw,vs,svc,deployments,pods

# --- lsd: Show containers in pods for all namespaces
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort

# --- reinstate: Reinstate provisioning on a new set of worker nodes
# Do this after you do `up` on a cluster that implements that operation.
# AWS implements `up` and `down`; other cloud vendors may not.
reinstate: istio
	$(KC) create ns $(APP_NS) | tee $(LOG_DIR)/reinstate.log
	$(KC) label ns $(APP_NS) istio-injection=enabled | tee -a $(LOG_DIR)/reinstate.log

# --- showcontext: Display current context
showcontext:
	$(KC) config get-contexts

# Run the loader, rebuilding if necessary, starting DynamDB if necessary, building ConfigMaps
loader: dynamodb-init $(LOG_DIR)/loader.repo.log cluster/loader.yaml
	$(KC) -n $(APP_NS) delete --ignore-not-found=true jobs/shiny-spoons-loader
	tools/build-configmap.sh gatling/resources/users.csv cluster/users-header.yaml | kubectl -n $(APP_NS) apply -f -
	tools/build-configmap.sh gatling/resources/music.csv cluster/music-header.yaml | kubectl -n $(APP_NS) apply -f -
	tools/build-configmap.sh gatling/resources/metadata.csv cluster/metadata-header.yaml | kubectl -n $(APP_NS) apply -f -
	$(KC) -n $(APP_NS) apply -f cluster/loader.yaml | tee $(LOG_DIR)/loader.log

# --- dynamodb-init: set up our DynamoDB tables
#
dynamodb-init: $(LOG_DIR)/dynamodb-init.log

# Start DynamoDB at the default read and write rates
$(LOG_DIR)/dynamodb-init.log: cluster/cloudformationdynamodb.json
	@# "|| true" suffix because command fails when stack already exists
	@# (even with --on-failure DO_NOTHING, a nonzero error code is returned)
	$(AWS) cloudformation create-stack --stack-name db-ZZ-REG-ID --template-body file://$< || true | tee $(LOG_DIR)/dynamodb-init.log
	# Must give DynamoDB time to create the tables before running the loader
	sleep 20

# --- dynamodb-stop: Stop the AWS DynamoDB service
#
dynamodb-clean:
	$(AWS) cloudformation delete-stack --stack-name db-ZZ-REG-ID || true | tee $(LOG_DIR)/dynamodb-clean.log
	@# Rename DynamoDB log so dynamodb-init will force a restart but retain the log
	/bin/mv -f $(LOG_DIR)/dynamodb-init.log $(LOG_DIR)/dynamodb-init-old.log || true

# --- ls-tables: List the tables and their read/write units for all DynamodDB tables
ls-tables:
	@tools/list-dynamodb-tables.sh $(AWS) $(AWS_REGION)

# --- registry-login: Login to the container registry
#
registry-login:
	@/bin/sh -c 'cat cluster/${CREG}-token.txt | $(DK) login $(CREG) -u $(REGID) --password-stdin'

# --- Variables defined for URL targets
# Utility to get the hostname (AWS) or ip (everyone else) of a load-balanced service
# Must be followed by a service
IP_GET_CMD=tools/getip.sh $(KC) $(ISTIO_NS)

# This expression is reused several times
# Use back-tick for subshell so as not to confuse with make $() variable notation
INGRESS_IP=`$(IP_GET_CMD) svc/istio-ingressgateway`

# --- kiali-url: Print the URL to browse Kiali in current cluster
kiali-url:
	@/bin/sh -c 'echo http://$(INGRESS_IP)/kiali'

# --- grafana-url: Print the URL to browse Grafana in current cluster
grafana-url:
	@# Use back-tick for subshell so as not to confuse with make $() variable notation
	@/bin/sh -c 'echo http://`$(IP_GET_CMD) svc/grafana-ingress`:3000/'

# --- prometheus-url: Print the URL to browse Prometheus in current cluster
prometheus-url:
	@# Use back-tick for subshell so as not to confuse with make $() variable notation
	@/bin/sh -c 'echo http://`$(IP_GET_CMD) svc/prom-ingress`:9090/'


# ----------------------------------------------------------------------------------------
# ------- Targets called by above. Not normally invoked directly from command line -------
# ------- Note that some subtargets are in `obs.mak`                               -------
# ----------------------------------------------------------------------------------------

# Install Prometheus stack by calling `obs.mak` recursively
prom:
	make -f obs.mak init-helm --no-print-directory
	make -f obs.mak install-prom --no-print-directory

# Install Kiali operator and Kiali by calling `obs.mak` recursively
# Waits for Kiali to be created and begin running. This wait is required
# before installing the three microservices because they
# depend upon some Custom Resource Definitions (CRDs) added
# by Kiali
kiali:
	make -f obs.mak install-kiali
	# Kiali operator can take awhile to start Kiali
	tools/waiteq.sh 'app=kiali' '{.items[*]}'              ''        'Kiali' 'Created'
	tools/waitne.sh 'app=kiali' '{.items[0].status.phase}' 'Running' 'Kiali' 'Running'

# Install Istio
istio:
	$(IC) install -y --set profile=demo --set hub=gcr.io/istio-release | tee -a $(LOG_DIR)/mk-reinstate.log

# Create and configure the application namespace
appns:
	# Appended "|| true" so that make continues even when command fails
	# because namespace already exists
	$(KC) create ns $(APP_NS) || true
	$(KC) label namespace $(APP_NS) --overwrite=true istio-injection=enabled

# Update monitoring virtual service and display result
monitoring: monvs
	$(KC) -n $(ISTIO_NS) get vs

# Update monitoring virtual service
monvs: cluster/monitoring-virtualservice.yaml
	$(KC) -n $(ISTIO_NS) apply -f $< > $(LOG_DIR)/monvs.log

# Update service gateway
gw: cluster/service-gateway.yaml
	$(KC) -n $(APP_NS) apply -f $< > $(LOG_DIR)/gw.log

# Update S1 and associated monitoring, rebuilding if necessary
s1: $(LOG_DIR)/s1.repo.log cluster/s1.yaml cluster/s1-sm.yaml cluster/s1-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/s1.yaml | tee $(LOG_DIR)/s1.log
	$(KC) -n $(APP_NS) apply -f cluster/s1-sm.yaml | tee -a $(LOG_DIR)/s1.log
	$(KC) -n $(APP_NS) apply -f cluster/s1-vs.yaml | tee -a $(LOG_DIR)/s1.log

# Update S2 and associated monitoring, rebuilding if necessary
s2: rollout-s2 cluster/s2-svc.yaml cluster/s2-sm.yaml cluster/s2-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/s2-svc.yaml | tee $(LOG_DIR)/s2.log
	$(KC) -n $(APP_NS) apply -f cluster/s2-sm.yaml | tee -a $(LOG_DIR)/s2.log
	$(KC) -n $(APP_NS) apply -f cluster/s2-vs.yaml | tee -a $(LOG_DIR)/s2.log

# Update S3 and associated monitoring, rebuilding if necessary
s3: rollout-s3 cluster/s3-svc.yaml cluster/s3-sm.yaml cluster/s3-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/s3-svc.yaml | tee $(LOG_DIR)/s3.log
	$(KC) -n $(APP_NS) apply -f cluster/s3-sm.yaml | tee -a $(LOG_DIR)/s3.log
	$(KC) -n $(APP_NS) apply -f cluster/s3-vs.yaml | tee -a $(LOG_DIR)/s3.log

# Update DB and associated monitoring, rebuilding if necessary
db: $(LOG_DIR)/db.repo.log cluster/awscred.yaml cluster/dynamodb-service-entry.yaml cluster/db.yaml cluster/db-sm.yaml cluster/db-vs.yaml
	$(KC) -n $(APP_NS) apply -f cluster/awscred.yaml | tee $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/dynamodb-service-entry.yaml | tee -a $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/db.yaml | tee -a $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/db-sm.yaml | tee -a $(LOG_DIR)/db.log
	$(KC) -n $(APP_NS) apply -f cluster/db-vs.yaml | tee -a $(LOG_DIR)/db.log

# Build & push the images up to the CR
cri: $(LOG_DIR)/s1.repo.log $(LOG_DIR)/s2-$(S2_VER).repo.log $(LOG_DIR)/s3-$(S3_VER).repo.log $(LOG_DIR)/db.repo.log

# Build the s1 service
$(LOG_DIR)/s1.repo.log: s1/Dockerfile s1/app.py s1/requirements.txt
	make -f k8s.mak --no-print-directory registry-login
	$(DK) build $(ARCH) -t $(CREG)/$(REGID)/shiny-spoons-s1:$(APP_VER_TAG) s1 | tee $(LOG_DIR)/s1.img.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-s1:$(APP_VER_TAG) | tee $(LOG_DIR)/s1.repo.log

# Build the s2 service
$(LOG_DIR)/s2-$(S2_VER).repo.log: s2/$(S2_VER)/Dockerfile s2/$(S2_VER)/app.py s2/$(S2_VER)/requirements.txt
	make -f k8s.mak --no-print-directory registry-login
	$(DK) build $(ARCH) -t $(CREG)/$(REGID)/shiny-spoons-s2:$(S2_VER) s2/$(S2_VER) | tee $(LOG_DIR)/s2-$(S2_VER).img.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-s2:$(S2_VER) | tee $(LOG_DIR)/s2-$(S2_VER).repo.log

# Build the s3 service
$(LOG_DIR)/s3-$(S3_VER).repo.log: s3/Dockerfile s3/app.py s3/requirements.txt
	make -f k8s.mak --no-print-directory registry-login
	$(DK) build $(ARCH) -t $(CREG)/$(REGID)/shiny-spoons-s3:$(S3_VER) s3 | tee $(LOG_DIR)/s3-$(S3_VER).img.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-s3:$(S3_VER) | tee $(LOG_DIR)/s3-$(S3_VER).repo.log

# Build the db service
$(LOG_DIR)/db.repo.log: db/Dockerfile db/app.py db/requirements.txt
	make -f k8s.mak --no-print-directory registry-login
	$(DK) build $(ARCH) -t $(CREG)/$(REGID)/shiny-spoons-db:$(APP_VER_TAG) db | tee $(LOG_DIR)/db.img.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-db:$(APP_VER_TAG) | tee $(LOG_DIR)/db.repo.log

# Build the loader
$(LOG_DIR)/loader.repo.log: loader/app.py loader/requirements.txt loader/Dockerfile registry-login
	$(DK) build $(ARCH) -t $(CREG)/$(REGID)/shiny-spoons-loader:$(LOADER_VER) loader  | tee $(LOG_DIR)/loader.img.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-loader:$(LOADER_VER) | tee $(LOG_DIR)/loader.repo.log

# Push all the container images to the container registry
# This isn't often used because the individual build targets also push
# the updated images to the registry
cr: registry-login
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-s1:$(APP_VER_TAG) | tee $(LOG_DIR)/s1.repo.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-s2:$(S2_VER) | tee $(LOG_DIR)/s2.repo.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-s3:$(S3_VER) | tee $(LOG_DIR)/s3repo.log
	$(DK) push $(CREG)/$(REGID)/shiny-spoons-db:$(APP_VER_TAG) | tee $(LOG_DIR)/db.repo.log

# ---------------------------------------------------------------------------------------
# Handy bits for exploring the container images... not necessary
image: showcontext registry-login
	$(DK) image ls | tee __header | grep $(REGID) > __content
	head -n 1 __header
	cat __content
	rm __content __header
