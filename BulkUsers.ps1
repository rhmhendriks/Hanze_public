# author: Ronald H.M. Hendriks
# Date: 11 may 2021
#
# Title: Active Directory user creation
#
# Description: 
# This script is used for bulk creation of users from A CSV file. 
# it is also possible to use a JSON files. 
# 
# This script also support manually adding a single user to the 
# active directory. 
#
# This script needs the following modules:
#   - ActiveDirectory
param (
    [string]$CSV = $null
    )

Import-Module ActiveDirectory
$DC="ZP07_DC01"


#-----------------Username Generator---------------------#
function GenerateUsername {
    param( [string]$FirstName, [string]$LastName, [string]$School, [string]$Role)

    ############### Poging tot rapport maken #########################
    #$reportname = Get-Date -Format "MMddyyyyHHmmssfff"
    #$reportname = $reportname+".txt"
    #New-Item -Name $reportname -ItemType "file" #CREATE REPORT FILE
    ##################################################################
    
    # Loop until username is valid or completely checked.
    $usernameOption = 1 #number of trys for username
    [bool] $notDone = $true

    while($notDone){

        # generating username
        if ($usernameOption -lt $FirstName.length){
            $userName = $FirstName.Substring(0,$usernameOption) + "." + $LastName #select number of trys in caracters from firstname and put them together for a username
        } else {
            # not username option found!
            # manual intervention needed. 
            # Administrator must enter username manually
            $userName = Read-Host -Prompt "I cant create a username for $FirstName $LastName automaticly, please enter a username:"
        }

        # Check if user with this username exists
        try{Get-ADUser $userName >> $nu;$exists=$true}catch{$exists=$false} #when user exists set True else set False
        if ($exists -ne $false) {
            # username exists
            # check if an user with the exact same properties exists
            $usernameOption++
        } else {
            # user created
            $notDone = $false
            return "$userName"
        }
    }
    
}

#Get-ADUser -filter {department -eq 'IT' -AND PhysicalDeliveryOfficeName -eq 'NewYork'}

#-----------------Parameter Checking---------------------#
Write-Host "The following CSV file will be used: $CSV" -ForegroundColor Yellow
$createreportname = Get-Date -Format "MMddyyyyHHmmssfff" # create report name with date
$createreportname = $createreportname+".txt" # Add extension

New-Item -Path . -Name $createreportname -ItemType "file" #CREATE REPORT FILE
echo "Volledige Naam `t `t Gebruikersnaam `t `t Wachtwoord " >> $createreportname # Report headlines


if($CSV -ne $null){
    Write-Host "CDV not NULL"
    #------------ CSV Importation ------------#
    
    Import-Csv $CSV | ForEach-Object {
        Write-Host $_
            # Read the personal data from the CSV
            $FirstName = $_.voornaam
            $LastName = $_.achternaam
            $School = $_.school
            $Role =  $_.functie

            # Generate username from function
            $userName = (GenerateUsername -FirstName $FirstName -LastName $LastName -School $School -Role $Role)

            # Select Right Path

            # Check for Role
            # Create AD account path
            $AccountPath=""
            if ($Role -eq "Student"){
                $AccountPath=$AccountPath+"OU=$School,OU=Students"   # for students
                $GroupName="G_Students_$School"
            } elseif ($Role -eq "Employee"){
                $AccountPath=$AccountPath+"OU=$School,OU=Employees" # for employees
                $GroupName="G_Employees_$School"
            } else {
                $AccountPath=$AccountPath+",OU=UNKNOWN" # if Role is Unknown
            }

            $AccountPath = $AccountPath+",OU=Gebruikers,DC=Hanze,DC=Hogeschool" # Add sub OU and Domain to Path

            #Generate Valid Password With Random Factor
            $plainPassword = "H@nze" # start with Default h@nze
            $random = Get-Random -Minimum 10000 -Maximum 99999 # generate random numbers
            $plainPassword = $plainPassword+$random+"!" # Add random to hanze and an ! at the end
            $password = ConvertTo-SecureString $plainPassword –asplaintext –force # make it a secure string for the AD


            # check if there is an username
            if ($userName -ne "INVALID"){
                # create user
                New-ADUser -Name $userName -GivenName "$LastName, $FirstName" -Surname "$LastName" -SamAccountName "$UserName" -Path $AccountPath -AccountPassword $password -Enabled $true
                Add-ADGroupMember -Identity $GroupName -Members $userName -Server $DC
                Set-ADUser -Identity $userName -ChangePasswordAtLogon $true 
                Write-Host "The user $FirstName $LastName has been added to the active directory. The AD-path is $AccountPath" -ForegroundColor Green
                "$FirstName $LastName `t `t $userName `t `t $plainPassword" >> $createReportName
            }            
        }

    Write-Host "'n 'n All users have been created! Review the signIn-information in the report named: $createReportName "-ForegroundColor Green


} else {
    Write-Host "Invalid Syntax: Call the script as BulkUsers.p1 -CSV <CSVFILENAME>!"
    # error message. Invalid parameters
}
