
#install chocolately package manager
if (!(get-command choco)) {
    
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

catch {
    Write-Error -Message $_
    throw 10
}



}


#install nuget package provider (for Powershell module installation)
if (!(Get-PackageProvider -name nuget)) {
    try {
    Install-PackageProvider -Name 'NuGet' -Force -Verbose
    }

    catch {
        write-error -Message $_
        throw 10
    }
}


#DSC will require these modules:
install-module xWebAdministration -force -RequiredVersion '2.2.0.0'    
install-Module cChoco -force