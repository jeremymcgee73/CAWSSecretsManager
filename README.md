# SecretsManagement.CAWSSecretsManager Secret Extension

A community written PowerShell Secret Manager Extension for AWS Secret Manager.

## Overview
This is a PowerShell Secret Extension/Module for AWS Secret Manager. This module is currenlty in beta. The Microsoft PowerShell SecretManagment module also is in alpha.

## Description
The module currently does not have a way to pass in common parameters for things like switching profiles, keys, etc. This currently works by using the default profile. The user must have access to read,write,and list AWS secrets.

## Installation
    Install-Module -Name SecretsManagement.CAWSSecretsManager
    Install-Module Microsoft.PowerShell.SecretsManagement  -AllowPrerelease
