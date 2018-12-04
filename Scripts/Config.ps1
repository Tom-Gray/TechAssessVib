
configuration VibServer {
    param(
        $computerName = 'localhost',
        $AppLocation = "C:\app"
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Modulename xWebadministration
    Import-DscResource -Modulename cChoco
    Import-DscResource -ModuleName SqlServerDsc




    Node $computername {

        WindowsFeature Web-Server            { Ensure = 'Present'; Name = 'Web-Server' }
        WindowsFeature Web-Mgmt-console      { Ensure = 'Present'; Name = 'Web-Mgmt-Console' }


        #we'll put our asp.net app here
        file AppLocation {
            DestinationPath = $AppLocation
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        #remove the default site so that it returns a non-200 status code.
        #A theoretical load balancer will not send
        #any traffic to this host until it is ready.
        xWebsite RemoveDefaultSite
        {
            Ensure          = "Absent"
            Name            = "Default Web Site"
            State           = "Stopped"
        }


        cChocoInstaller installChoco
        {
            InstallDir = "$env:programdata\choco"
        }

        #install data tier. This will take aw while.
        cChocoPackageInstaller SQLEXPRESS 
        {
            Name        = "7zip"
            DependsOn   = "[cChocoInstaller]installChoco"
            Version     = "14.1801.3958.1"
        }

        #the dotnet windowshosting package is required to run ASP.NET Core apps on IIS.
        cChocoPackageInstaller dotnet-IIS-Runtime 
        {
            Name        = "dotnetcore-windowshosting"
            DependsOn   = "[cChocoInstaller]installChoco"
            Version     = "2.1.6"
        }


        #create a database called 'Data' that our app will talk to.
        SqlDatabase CreateDatabase 
        {
            Servername      = 'localhost'
            InstanceName    = 'MSSQLSERVER'
            Name            = 'Data'
            Ensure          = 'Present'
            DependsOn       = '[cChocoPackageInstaller]SQLEXPRESS'
        }






    }

}

#generate .mof and appy configuration when this script executed by the vagrant shell provisioner
VibServer 
Start-DscConfiguration -path ./Vibserver -wait -verbose
