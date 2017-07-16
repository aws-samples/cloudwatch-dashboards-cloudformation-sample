###
# Customizable parameters
###

BUCKET_NAME := teamname-codebuddy
DASHBOARD_NAME := CodeBuddy
FUNCTION_NAME := CodeBuddy
MAILING_LIST := teamname[hat]company[dot]com
REGION := eu-west-1
SCHEDULE_EXPRESSION := "\"cron(0 7 ? * 2,3,4,5,6 *)\""
STACK_NAME := CodeBuddy
TEMPLATE_FILENAME := default.email.template.txt
TEAM_MEMBER_NAMES := "Augustus;Gaius Caligula;Nero;Hadrian;Marcus Aurelius;Constantine the Great;Justinian"



###
# Tasks
###
ACCOUNTID := $(shell aws --profile codebuddy sts get-caller-identity  --output text --query Account)
CLOUDFORMATION_TEMPFILE = /tmp/codebuddy.cloudformation.template.yaml
MAKEFILE := $(lastword $(MAKEFILE_LIST))
PWD := $(patsubst %/,%,$(dir $(abspath $(MAKEFILE))))

define colorecho
	$(if $(TERM),
		@tput setaf $2
		@echo $1
		@tput sgr0,
		@echo $1)
endef

help: ## Show this help dialog.
	@echo
	$(call colorecho, "⁉️ Help", 13)
	@echo
	$(call colorecho, "AWS ACCOUNT ID: $(ACCOUNTID)", 3)
	@echo
	$(call colorecho, "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' | column -c2 -t -s :)", 5)
	@echo

clean: ## Clean all directories to build and distribute the project.
	@echo
	$(call colorecho, "Clean project", 13)
	@rm -rf ./build/
	$(call colorecho, "Cleaned build directory", 3)
	@rm -rf ./dist/
	$(call colorecho, "Cleand dist directory", 3)
	@echo

build: clean ## Build the package code.
	@echo
	$(call colorecho, "Build project", 13)
	@npm install
	$(call colorecho, "Installed dependencies", 3)
	@mkdir build
	@mkdir build/node_modules
	@cp -R node_modules/aws-sdk ./build/node_modules/aws-sdk
	@cp -R node_modules/handlebars ./build/node_modules/handlebars
	@cp -R node_modules/lambda-log ./build/node_modules/lambda-log
	$(call colorecho, "Copied dependencies to build directory", 3)
	@cp -R src/* build/
	$(call colorecho, "Copied sources to build directory", 3)
	@echo

build-cloudformation-template: ## Build the Cloudformation template.
	@echo
	$(call colorecho, "Build Cloudformation template", 13)
	@rm -f $(CLOUDFORMATION_TEMPFILE)
	@$(eval CLOUDFORMATION_TEMPLATE = $(shell cat cloudformation/template.yaml))
	@$(eval DASHBOARD_BODY_COMPRESSED = $(shell cat cloudformation/dashboard.json | tr -d '\t' |tr -d '\n'))
	$(call colorecho, "Compressed dashboard body", 3)
	@cat cloudformation/template.yaml | sed -e s~DASHBOARD_BODY~'$(DASHBOARD_BODY_COMPRESSED)'~g > $(CLOUDFORMATION_TEMPFILE)
	$(call colorecho, "Created Cloudformation template in $(CLOUDFORMATION_TEMPFILE)", 3)
	@echo

dist: run-tests build ## Create ZIP package to deploy on AWS Lambda
	@echo
	$(call colorecho, "Create ZIP package", 13)
	@mkdir dist
	@cd build; zip -qq -r ../dist/codebuddy.zip *
	$(call colorecho, "Created ../dist/codebuddy.zip", 3)
	@echo

run-tests: ## Run test suite. Optionally accepts a grep parameter to filter only matching tests.
	@echo
ifdef grep
	$(call colorecho, "Running unit tests that matches \"$(grep)\"...", 13)
	@echo
	export NODE_ENV="test"; ./node_modules/mocha/bin/mocha ./test/**/*.test.js --grep $(grep) --sort
else
	$(call colorecho, "Running unit tests suite...", 13)
	@echo
	export NODE_ENV="test"; ./node_modules/mocha/bin/mocha ./test/**/*.test.js --sort
endif

stack-policy: ## Create the policy to assign to codebuddy user in order to create stack in CloudFormation
	@echo
	$(call colorecho, "Create IAM policy CodeBuddyCloudformationPolicy", 13)
	@$(eval POLICY_DOCUMENT = $(shell cat cloudformation/policy.json | tr -d ' ' | tr -d '\n'))
	@$(eval POLICY_DOCUMENT_ESCAPED = $(shell echo '$(POLICY_DOCUMENT)' | sed -e s/\"/\\\\\"/g))
	@aws --profile codebuddy --region $(REGION) iam create-policy --policy-name CodeBuddyCloudformationPolicy --policy-document "$(POLICY_DOCUMENT_ESCAPED)"
	$(call colorecho, "Created IAM policy CodeBuddyCloudformationPolicy", 3)
	@echo

stack-create: build-cloudformation-template ## Create CloudFormation stack
	@echo
	$(call colorecho, "Create CloudFormation stack", 13)
	@aws --profile codebuddy --region $(REGION) cloudformation create-stack \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters ParameterKey=BucketName,ParameterValue=$(BUCKET_NAME)\
		ParameterKey=DashboardName,ParameterValue=$(DASHBOARD_NAME)\
		ParameterKey=FunctionName,ParameterValue=$(FUNCTION_NAME)\
		ParameterKey=MailingListEmail,ParameterValue=$(MAILING_LIST)\
		ParameterKey=ScheduleExpression,ParameterValue=$(SCHEDULE_EXPRESSION)\
		ParameterKey=RootTemplateFilename,ParameterValue=$(TEMPLATE_FILENAME)\
		ParameterKey=TeamMemberNames,ParameterValue=$(TEAM_MEMBER_NAMES)\
		--stack-name $(STACK_NAME)\
		--template-body file://$(CLOUDFORMATION_TEMPFILE)
	@echo
	$(call colorecho, "Creation command executed.", 3)
	$(call colorecho, "Waiting status update...", 3)
	@sleep 10
	@$(MAKE) -f $(MAKEFILE) stack-status

stack-delete: ## Delete CloudFormation stack
	@echo
	$(call colorecho, "Delete CloudFormation stack", 13)
	@aws --profile codebuddy --region $(REGION) cloudformation delete-stack \
		--stack-name $(STACK_NAME)
	$(call colorecho, "Command executed waiting status update...", 3)
	@echo
	@$(MAKE) --no-print-directory -f $(MAKEFILE) stack-status
	@echo

stack-status:
	@aws --profile codebuddy --region $(REGION) cloudformation describe-stacks \
		--stack-name $(STACK_NAME) | python -c "import sys, json; print json.load(sys.stdin)['Stacks'][0]['StackStatus']"

stack-update: build-cloudformation-template ## Update CloudWatch dashboard
	@echo
	$(call colorecho, "Update dashboard", 13)
	@aws --profile codebuddy --region $(REGION) cloudformation update-stack \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters ParameterKey=BucketName,ParameterValue=$(BUCKET_NAME)\
		ParameterKey=DashboardName,ParameterValue=$(DASHBOARD_NAME)\
		ParameterKey=FunctionName,ParameterValue=$(FUNCTION_NAME)\
		ParameterKey=MailingListEmail,ParameterValue=$(MAILING_LIST)\
		ParameterKey=ScheduleExpression,ParameterValue=$(SCHEDULE_EXPRESSION)\
		ParameterKey=RootTemplateFilename,ParameterValue=$(TEMPLATE_FILENAME)\
		ParameterKey=TeamMemberNames,ParameterValue=$(TEAM_MEMBER_NAMES)\
		--stack-name $(STACK_NAME)\
		--template-body file://$(CLOUDFORMATION_TEMPFILE)
	@echo
	@$(MAKE) --no-print-directory -f $(MAKEFILE) stack-status
	@echo
	$(call colorecho, "Dashboard updated", 3)
	@echo

update-function: dist ## Update Lambda function with latest changes
	@echo
	$(call colorecho, "Update Lambda function", 13)
	@aws --profile codebuddy --region $(REGION) lambda update-function-configuration \
		--function-name $(FUNCTION_NAME) \
		--environment '{"Variables":{"BUCKET_NAME":"$(BUCKET_NAME)","SNS_TOPIC_ARN":"arn:aws:sns:$(REGION):$(ACCOUNTID):CodeBuddy","TEAM_MEMBER_NAMES":$(TEAM_MEMBER_NAMES),"TEMPLATE_FILENAME":"$(TEMPLATE_FILENAME)"}}'
	$(call colorecho, "Configuration updated", 3)
	@echo
	@aws --profile codebuddy --region $(REGION) lambda update-function-code \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://$$PWD/dist/codebuddy.zip
	$(call colorecho, "Code updated", 3)
	@echo

update-template: ## Update email template in S3
	@echo
	$(call colorecho, "Update email template file", 13)
	$(call colorecho, "Uploading default email template $(TEMPLATE_FILENAME) to $(BUCKET_NAME)", 3)
	aws --profile codebuddy --region $(REGION) s3 cp $(PWD)/cloudformation/$(TEMPLATE_FILENAME) s3://$(BUCKET_NAME)/
