<#
.SYNOPSIS
InstallNlp

.DESCRIPTION
InstallNlp

.INPUTS
InstallNlp - The name of InstallNlp

.OUTPUTS
None

.EXAMPLE
InstallNlp

.EXAMPLE
InstallNlp


#>
function InstallNlp() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $environmentName
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $package
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $packageUrl
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $local
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $isAzure
    )

    Write-Verbose 'InstallNlp: Starting'
    Set-StrictMode -Version latest
    $ErrorActionPreference = 'Stop'

    CreateSecretsForNlp -namespace $namespace -Verbose

    if ($isAzure) {
        CreateAzureStorage -namespace $namespace
    }
    else {
        CreateOnPremStorage -namespace $namespace
    }

    Write-Output "Removing old deployment for $package"
    DeleteHelmPackage -package $package

    if ($namespace -ne "kube-system") {
        CleanOutNamespace -namespace $namespace
    }

    Write-Host "Installing product from $packageUrl into $namespace"

    # you can also set slackUrl in the helm install below
    [int] $monitoringSleepInterval = 300
    [int] $monitoringIntervalBetweenMessages = 3600

    if ($isAzure) {
        helm install $packageUrl `
            --name $package `
            --set environmentName=$environmentName `
            --set-string monitoringSleepInterval='"'$monitoringSleepInterval'"' `
            --set-string monitoringIntervalBetweenMessages='"'$monitoringIntervalBetweenMessages'"' `
            --namespace $namespace `
            --debug
    }
    else {
        helm install $packageUrl `
            --name $package `
            --set environmentName=$environmentName `
            --set-string monitoringSleepInterval='"'$monitoringSleepInterval'"' `
            --set-string monitoringIntervalBetweenMessages'"'$monitoringIntervalBetweenMessages'"' `
            --namespace $namespace `
            --set onprem=true `
            --debug
    }

    Write-Verbose "Listing packages"
    [string] $failedText = $(helm list --failed --output json)
    if (![string]::IsNullOrWhiteSpace($failedText)) {
        Write-Error "Helm package failed"
    }
    $(helm list)

    WaitForPodsInNamespace -namespace $namespace -interval 5 -Verbose

    # read tcp ports and update ngnix with those ports
    SetTcpPortsForStack -namespace $namespace -Verbose

    Write-Verbose 'InstallNlp: Done'
}

Export-ModuleMember -Function 'InstallNlp'