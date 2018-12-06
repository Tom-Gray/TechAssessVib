

#turn off windows defender to speed things up a bit
Set-mppreference -DisableRealTimeMonitoring $true -verbose



#copy modules into the host rather than download them from the web, which is proving unreliable
try {
Copy-Item "C:\vagrant_data\Modules\" -destination "C:\Program Files\WindowsPowershell" -force -recurse 
}

catch {
    throw
}



#import  certificate so DSC can decode credentials.
$certPassword = 'Password1' | convertto-securestring -force -AsPlainText
Import-PfxCertificate -FilePath C:\vagrant_data\DscPrivateKey.pfx -Password $certPassword -CertStoreLocation "Cert:\LocalMachine\My" -verbose