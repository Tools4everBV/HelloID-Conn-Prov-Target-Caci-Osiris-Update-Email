##########################################################
# HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email-Create
#
# Version: 1.0.0
##########################################################
$VerbosePreference = "Continue"

# Initialize default value's
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
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
    $headers.Add("OS-STUDENTNUMMER", $($account.studentnummer))

    Write-Verbose "Verify if Caci-Osiris account for: [$($p.DisplayName)] exists"
    $splatParams = @{
        Url     = "$($config.BaseUrl)/student/contactgegevens"
        Method  = 'GET'
        Headers = $headers
    }
    $responseGetUser = Invoke-RestMethod @splatParams

    if ($responseGetUser.studentnummer -eq $($p.ExternalId)){
        # If the eMailAddress in HelloID matches with the eMailAddress in Caci-Osiris -> Correlate
        Write-Verbose "Verifying if the emailAddress for: [$($p.DisplayName)] must be updated"
        if ($responseGetUser.e_mailadres -eq $account.e_mailadres){
            $action = 'Correlate'
            # If the eMailAddress in HelloID differs from the eMailAddress in Caci-Osiris -> Correlate-Update
        } elseif ($responseGetUser.e_mailadres -ne $account.e_mailadres){
            $action = 'Correlate-Update'
        }

        $msg = "$action Caci-Osiris eMail account for: [$($p.DisplayName)] will be executed during enforcement"
    }

    # Add an auditMessage showing what will happen during enforcement
    if ($dryRun -eq $true){
        $auditLogs.Add([PSCustomObject]@{
            Message = $msg
            IsError = $false
        })
    }

    # Process
    if (-not($dryRun -eq $true)){
        switch ($action){
            'Correlate' {
                Write-Verbose "Correlating Caci-Osiris account for: [$($p.DisplayName)]"
                $accountReference = $responseGetUser.studentnummer
                $success = $true
                $auditLogs.Add([PSCustomObject]@{
                    Message = "Correlated Caci-Osiris account for: $($p.DisplayName)"
                    IsError = $false
                })
                break
            }

            'Correlate-Update' {
                Write-Verbose "Correlating and updating Caci-Osiris account for: [$($p.DisplayName)]"
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
                        Message = "Correlated Caci-Osiris eMail account and updated emailAddress for: [$($p.DisplayName)]"
                        IsError = $false
                    })
                }
            }
        }
    }
} catch {
    $success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
    $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-HTTPError -ErrorObject $ex
        $errorMessage = "Could not $action Caci-Osiris eMail account for: [$($p.DisplayName)]. Error: $($errorObj.ErrorMessage)"
    } else {
        $errorMessage = "Could not $action Caci-Osiris eMail account for: [$($p.DisplayName)]. Error: $($ex.Exception.Message)"
    }
    Write-Verbose $errorMessage
    $auditLogs.Add([PSCustomObject]@{
        Message = $errorMessage
        IsError = $true
    })
# End
} finally {
   $result = [PSCustomObject]@{
        Success          = $success
        AccountReference = $accountReference
        Auditlogs        = $auditLogs
        Account          = $account
    }
    Write-Output $result | ConvertTo-Json -Depth 10
}
