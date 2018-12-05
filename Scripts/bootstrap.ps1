
#install nuget package provider (for Powershell module installation)
if (!(Get-PackageProvider -name nuget)) {
    try {
    Write-Host "Installing NuGet Package Provider"
    Install-PackageProvider -Name 'NuGet' -Force -Verbose
    }

    catch {
        write-error -Message $_
        throw 10
    }
}


#DSC will require these modules:
install-module xWebAdministration -force -RequiredVersion '2.2.0.0'  -verbose  
install-Module cChoco -force -verbose
Install-Module SqlServerDsc -force -RequiredVersion '12.1.0.0' -verbose