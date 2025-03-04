##################################################
# HelloID-Conn-Prov-Target-Caci-Osiris-Update-Email-Delete
# PowerShell V2
##################################################

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

    if ($null -ne $correlatedAccount) {
        $action = 'DeleteAccount'
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'DeleteAccount' {

            Write-Information "Deleting Caci-Osiris Email address of accountReference: [$($actionContext.References.Account)]"
            $body = @{
                p_studentnummer = $actionContext.References.Account
                p_e_mail_adres = $null
            } | ConvertTo-Json -Depth 10

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
                Write-Information "[DryRun] Deleting Caci-Osiris-Update-Email account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Update account was successful, Account property updated: EmailAddress]"
                    IsError = $false
                })
            break    
        }

        'NotFound' {
            Write-Information "Caci-Osiris-Update-Email account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Caci-Osiris-Update-Email account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $false
                })
            break
        }
    }
} catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Caci-Osiris-Update-EmailError -ErrorObject $ex
        $auditMessage = "Could not remove Caci-Osiris email account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not remove Caci-Osiris email account. Error: $($_.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}