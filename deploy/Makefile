BRANCH_NAME=master
# PROJECT_ID=$(shell gcloud config list project --format="value(core.project)")
PROJECT_ID=dray-app
PROJECT_NAME=k8s-ssl-man

# VERSION := $(shell git ls-remote --tags origin | cut -d'/' -f3 | sort -t'.' -k1,1 -k2,2 -k3,3 -n | tail -n 1)
VERSION := $(shell git rev-parse HEAD)
DEPLOY_TYPE=stage

all: context build push rc rolling

.PHONY: context
context:
	kubectl config use-context $(DEPLOY_TYPE);

.PHONY: build
build:
	docker build -t $(PROJECT_NAME):$(VERSION) -f ../Dockerfile ..

.PHONY: push
push:
	docker tag $(PROJECT_NAME):$(VERSION) us.gcr.io/$(PROJECT_ID)/$(PROJECT_NAME):$(VERSION) && \
		gcloud docker -- push us.gcr.io/$(PROJECT_ID)/$(PROJECT_NAME):$(VERSION)

.PHONY: rc
rc: context
	mkdir -p rc/compiled/
	sed s/PROJECT_VERSION/$(VERSION)/g rc/base/$(PROJECT_NAME)-rc-$(DEPLOY_TYPE)-base.json > rc/compiled/$(PROJECT_NAME)-rc-$(DEPLOY_TYPE)-v-$(VERSION).json
	sed -i.bak "s/PROJECT_NAME/$(PROJECT_NAME)/g" rc/compiled/$(PROJECT_NAME)-rc-$(DEPLOY_TYPE)-v-$(VERSION).json
	sed -i.bak "s/DEPLOY_TYPE/$(DEPLOY_TYPE)/g" rc/compiled/$(PROJECT_NAME)-rc-$(DEPLOY_TYPE)-v-$(VERSION).json

.PHONY: rolling
rolling: context
	echo "Starting a rolling update to $(VERSION)..."
	PREV_VER=`kubectl get rc --selector=app=$(PROJECT_NAME) -o 'jsonpath={.items[*].metadata.name}' | head -n 1` && \
			 kubectl rolling-update $${PREV_VER} -f rc/compiled/$(PROJECT_NAME)-rc-$(DEPLOY_TYPE)-v-$(VERSION).json
	slackcli $(SLACK_OPTS) -m "Completed deploying *$(PROJECT_NAME)* (v $(VERSION)) to $(DEPLOY_TYPE)."

.PHONY: new
new: context
	kubectl create -f rc/compiled/$(PROJECT_NAME)-rc-$(DEPLOY_TYPE)-v-$(VERSION).json && \
		kubectl create -f ./$(PROJECT_NAME)-svc.yaml

.PHONY: promote
promote: rc rolling

.PHONY: cronjob
cronjob: context
	cat jobs/cronjob-$(DEPLOY_TYPE).yml | sed s/PROJECT_NAME/$(PROJECT_NAME)/g | sed s/PROJECT_VERSION/$(VERSION)/g | sed s/DEPLOY_TYPE/$(DEPLOY_TYPE)/g | kubectl delete -f - --ignore-not-found=true
	cat jobs/cronjob-$(DEPLOY_TYPE).yml | sed s/PROJECT_NAME/$(PROJECT_NAME)/g | sed s/PROJECT_VERSION/$(VERSION)/g | sed s/DEPLOY_TYPE/$(DEPLOY_TYPE)/g | kubectl create -f -

.PHONY: job
job: context
	cat jobs/job-$(DEPLOY_TYPE).yml | sed s/PROJECT_NAME/$(PROJECT_NAME)/g | sed s/PROJECT_VERSION/$(VERSION)/g | sed s/DEPLOY_TYPE/$(DEPLOY_TYPE)/g | kubectl delete -f - --ignore-not-found=true
	cat jobs/job-$(DEPLOY_TYPE).yml | sed s/PROJECT_NAME/$(PROJECT_NAME)/g | sed s/PROJECT_VERSION/$(VERSION)/g | sed s/DEPLOY_TYPE/$(DEPLOY_TYPE)/g | kubectl create -f -
