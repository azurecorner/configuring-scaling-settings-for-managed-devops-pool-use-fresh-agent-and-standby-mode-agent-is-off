param(  [string]$organization="datasynchro",
        [string]$project="test-managed-devops-pools",
        [int]$definitionId=48,
        [array]$buildIds=@(1518),
        [string]$pat="xxxxxx",
        [string]$mdpScalingOption="CONFIGURATION_A",
        [string]$description='Pool Maximum agents = 5 && Agent state = Fresh agent every time   &&  standby agents mode  = off && running 5 builds'
 )

write-host "Organization: $organization"
write-host "Project: $project"
write-host "Definition ID: $definitionId"
write-host "BUILD IDS: $buildIds"


# Encode the PAT for use in the Authorization header
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
    "Content-Type" = "application/json"
}

$reportResult = @()
$buildIds | ForEach-Object {

$buildId = $_


# Wait for the build to complete
$buildStatusUrl = "https://dev.azure.com/$organization/$project/_apis/build/builds/$($buildId)?api-version=7.1-preview.7"

$buildResponse=$()
do {
    $buildResponse = Invoke-RestMethod -Uri $buildStatusUrl -Method Get -Headers $headers # -Body "{}"
    $status = $buildResponse.status
    Write-Output "Build ID $buildId status: $status on $(Get-Date)"
    
    # Sleep for a few seconds before checking again
    if ($status -ne "completed") {
    Start-Sleep -Seconds 30
    }

} while ($status -ne "completed")


$buildId = $buildResponse.id
$queueTime = $buildResponse.queueTime
$startTime = $buildResponse.startTime
$finishTime = $buildResponse.finishTime
$delayInSeconds = 0
$durationInSeconds = 0
# Calculate the duration if both startTime and finishTime are available
if ($startTime -and $finishTime) {
    $duration = (Get-Date $finishTime) - (Get-Date $startTime) 
    $durationInSeconds = $duration.TotalSeconds
} else {
    $duration = "N/A"
}

if ($queueTime -and $startTime) {
    $delay = (Get-Date $startTime) - (Get-Date $queueTime)
    $delayInSeconds = $delay.TotalSeconds
} else {
    $delay = "N/A"
}

Write-Output "-----------------------------------"
Write-Output "Triggered build with ID: $buildId"
Write-Output "Delay: $delay"
Write-Output "Duration: $duration"

Write-Output "delayInSeconds: $delayInSeconds"
Write-Output "durationInSeconds: $durationInSeconds"

Write-Output "Trigger Time: $queueTime"
Write-Output "Start Time: $startTime"
Write-Output "Finish Time: $finishTime"


# Define the URL to get the timeline (which includes job information)
$logsUrl = $buildResponse.logs.url + "?api-version=7.1"

# Get the timeline which includes job details
$logResponse = Invoke-RestMethod -Uri $logsUrl -Method Get -Headers $headers

# Initialize the dictionary to hold the results
$result = @{}
$result['scalingOption']=$mdpScalingOption
$result['description']=$description
$result['buildId']=$buildId
$result['result']=$buildResponse.result

# Process the timeline to find agent details
$logResponse.value | ForEach-Object {

    # Trigger the build
    $logText = Invoke-RestMethod -Uri $_.url -Method Get -Headers $headers #-Body "{}"

    # Extracting the Agent machine name (only if not already set)
    if (-not $result['AgentMachineName'] -and $logText -match "Agent machine name: '([^']+)'") {
        $result['AgentMachineName'] = $matches[1]
    }

    # Extracting the Image (only if not already set)
    if (-not $result['Image'] -and $logText -match "Image: ([^\s]+)") {
        $result['Image'] = $matches[1]
    }

    # Extracting the Version (only if not already set)
    if (-not $result['Version'] -and $logText -match "Version: ([^\s]+)") {
        $result['Version'] = $matches[1]
    }

    # Extracting the Current agent version (only if not already set)
    if (-not $result['CurrentAgentVersion'] -and $logText -match "Current agent version: '([^']+)'") {
        $result['CurrentAgentVersion'] = $matches[1]
    }

    # Extracting the Agent name (only if not already set)
    if (-not $result['AgentName'] -and $logText -match "Agent name: '([^']+)'") {
        $result['AgentName'] = $matches[1]
    }

    # Extracting the SKU (only if not already set)
    if (-not $result['SKU'] -and $logText -match "SKU: ([^\s]+)") {
        $result['SKU'] = $matches[1]
    }

    # Extracting the Image Version (only if not already set)
    if (-not $result['ImageVersion'] -and $logText -match "Image Version: ([^\s]+)") {
        $result['ImageVersion'] = $matches[1]
    }

}

$result['queueTime']=$queueTime
$result['startTime']=$startTime
$result['finishTime']=$finishTime


$jsonResult = $result | ConvertTo-Json -Depth 10
Write-Output $jsonResult

$reportResult += $result
}

$reportJsonResult = $reportResult | ConvertTo-Json -Depth 10
# Write JSON to a file
$jsonFilePath = "report_$($mdpScalingOption)_$($definitionId).json"
$reportJsonResult | Out-File -FilePath $jsonFilePath -Encoding utf8


 # Output file content to GitHub Actions log for verification
 Write-Output "JSON file content:"
 Get-Content -Path $jsonFilePath

 # to csv   
# Convertir chaque hashtable en PSCustomObject
$reportResult = $reportResult | ForEach-Object {
    [PSCustomObject]$_
}

 # Convert to CSV and write to a file
$csvFilePath = "report_$($mdpScalingOption)_$($definitionId).csv"
$reportResult | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding utf8

# Output file content to GitHub Actions log for verification
Write-Output "CSV file content:"
Get-Content -Path $csvFilePath