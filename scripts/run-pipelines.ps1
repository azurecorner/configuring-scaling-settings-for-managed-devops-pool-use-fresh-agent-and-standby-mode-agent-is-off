param(
    [string]$organization="datasynchro",
    [string]$project="test-managed-devops-pools",
    [string]$definitionName="managed-devops-pools-scaling-ubuntu",
    [string]$pat="xxxxxxxxxx"
)

# Encode the PAT for use in the Authorization header
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
    "Content-Type" = "application/json"
}

# Get the list of all build definitions
$definitionsUrl = "https://dev.azure.com/$organization/$project/_apis/build/definitions?api-version=7.1-preview.7"
$responseDefinitions = Invoke-RestMethod -Uri $definitionsUrl -Method Get -Headers $headers #-Body "{}"

# Find the definition ID by name
$definitionId = ($responseDefinitions.value | Where-Object { $_.name -eq $definitionName }).id

if (-not $definitionId) {
    Write-Output "Build definition with name '$definitionName' not found."
    return
}


$pipelineId=$definitionId

# Define the URL to trigger the pipeline
$url = "https://dev.azure.com/$organization/$project/_apis/pipelines/$pipelineId/runs?api-version=7.0"

# Trigger the pipeline 10 times
$buildIds = @()
for ($i = 1; $i -le 10 ; $i++) {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body "{}"
    Write-Host "Triggered pipeline run # $($response.id)"
   
    $buildIds += $response.id

    Write-Host "Triggered pipeline response: $($response | ConvertTo-Json -Depth 100)"
}

# Create a custom object to return both values
$result = [PSCustomObject]@{
    BuildIds      = $buildIds
    DefinitionId  = $definitionid
}

# Return the custom object
return $result