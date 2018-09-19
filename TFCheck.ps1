#Generate show.out file
.\terraform.exe show > .\show.out

#Security Checks
$Content = Get-Content ".\show.out"
$FileLocation = ".\show.out"
$Sections = @()
$Objects = New-Object PSCustomObject

#Function which breaks up each object into a separate string for security processing.
function GetSections (){
    $StartPoints = @()
    $Sections = @()
    ForEach($Line in $Content){
        if($Line.Substring(0,2) -ne "  " -and $Line.SubString($Line.length -1, 1) -eq ":"){
            $StartPoints += $Content | Select-String $Line.SubString(2) | Select-Object -ExpandProperty 'LineNumber' #Used $Line.SubString(2) to fix error with character on first line of file
            }
        }
    ForEach($Start in $StartPoints){
        if($StartPoints[($StartPoints.IndexOf($Start) + 1)] -gt $StartPoints[($StartPoints.IndexOf($Start))]){ #Checks if the next array is higher than the current one
            $Sections += (Get-Content $FileLocation)[($Start - 1) .. ($StartPoints[($StartPoints.IndexOf($Start)+1)]-2)] | out-string
            }
        }
    $Sections += (Get-Content $FileLocation)[(($Start[-1])-1) .. ($Content.length-2)] | out-string
    Return $Sections
    }

#Function which parses each object into a custom powershell object for security analysis
function ParseSections ($Sections){
    ForEach ($Section in ($Sections)){
        $SectionObject = @() #Creates a custom powershell object to store the values parsed in each section
        $Data = $Section -split "\r\n"
        $Data = $Data | ? {$_} #Removes blank lines/array elements
        ForEach ($Line in $Data){ #loops through each line in a section
            $Path = ($Line.split('='))[0] #Splits one statement into 2 arrays based on " = " delimeter, e.g. location = canadacentral, becomes @(location,canadacentral)
            $FullStopCount = ([regex]::Matches($Path, '\.' )).count #Counts the number of full stops in a statement property. E.g. private_ip_addresses.0 has 1 dot. This is to fix json formatting below.
            $Path = ($Path -replace '\.','":{"').Trim() #Trims blank characters etc. from string
            try{$Value = ($Line.split('='))[1].Trim()} catch{} #Trims blank characters etc. from string. Needs to be 'try' because the object declaration doesn't contain ' = '.
            $PropertyArray = "{""" + $Path + """:" + '"' + $Value + '"' + "}" + "}"*$FullStopCount #Builds Json formatted string based on variables in this line
            $Converted = $PropertyArray | ConvertFrom-Json #Creates powershell object based on Json formatted string
            $SectionObject += $Converted #Adds the powershell object for this line to the powershell object for the section
            }
        $tempName = ($SectionObject.name | Out-String).Trim() #Reads the resource name
        $Objects | Add-Member -MemberType NoteProperty -Name $tempName -Value $SectionObject -Force #Adds the section object to the global object, and names is by resource name
        }
    Return $Objects
    }

try{
    Write-Host "------------------------------------------------------------------------"
    Write-Host "Security Checks"
    Write-Host "------------------------------------------------------------------------"
    Write-Host "Parsing show.out"
    try{$Sections = GetSections}
    catch{Write-Host  "Error Getting Sections: "$_.Exception.Message}
    try{$Objects = ParseSections ($Sections)}
    catch{Write-Host  "Error Parsing Objects: "$_.Exception.Message}
    Write-Host "Objects identified: $($Sections.length)"
    
    ############Write your security rules here###########
    
}
catch{
    Write-Host "Error in security analysis script, please notify security@company.com : $error[0]"
}
"------------------------------------------------------------------------"
