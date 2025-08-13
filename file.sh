@echo off
REM Script to create Terraform project structure with empty files

echo Creating Terraform project structure...

REM Create root terraform directory
mkdir terraform

REM Navigate to terraform directory
cd terraform

REM Create main directories
mkdir modules\eks-cluster
mkdir modules\networking
mkdir modules\argocd
mkdir modules\monitoring
mkdir modules\addons
mkdir environments\dev
mkdir environments\stage
mkdir environments\prod
mkdir shared
mkdir scripts

echo Created directory structure...

REM Create files for eks-cluster module
echo. > modules\eks-cluster\main.tf
echo. > modules\eks-cluster\variables.tf
echo. > modules\eks-cluster\outputs.tf
echo. > modules\eks-cluster\versions.tf

REM Create files for networking module
echo. > modules\networking\main.tf
echo. > modules\networking\variables.tf
echo. > modules\networking\outputs.tf
echo. > modules\networking\versions.tf

REM Create files for argocd module
echo. > modules\argocd\main.tf
echo. > modules\argocd\variables.tf
echo. > modules\argocd\outputs.tf
echo. > modules\argocd\bootstrap.tf

REM Create files for monitoring module
echo. > modules\monitoring\main.tf
echo. > modules\monitoring\variables.tf
echo. > modules\monitoring\outputs.tf
echo. > modules\monitoring\versions.tf

REM Create files for addons module
echo. > modules\addons\main.tf
echo. > modules\addons\variables.tf
echo. > modules\addons\outputs.tf
echo. > modules\addons\versions.tf

echo Created module files...

REM Create files for dev environment
echo. > environments\dev\main.tf
echo. > environments\dev\variables.tf
echo. > environments\dev\terraform.tfvars
echo. > environments\dev\backend.tf
echo. > environments\dev\outputs.tf
echo. > environments\dev\versions.tf

REM Create files for stage environment
echo. > environments\stage\main.tf
echo. > environments\stage\variables.tf
echo. > environments\stage\terraform.tfvars
echo. > environments\stage\backend.tf
echo. > environments\stage\outputs.tf
echo. > environments\stage\versions.tf

REM Create files for prod environment
echo. > environments\prod\main.tf
echo. > environments\prod\variables.tf
echo. > environments\prod\terraform.tfvars
echo. > environments\prod\backend.tf
echo. > environments\prod\outputs.tf
echo. > environments\prod\versions.tf

echo Created environment files...

REM Create shared files
echo. > shared\locals.tf
echo. > shared\data.tf
echo. > shared\variables.tf

REM Create script files
echo. > scripts\deploy.sh
echo. > scripts\destroy.sh
echo. > scripts\plan.sh
echo. > scripts\switch-env.sh

REM Create README.md
echo. > README.md

echo Created shared files and scripts...

echo.
echo ✓ Terraform project structure created successfully!
echo.
echo Structure created in: %cd%
echo.
echo To see the structure, run:
echo tree terraform /f
echo.
echo Or use dir to explore the directories.

pause