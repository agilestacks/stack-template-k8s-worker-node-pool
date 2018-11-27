.DEFAULT_GOAL := deploy

export NAME        ?= worker-pool
export DOMAIN_NAME ?= dev.kubernetes.delivery

export STATE_BUCKET ?= agilestacks.cloud-account-name.superhub.io
export STATE_REGION ?= us-east-2

ELABORATE_FILE_FS := .hub/$(DOMAIN_NAME)-$(NAME).elaborate
ELABORATE_FILE_S3 := s3://$(STATE_BUCKET)/$(DOMAIN_NAME)/hub/$(NAME)/hub.elaborate
ELABORATE_FILES   := $(ELABORATE_FILE_FS),$(ELABORATE_FILE_S3)
STATE_FILES       := .hub/$(DOMAIN_NAME)-$(NAME).state,s3://$(STATE_BUCKET)/$(DOMAIN_NAME)/hub/$(NAME)/hub.state

TEMPLATE_PARAMS ?= params/template.yaml
STACK_PARAMS    ?= params/$(DOMAIN_NAME).yaml

PLATFORM_STATE_FILES ?= must-be-set-to-platform-s3-state-path

COMPONENT ?=

HUB_OPTS ?=

hub := hub -d --aws_region=$(STATE_REGION)

ifdef HUB_API
ifdef HUB_TOKEN
ifdef HUB_ENVIRONMENT
ifdef HUB_STACK_INSTANCE
HUB_LIFECYCLE_OPTS ?= --hub-environment "$(HUB_ENVIRONMENT)" --hub-stack-instance "$(HUB_STACK_INSTANCE)"
endif
endif
endif
endif

$(ELABORATE_FILE_FS): cloud.yaml $(TEMPLATE_PARAMS) $(STACK_PARAMS) params/user.yaml
	@mkdir -p .hub
	$(hub) elaborate \
		hub.yaml cloud.yaml $(TEMPLATE_PARAMS) $(STACK_PARAMS) params/user.yaml \
		$(HUB_OPTS) \
		-o $(ELABORATE_FILES) \
		-s $(PLATFORM_STATE_FILES)

elaborate:
	-rm -f $(ELABORATE_FILE_FS)
	$(MAKE) $(ELABORATE_FILE_FS)
.PHONY: elaborate

COMPONENT_LIST := $(if $(COMPONENT),-c $(COMPONENT),)

deploy: $(ELABORATE_FILE_FS)
	$(hub) deploy \
		$(ELABORATE_FILES) \
		$(HUB_LIFECYCLE_OPTS) \
		$(HUB_OPTS) \
		-s $(STATE_FILES) \
		$(COMPONENT_LIST)
.PHONY: deploy

undeploy: $(ELABORATE_FILE_FS)
	$(hub) undeploy --force \
		$(ELABORATE_FILES) \
		$(HUB_LIFECYCLE_OPTS) \
		$(HUB_OPTS) \
		-s $(STATE_FILES) \
		$(COMPONENT_LIST)
.PHONY: undeploy

clean:
	-rm -f .hub/$(DOMAIN_NAME)-$(NAME)*
.PHONY: clean
