Initial commit!

The brief states I should "Choose the platforms, frameworks and languages you're most familiar with." Which for me is the Windows which unfortunately means huge downloads and install times.


- Windows Server 2016
- IIS and ASP.NET core
- MSSQL Express
- Vagrant - the Windows box will be about 5gb. Sorry! Larry Smith has up-to-date Windows boxes https://github.com/mrlesmithjr/packer-templates
- Basic ASP.NET core app to return data from the database to the user. (first time writing asp.net core so it's going to be... simple.)

I have been playing with Puppet and Ansible the last couple of weeks but I'm not confident I cant use them as effectively as Powershell DSC, so we'll roll with DSC. 

## Rough plan:

1. Vagrant will launch a vanilla install of Server 2016. We'll need to bootstrap a few things:
    - Chocolately package manager
    - Nuget package manager
    - Some DSC modules for managing IIS and SQL 

2. With those installed, DSC can install and configure IIS, SQLExpress and the .NET core runtime. 


3. Create a database and populate it with a table and some data. 


4. Deploy the .NET Core web app in there to respond to requests with a record from the  database




## Notes after completion

I managed to stick mostly to the plan. I'm not sure how much commentary I'm supposed to provide but hopefully the comments and commit messages are descriptive enough to get the general gist of where I changed direction and why.

Its not mentioned in the brief but I tried to make it idempotent so you can run `vagrant provision` multiple times and not have errors.


Late in the piece I tried to move all credentials out of the scripts and into the vagrantfile. Doing in this way allows the passwords to be retrieved at runtime from a proper, secure source. (Env:Vars,CI\CD tool, AWS Param store, etc ).  This ramped up the complexity a little bit. Which is something I was comfortable with in DSC but probably not Puppet or Ansible. 

This took me a bit longer than 4 hours but a lot of that was waiting for Windows to boot and SQL to install. 


## How to Launch

- Clone this repo
- Navigate to the directory containing the Vagrantfile
- run `vagrant up`
- wait a while. 
- You've got a 5gb box to download and a Windows box to configure. Seriously go have lunch.
- When vagrant is complete, browse to http://192.168.58.64 



## Bugs

I've allocated 4Gb of RAM to the VM as I found on occasion it would hard-reboot during the installation of SQL. In the event this happens again, the VM will reboot and finish configuring, however Vagrant will lose track of the log output. It should be fine on any recent hardware.  