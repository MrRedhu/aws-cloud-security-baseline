TF_DIR := terraform
TF := terraform -chdir=$(TF_DIR)

.PHONY: init fmt validate plan apply destroy

init:
	$(TF) init

fmt:
	$(TF) fmt -recursive

validate: init
	$(TF) validate

plan: init
	$(TF) plan

apply: init
	$(TF) apply

destroy: init
	$(TF) destroy
