Initial commit!

The brief states I should "Choose the platforms, frameworks and languages you're most familiar with." Which for me is the Windows which unfortunately means huge downloads and install times.


- Windows Server 2016
- IIS and ASP.NET core
- MSSQL Express
- Vagrant - the Windows box will be about 5gb. Sorry! Larry Smith has up-to-date Windows boxes https://github.com/mrlesmithjr/packer-templates
- Basic ASP.NET core app to return data from the database to the user.

I have been playing with Puppet and Ansible the last couple of weeks but I'm not confident I cant use them as effectively as Powershell DSC, so we'll roll with DSC. 

## Rough plan:

1. Vagrant will launch a vanilla install of Server 2016. We'll need to bootstrap a few things:
    - Chocolately package manager
    - Nuget package manager
    - Some DSC modules for managing IIS and SQL 

2. With those installed, DSC can install and configure IIS, SQLExpress and the .NET core runtime. 


3. Create a database and populate it with a table and some data. 


4. Deploy the .NET Core web app in there to respond to requests with a record from the  database


