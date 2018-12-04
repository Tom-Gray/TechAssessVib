
configuration VibServer {
    param(
        $computerName = 'localhost',
        $AppLocation = "C:\app"
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Modulename xWebadministration




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




    }

}

#generate .mof and appy configuration when this script executed by the vagrant shell provisioner
VibServer 
Start-DscConfiguration -path ./Vibserver -wait -verbose
