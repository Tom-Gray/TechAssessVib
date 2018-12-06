
configuration VibServer {
    param(
        $computerName = 'localhost',
        $AppLocation = "C:\app"
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Modulename xWebadministration -moduleversion '2.2.0.0' 
    Import-DscResource -Modulename cChoco
    Import-DscResource -ModuleName SqlServerDsc -moduleversion '12.1.0.0' 




    Node $computername {

        WindowsFeature Web-Server            { Ensure = 'Present'; Name = 'Web-Server' }
        WindowsFeature Web-Mgmt-console      { Ensure = 'Present'; Name = 'Web-Mgmt-Console' }


        #we'll put our asp.net app here


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

        #The SQL Installer cannot run under the SYSTEM account so we'll use the administrative Vagrant user for now.
        $PsDscRunAsCredentialPass = 'vagrant' | ConvertTo-SecureString -AsPlainText -Force
        $SA_DSCRunAsCred = New-Object System.Management.Automation.PSCredential('vagrant', $PsDscRunAsCredentialPass)
    
        #install data tier. This will take aw while.
        cChocoPackageInstaller SQLEXPRESS 
        {
            Name        = "sql-server-express"
            DependsOn   = "[cChocoInstaller]installChoco"
            Version     = "13.1.4001.0"
            PsDscRunAsCredential = $SA_DSCRunAsCred  
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
            Servername      = $computerName
            InstanceName    = 'SQLEXPRESS'
            Name            = 'Data'
            Ensure          = 'Present'
            DependsOn       = '[cChocoPackageInstaller]SQLEXPRESS'
        }

        #Create Data in the database for the app to query
        SqlScriptQuery Create_Data
        {
            ServerInstance       = "$computername\SQLEXPRESS"

            GetQuery             = "SELECT Name FROM data.information_schema.tables WHERE table_name = 'data' FOR JSON AUTO"
            TestQuery            = "USE Data;if (select count(TABLE_NAME) from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'data') = 0
            BEGIN
                RAISERROR('No Data Found. Creating....', 16, 1)
            END
            "
            SetQuery             = "USE Data create table dbo.data (id int PRIMARY KEY CLUSTERED); alter table dbo.data ADD messages varchar(20) NULL
            GO
            use data; insert into dbo.data values (1,'HelloVibrato') "
            QueryTimeout = 120 #slow laptop, long timeout.

            #PsDscRunAsCredential = $SA_DSCRunAsCred
        }
        
        File DeployApp
        {
            SourcePath = "C:\vagrant_data\App\Published\"
            DestinationPath = $AppLocation
            Ensure = 'Present'
            Type = "Directory"
            Recurse = $true
            Matchsource = $true
        }

        #Create the AppPool and IIS Site to run the App.
        xWebAppPool VirbAppPool
        {
            Name = "VirbAppPool"
            Ensure = "Present"
            State = "started"
            IdentityType = "SpecificUser"
            Credential = $SA_DSCRunAsCred
                        
        }

        xWebsite AppSite
        {
            Name = "VibApp"
            PhysicalPath = $AppLocation
            State = "Started"
            Ensure = "present"
            ApplicationPool = "VirbAppPool"
            
        }

    
        




    }

}

#We have the specifically set this so DSC will let use use a plaintext password in the script.

$configdata = 
@{
    AllNodes = @(
    @{
        Nodename = 'localhost'
        PSDscAllowPlainTextPassword = $true
            }
    )
 }

#generate .mof and appy configuration when this script executed by the vagrant shell provisioner
VibServer -ConfigurationData $configdata
Start-DscConfiguration -path ./Vibserver -wait -verbose -force 
