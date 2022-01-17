# HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email

| :warning: Warning |
|:---------------------------|
| Note that this connector is not yet implemented nor tested on a HelloID environment. Contact our support for further assistance       |

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

<br />

<p align="center">
  <img src="https://www.caci.nl/wp-content/themes/caci-bootscore-child/img/logo/logo.svg">
</p>

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Remarks](#Remarks)
- [Setup the connector](@Setup-The-Connector)
- [Getting help](#Getting-help)
- [HelloID Docs](#HelloID-docs)

## Introduction

_HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email_ is a _target_ connector. Caci-Osiris provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint     | Description |
| ------------ | ----------- |
| /student/contactgegevens | Used to retrieve and update a student |

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                        | Mandatory   |
| ------------ | -----------                        | ----------- |
| ApiKey     | The ApiKey to connector to Caci Osiris. ApiKeys are generated within the application. | Yes |
| BaseUrl     |The URL to Caci Osiris. | Yes |

### Remarks

#### Create

Note that this connector only updates the email address for a student. The create.ps1 does not create accounts but merely correlates a HelloID person with a Caci-Osiris student and updates the EmailAddress if necessary.

## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
