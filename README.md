This is a sample project called 'CodeBuddy'. This is to demonstrate using Cloudformation, how to create and configure CloudWatch metric filters, alarms and a dashboard to monitor an AWS Lambda function.

# Code Buddy

Code Buddy is a utility designed to run on AWS using Lambda and SNS.
On daily basis it will send an email to a mailing list (SNS Topic) used by a team. This notification will contain the code buddies assignations for the team members.
The default template looks like:
```
This is week n.30, for this week the code buddies are:
    Augustus's code-buddy is Hadrian
    Gaius Caligula's code-buddy is Marcus Aurelius
    Nero's code-buddy is Constantine the Great
    Hadrian's code-buddy is Justinian
    Marcus Aurelius's code-buddy is Augustus
    Constantine the Great's code-buddy is Gaius Caligula
    Justinian's code-buddy is Nero
```

## Installation

The installation steps are the following:

1. Customize `Makefile` parameters
2. Create a `codebuddy` user in our account with credentials pair
3. Configure CLI
4. Create a IAM policy called `CodeBuddyCloudformationPolicy` and attach to `codebuddy` user
5. Create the Cloudformation stack
6. Upload in S3 the email template
7. Deploy the Lambda code

#### Step 1 - Customize Makefile

At the beginning of the Makefile are defined a set of parameters that most probably you want to change.
Here the description of all parameters, at least you would like to change the team members names:

```
BUCKET_NAME # is the name of the S3 bucket used by this utility
DASHBOARD_NAME # is the name of the CloudWatch dashboard you will use to monitor this utility
FUNCTION_NAME # is the name of the Lambda function that will run this utility
MAILING_LIST  # is the mailing list to which the utility will send the notifications
REGION # is the AWS region where all the necessary resources will be created
SCHEDULE_EXPRESSION # is the cron expression in GMT time to set the frequency of notifications
STACK_NAME # is the name of the Cloudformation stack that will be created
TEMPLATE_FILENAME # is the filename of the template used for the notifications
TEAM_MEMBER_NAMES # the names of the team members
```

#### Step 2 - Create user
In order to install this utility into your AWS account and correctly execute the scripts of this project you have to [create a new user](https://console.aws.amazon.com/iam/home#/users$new?step=details) called `codebuddy` and give it a programmatic access. For the moment have to attach to this user the `IAMFullAccess` existing policy. In the step 4 you will create a more fine grained policy and will remove this one.

#### Step 3 - Configure CLI

In the last step of user creation you will get Access and Secret keys for `codebuddy` user. Copy that credentials in your `~/.aws/credentials` file something like:

```
[codebuddy]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
region = eu-west-1
```

If you need to learn more go to [official documentation](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

#### Step 4 - Create IAM policy

The next step is to define fine grained `permissions`. In order to create the policy with all the necessary permissions needed to create the CloudFormation stack, you have to execute the following command in the project root folder:
```
$> make stack-policy
```
This command will create an IAM policy called `CodeBuddyCloudformationPolicy` using the `codebuddy` profile. You can go to the [IAM Console](https://console.aws.amazon.com/iam/home#/users/codebuddy), click on "Add permissions", click on "Attach existing policy", filter policies by "Filter: Customer managed" and attach `CodeBuddyCloudformationPolicy` to the user. You want also to remove the previous policy `IAMFullAccess` that is not necessary anymore.

#### Step 5 - Create the Cloudformation stack

Now that `codebuddy` user is created and has all the necessary permissions you can execute the following command:

```
$> make stack-create
```

This command will create an S3 bucket, an empty Lambda function and CloudWatch alarms, log group and dashboard. The good part of Cloudformation is that you can go in the console and if anything goes wrong inspect the history of events.

#### Step 6 - Upload in S3 the email template

The S3 bucket will host our email [handlebars](http://handlebarsjs.com/) template. In order to upload the email template (cloudformation/default.email.template.txt) you must execute:

```
$> make update-template
```
Obviously the idea is that you can customize you email and re-update as you need.

#### Step 7 - Deploy the Lambda code

Last step is to build the bundle and deploy it into Lambda, executing:

```
$> make update-function
```

### Deletion

For the deletion, since we used Cloudformation, is as simple as executing the following command:

```
$> make stack-delete
```
Be aware that most probably will fail because some resources have to be manually deleted, like alarms and the S3 bucket if it is not empty.

## Measure, diagnose, improve it!

Use CloudWatch Console and specifically your new [Dashboard](https://console.aws.amazon.com/cloudwatch/home?#dashboards:name=CodeBuddy) to monitor your utility running on Lambda!

The default `ScheduleExpression` makes run this utility on daily basis, if you want to test it you can just trigger the lambda function manually. Overall I invite you to customize the lambda function for your team. You could schedule another notification at noon to invite everybody to close tasks and get ready for lunch!

Execute `make help` to see all the tasks ready for development.

```
  CodeBuddy [master] make help

⁉️ Help

AWS ACCOUNT ID: 000000000000

help                            Show this help dialog.
clean                           Clean all directories to build and distribute the project.
build                           Build the package code.
build-cloudformation-template   Build the Cloudformation template.
dist                            Create ZIP package to deploy on AWS Lambda
run-tests                       Run test suite. Optionally accepts a grep parameter to filter only matching tests.
stack-policy                    Create the policy to assign to codebuddy user in order to create stack in CloudFormation
stack-create                    Create CloudFormation stack
stack-delete                    Delete CloudFormation stack
stack-update                    Update CloudWatch dashboard
update-function                 Update Lambda function with latest changes
update-template                 Update email template in S3
```
