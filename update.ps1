##########################################################
# HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email-Update
#
# Version: 1.0.0
##########################################################
$VerbosePreference = "Continue"

# Initialize default value's
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$aRef = $AccountReference | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

# Mapping
$account = @{
    studentNummer = $p.ExternalId
    e_mailadres   = $p.Contact.Business.Email
}

#region functions
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
            ScriptStackTrace      = $ErrorObject.ScriptStackTrace
            ErrorMessage          = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorMessage = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $httpErrorObj.ErrorMessage = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Begin
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Api-Key", $config.ApiKey)
    $headers.Add("OS-STUDENTNUMMER", $aRef)

    Write-Verbose "Verify if Caci-Osiris account for: [$($p.DisplayName)] exists"
    $splatParams = @{
        Url     = "$($config.BaseUrl)/student/contactgegevens"
        Method  = 'GET'
        Headers = $headers
    }
    $responseGetUser = Invoke-RestMethod @splatParams

    if ($responseGetUser.e_mailadres -ne $account.e_mailadres){
        $action = 'Update'
        $msg = "$action Caci-Osiris eMailAddress: [$($account.e_mailadres)] for: [$($p.DisplayName)] will be executed during enforcement"
    } elseif ($responseGetUser.e_mailadres -eq $account.e_mailadres){
        $action = 'Exit'
        $msg = "eMailAddress: [$($account.e_mailadres)] for: [$($p.DisplayName)] does not require an update"
    }

    # Add an auditMessage showing what will happen during enforcement
    if ($dryRun -eq $true){
        $auditLogs.Add([PSCustomObject]@{
            Message = $msg
        })
    }

    if (-not($dryRun -eq $true)) {
        switch ($action){
            'Update' {
                Write-Verbose "Updating Caci-Osiris eMailAddress for: [$($p.DisplayName)]"
                $body = @{
                    e_mailadres = $account.e_mailadres
                } | ConvertTo-Json -Depth 10

                $splatParams = @{
                    Url         = "$($config.BaseUrl)/student/contactgegevens"
                    Method      = 'PUT'
                    Body        = $body
                    Headers     = $headers
                    ContentType = 'application/json'
                }
                $responseUpdateUser = Invoke-RestMethod @splatParams
                if ($responseUpdateUser.statusmeldingen[0].status -eq 'bijgewerkt'){
                    $accountReference = $responseGetUser.studentnummer
                    $success = $true
                    $auditLogs.Add([PSCustomObject]@{
                        Message = "Updated emailAddress for: [$($p.DisplayName)]"
                        IsError = $false
                    })
                }
            }

            'Exit' {
                $success = $true
                $auditLogs.Add([PSCustomObject]@{
                    Message = $msg
                    IsError = $false
                })
                break
            }
        }
    }
} catch {
    $success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
    $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-HTTPError -ErrorObject $ex
        $errorMessage = "Could not update Caci-Osiris eMail account for: [$($p.DisplayName)]. Error: $($errorObj.ErrorMessage)"
    } else {
        $errorMessage = "Could not update Caci-Osiris eMail account for: [$($p.DisplayName)]. Error: $($ex.Exception.Message)"
    }
    Write-Verbose $errorMessage
    $auditLogs.Add([PSCustomObject]@{
        Message = $errorMessage
        IsError = $true
    })
} finally {
    $result = [PSCustomObject]@{
        Success   = $success
        Account   = $account
        Auditlogs = $auditLogs
    }
    Write-Output $result | ConvertTo-Json -Depth 10
}
