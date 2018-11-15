<#
.SYNOPSIS
ShowNlpMenu

.DESCRIPTION
ShowNlpMenu

.INPUTS
ShowNlpMenu - The name of ShowNlpMenu

.OUTPUTS
None

.EXAMPLE
ShowNlpMenu

.EXAMPLE
ShowNlpMenu


#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function ShowNlpMenu()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $baseUrl
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $local
        ,
        [bool]
        $isAzure = $true
    )

    Write-Verbose 'ShowNlpMenu: Starting'

    $userinput = ""
    while ($userinput -ne "q") {
        Write-Host "================ $namespace menu ================"
        Write-Host "------ Install -------"
        Write-Host "1: Install $namespace"
        Write-Host "------ Status --------"
        Write-Host "2: Show status of $namespace"
        Write-Host "3: Show $namespace urls & passwords"
        Write-Host "5: Show $namespace detailed status"
        Write-Host "6: Show $namespace logs"
        # Write-Host "8: Show DNS entries for /etc/hosts"
        Write-Host "9: Troubleshoot Ingresses"
        Write-Host "11: Show commands to SSH to $namespace containers"
        Write-Host "------ Delete data --------"
        Write-Host "12: Delete all data in $namespace"
        Write-Host "------ Testers --------"
        Write-Host "-----------"
        Write-Host "q: Go back to main menu"
        $userinput = Read-Host "Please make a selection"
        switch ($userinput) {
            '1' {
                $packageUrl = $kubeGlobals.realtimePackageUrl
                if ($local) {
                    $packageUrl = "$here\..\..\..\helm.nlp\fabricnlp"
                    Write-Host "Loading package from $packageUrl"
                }
                $VerbosePreference = 'Continue'

                InstallNlp -namespace $namespace -package "fabricnlp" -packageUrl $packageUrl -local $local -isAzure $isAzure
            }
            '2' {
                kubectl get 'deployments,pods,services,ingress,secrets,persistentvolumeclaims,persistentvolumes,nodes' --namespace=$namespace -o wide
            }
            '3' {
                $loadBalancerIPResult = $(GetLoadBalancerIPs)
                $loadBalancerIP = $loadBalancerIPResult.ExternalIP
                $loadBalancerInternalIP = $loadBalancerIPResult.InternalIP

                Write-Host "Solr UI is at http://$loadBalancerInternalIP/solr in the web browser"
                Start-Process -FilePath "http://$loadBalancerInternalIP/solr";
                Write-Host "NLP web UI is at http://$loadBalancerIP/nlpweb in the web browser (ndepthuser/password)"
                Start-Process -FilePath "http://$loadBalancerIP/nlpweb";
                Write-Host "NLP job UI is at http://$loadBalancerIP/nlp in the web browser"
                Start-Process -FilePath "http://$loadBalancerIP/nlp";

                $secrets = $(kubectl get secrets -n $namespace -o jsonpath="{.items[?(@.type=='Opaque')].metadata.name}")
                Write-Host "All secrets in $namespace : $secrets"
                WriteSecretPasswordToOutput -namespace $namespace -secretname "mysqlrootpassword"
                WriteSecretPasswordToOutput -namespace $namespace -secretname "mysqlpassword"
                WriteSecretPasswordToOutput -namespace $namespace -secretname "smtprelaypassword"
                WriteSecretValueToOutput  -namespace $namespace -secretname "jobserver-external-url"
                WriteSecretValueToOutput  -namespace $namespace -secretname "nlpweb-external-url"
            }
            '5' {
                ShowStatusOfAllPodsInNameSpace "$namespace"
            }
            '6' {
                ShowLogsOfAllPodsInNameSpace "$namespace"
            }
            '9' {
                TroubleshootIngress "$namespace"
            }
            '11' {
                ShowSSHCommandsToContainers -namespace $namespace
            }
            '12' {
                Write-Warning "This will delete all data in this namespace and clear out any secrets"
                Do { $confirmation = Read-Host "Do you want to continue? (y/n)"}
                while ([string]::IsNullOrWhiteSpace($confirmation))

                if ($confirmation -eq "y") {

                    DeleteHelmPackage -package $namespace -Verbose

                    if($isAzure){

                        DeleteNamespaceAndData -namespace "$namespace" -isAzure $isAzure -Verbose
                    }
                    else
                    {
                        CleanOutNamespace -namespace $namespace

                        if ($isAzure) {
                            DeleteAzureStorage -namespace $namespace
                        }
                        else {
                            DeleteOnPremStorage -namespace $namespace
                        }

                        DeleteAllSecretsInNamespace -namespace $namespace -Verbose
                    }
                }
            }
            'q' {
                return
            }
        }
        $userinput = Read-Host -Prompt "Press Enter to continue or q to go back to top menu"
        if ($userinput -eq "q") {
            return
        }
        [Console]::ResetColor()
        Clear-Host
    }

    Write-Verbose 'ShowNlpMenu: Done'

}

Export-ModuleMember -Function 'ShowNlpMenu'