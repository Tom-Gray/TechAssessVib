
configuration VibServer {
    param(
        $computerName = 'localhost',
        $AppLocation = "C:\app",
        [PsCredential] $SA_DSCRunAsCred

    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Modulename xWebadministration -moduleversion '2.2.0.0' 
    Import-DscResource -Modulename cChoco
    Import-DscResource -ModuleName SqlServerDsc -moduleversion '12.1.0.0' 


 

    Node $computername {

        LocalConfigurationManager
        {
             CertificateId = $node.Thumbprint
             RebootNodeIfNeeded = $false
        }

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



    
        #install data tier. This will take aw while.
        #The SQL Installer cannot run under the SYSTEM account so we'll use the administrative Vagrant user for now.
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

        cChocoPackageInstaller dotnetcore-sdk 
        {
            Name        = "dotnetcore-sdk"
            DependsOn   = "[cChocoInstaller]installChoco"
            Version     = " 2.1.500"
        }


        #create a database called 'Data' that our app will talk to.
        SqlDatabase CreateDatabase 
        {
            Servername      = $computerName
            InstanceName    = 'SQLEXPRESS'
            Name            = 'Data'
            Ensure          = 'Present'
            DependsOn       = '[cChocoPackageInstaller]SQLEXPRESS'
            PsDscRunAsCredential      = $SA_DSCRunAsCred
        }

        #Create Data in the database for the app to query
        SqlScriptQuery Create_Data
        {
            ServerInstance       = "$computername\SQLEXPRESS"

            GetQuery             = "SELECT Name FROM data.information_schema.tables WHERE table_name = 'data' FOR JSON AUTO"
            
            TestQuery            = "USE Data;if (select count(TABLE_NAME) from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'data') = 0
                                    BEGIN
                                        RAISERROR('No Data Found. Creating....', 16, 1)
                                    END"
            
           
            SetQuery             = "USE Data create table dbo.data (id int PRIMARY KEY CLUSTERED); alter table dbo.data ADD messages varchar(20) NULL
                                    GO
                                    use data; insert into dbo.data values (1,'HelloVibrato') "
            QueryTimeout = 120 #slow laptop, long timeout.


        }


        #compiling\publishing the app directly into the image, which feels cleaner
        #than having the compiled code in source control.
        #I dont think that Config Management code should do application deployments,
        #But I have contraints here so this will have to work for now.
        Script PublishApp {
            GetScript =  {{Return @{Result=""}}}

            #Check to see if the app config file is already there
            TestScript = { 
                if (Test-Path C:\app\web.config) {
                    return $true
                }
                else {
                    return $false
                }
                }
            #If there is no files present, we enter the SET Script which calls the dotnet publish command.
            #This makes the assumption that the .NET code is tested and will actually compile!    
            SetScript = { 
                try {
                    dotnet publish C:\vagrant_data\app\VibApp.sln -o C:\app
                }
                Catch {
                    write-error $_ 
                    Throw
                }
            }
            


        }
        
        


        #Create the AppPool and IIS Site to run the App.
        xWebAppPool VirbAppPool
        {
            Name = "VirbAppPool"
            Ensure = "Present"
            State = "started"
            IdentityType = "SpecificUser"
            Credential = $SA_DSCRunAsCred #run the app pool as vagrant user so the app has permission to the database
                        
        }

        xWebsite AppSite
        {
            Name = "VibApp"
            PhysicalPath = $AppLocation
            State = "Started"
            Ensure = "present"
            ApplicationPool = "VirbAppPool"
            
        }

        #after the instalaion of the dotnet core hosting runtime, the IIS service needs to be restarted
        #before it will serve an application. 
        #Here is a really hacky way to restart one time, rather than every time this config is applied.
        script RestartIISOneTime {
            TestScript = 
            {
                if (test-path C:\RestartOnce.txt) {
                    return $true
                } 
                else {
                    return $false
                }
            }


            SetScript = 
            {  
                cmd /c iisreset
                "restartFlag" | out-file C:\RestartOnce.txt
            }    
            
            GetScript = 
            {
                {Return @{Result=""}}
            }

            }

    
        




    }

}



#VibServer -configurationData $configData -SA_DSCRunAsCred $SA_DSCRunAsCred
#We have the specifically set this so DSC will let use use a plaintext password in the script.
write-verbose "using cred:  $SA_DSCRunAsCred"
$configdata = 
@{
    AllNodes = @(
    @{
        Nodename = 'localhost'
        Thumbprint = '04CEDBFDADC5838D1F501901F4D33BDA079DC635'
        CertificateFile = "C:\vagrant_data\DscPublicKey.cer"
            }
    )
 }


