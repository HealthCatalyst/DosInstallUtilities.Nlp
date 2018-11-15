<#
.SYNOPSIS
CreateSecretsForNlp

.DESCRIPTION
CreateSecretsForNlp

.INPUTS
CreateSecretsForNlp - The name of CreateSecretsForNlp

.OUTPUTS
None

.EXAMPLE
CreateSecretsForNlp

.EXAMPLE
CreateSecretsForNlp


#>
function CreateSecretsForNlp() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
    )

    Write-Verbose 'CreateSecretsForNlp: Starting'

    Set-StrictMode -Version latest
    # stop whenever there is an error
    $ErrorActionPreference = "Stop"

    CreateNamespaceIfNotExists -namespace $namespace

    [string] $smtpRelayPassword = $(ReadSecretPassword -secretname "smtprelaypassword" -namespace "default")
    if ([string]::IsNullOrEmpty($smtpRelayPassword)) {
        AskForPasswordAnyCharacters -secretname "smtprelaypassword" -prompt "Please enter SMTP relay password" -namespace $namespace
    }
    else {
        SaveSecretPassword -secretname "smtprelaypassword" -namespace $namespace -value $smtpRelayPassword
    }

    $dnshostname = $(ReadSecretValue -secretname "dnshostname" -namespace "default")
    SaveSecretValue -secretname "nlpweb-external-url" -valueName "value" -value "nlp.$dnshostname" -namespace $namespace
    SaveSecretValue -secretname "jobserver-external-url" -valueName "value" -value "nlpjobs.$dnshostname" -namespace $namespace

    $secret = "mysqlrootpassword"
    GenerateSecretPassword -secretname "$secret" -namespace "$namespace"
    $secret = "mysqlpassword"
    GenerateSecretPassword -secretname "$secret" -namespace "$namespace"

    Write-Verbose 'CreateSecretsForNlp: Done'

}

Export-ModuleMember -Function 'CreateSecretsForNlp'