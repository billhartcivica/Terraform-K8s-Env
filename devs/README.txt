These scripts are for managing a full network environment for the eGar project.
They create a VPC, subnet, route, gateway and security group for all hosts 
running within the environment.

The create script parses environment parameters to the Terraform template, 
creating a new script with the required variables. 
