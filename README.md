# HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

| :warning: Warning |
|:---------------------------|
| Note that this connector is not yet implemented nor tested on a HelloID environment. Contact our support for further assistance       |


<p align="center">
  <img src="">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email](#helloid-conn-prov-target-Caci-Osiris-Update-Email)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Connection settings](#connection-settings)
    - [Correlation configuration](#correlation-configuration)
    - [Available lifecycle actions](#available-lifecycle-actions)
    - [Field mapping](#field-mapping)
  - [Remarks](#remarks)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
    - [API documentation](#api-documentation)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email_ is a _target_ connector. _Caci-Osiris-Update-Email_ provides a set of REST API's that allow you to programmatically interact with its data.

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                        | Mandatory   |
| ------------ | -----------                        | ----------- |
| ApiKey     | The ApiKey to connector to Caci Osiris. ApiKeys are generated within the application. | Yes |
| BaseUrl     |The URL to Caci Osiris. | Yes |

### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _Caci-Osiris-Update-Email_ to a person in _HelloID_.

| Setting                   | Value                             |
| ------------------------- | --------------------------------- |
| Enable correlation        | `True`                            |
| Person correlation field  | `PersonContext.Person.ExternalId` |
| Account correlation field | `p_studentnummer`                  |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

### Available lifecycle actions

The following lifecycle actions are available:

| Action                                  | Description                                                                                 |
| --------------------------------------- | ------------------------------------------------------------------------------------------- |
| create.ps1                              | Correlates the account on student number (does not create the account if not found).                                                                      |
| delete.ps1                              | Removes/clears the email address of the account.                                                     |
| update.ps1                              | Updates the email address of an account.                                                      |
| configuration.json                      | Contains the connection settings and general configuration for the connector.              |
| fieldMapping.json                       | Defines mappings between person fields and target system person account fields.              |

### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

## Remarks

Note that this connector only updates the email address for a student. The create.ps1 does not create accounts but merely correlates a HelloID person with a Caci-Osiris student
## Development resources

### API endpoints

The following endpoints are used by the connector

| Endpoint     | Description |
| ------------ | ----------- |
| /basis/student/contactgegevens | Used to retrieve and update a student |

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
