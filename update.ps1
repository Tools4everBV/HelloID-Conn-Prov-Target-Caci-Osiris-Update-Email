#################################################
# HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email-Update
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-Caci-Osiris-Update-EmailError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            # $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
        } catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }   

    $headers = @{}
    $headers.Add("Api-Key", $actionContext.configuration.ApiKey)

    Write-Information "Verify if Caci-Osiris account for: [$($actionContext.References.Account)] exists"
    $splatParams = @{
        Uri     = "$($actionContext.configuration.BaseUrl)/basis/student?p_studentnummer=$($actionContext.References.Account)"
        Method  = 'GET'
        Headers = $headers
    }
    $correlatedAccount = Invoke-RestMethod @splatParams    
    $outputContext.PreviousData = $correlatedAccount

    # Always compare the account against the current account in target system
    if ($null -ne $correlatedAccount) {
        if ($correlatedAccount.e_mailadres -ne $actionContext.Data.p_e_mail_adres){
               $action = 'UpdateAccount'
        } else {
            $action = 'NoChanges'
        }
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'UpdateAccount' {
            Write-Information "Updating Caci-Osiris-Update-Email account with accountReference: [$($actionContext.References.Account)]"
            Write-Information "Account property(s) required to update: p_e_mail_adres)"
            $actionContext.Data.p_studentnummer = $actionContext.References.Account
            $body = $actionContext.Data | ConvertTo-Json -Depth 10
            if (-not($actionContext.DryRun -eq $true)) {
                $splatParams = @{
                    Uri         = "$($actionContext.configuration.BaseUrl)/basis/student/update_account"
                    Method      = 'PUT'
                    Body        = $body
                    Headers     = $headers
                    ContentType = 'application/json'
                }
                $responseUpdateUser = Invoke-RestMethod @splatParams
                if ($responseUpdateUser.statusmeldingen.Count -gt 0) {
                    throw "$($responseUpdateUser.statusmeldingen[0].tekst)"
                }
            } else {
                Write-Information "[DryRun] Update Caci-Osiris-Update-Email account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Update account was successful, Account property updated: EmailAddress]"
                    IsError = $false
                })
            break      
        }

        'NoChanges' {
            Write-Information "No changes to Caci-Osiris-Update-Email account with accountReference: [$($actionContext.References.Account)]"

            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = 'No changes will be made to the account during enforcement'
                    IsError = $false
                })
            break
        }

        'NotFound' {
            Write-Information "Caci-Osiris-Update-Email account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $false
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Caci-Osiris-Update-Email account with accountReference: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $true
                })
            break
        }
    }
} catch {
    $outputContext.Success  = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Caci-Osiris-Update-EmailError -ErrorObject $ex
        $auditMessage = "Could not update Caci-Osiris email. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not update Caci-Osiris email. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
