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
function CreateSecretsForNlp()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
    )

    Write-Verbose 'CreateSecretsForNlp: Starting'

    CreateNamespaceIfNotExists -namespace $namespace

    CreateNamespaceIfNotExists $namespace
    AskForPasswordAnyCharacters -secretname "smtprelaypassword" -prompt "Please enter SMTP relay password" -namespace $namespace
    $dnshostname = $(ReadSecretValue -secretname "dnshostname" -namespace "default")
    SaveSecretValue -secretname "nlpweb-external-url" -valueName "value" -value "nlp.$dnshostname" -namespace $namespace
    SaveSecretValue -secretname "jobserver-external-url" -valueName "value" -value "nlpjobs.$dnshostname" -namespace $namespace

    Write-Verbose 'CreateSecretsForNlp: Done'

}

Export-ModuleMember -Function 'CreateSecretsForNlp'