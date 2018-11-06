$module = Get-Module -Name "DosInstallUtilities.Nlp"
$module | Select-Object *

$params = @{
    'Author' = 'Health Catalyst'
    'CompanyName' = 'Health Catalyst'
    'Description' = 'Functions to create Nlp menus'
    'NestedModules' = 'DosInstallUtilities.Nlp'
    'Path' = ".\DosInstallUtilities.Nlp.psd1"
}

New-ModuleManifest @params
