# Run .\DeployPipelines.ps1 -Token "glpat-xXXXxx9x9XXxXx_XxXXx"
param (
    [string]$Token = $null
)

Write-Host "Token: $Token"

# Configure GitLab API parameters
$GITLAB_TOKEN = $Token
$PROJECT_ID = 54
$GITLAB_API_URL = "https://it-gitlab.intra.acer.com/api/v4/projects/$PROJECT_ID"
$HEADERS = @{
    "PRIVATE-TOKEN" = $GITLAB_TOKEN
}

# Define branch list
$BRANCHES = @("uatAIL", "prdAAP", "prdAIL", "prdAPIN")

# Function: Get the latest pipeline ID
function Get-LatestPipelineId {
    param (
        [string]$Branch
    )
    
    $url = "$GITLAB_API_URL/pipelines?ref=$Branch"
    $response = Invoke-RestMethod -Uri $url -Headers $HEADERS
    $pipelineId = $response | Select-Object -First 1 | ForEach-Object { $_.id }
    
    Write-Host "Latest $Branch pipeline ID: $pipelineId"
    return $pipelineId
}

# Function: Get the job ID for the build-image stage
function Get-BuildImageJobId {
    param (
        [int]$PipelineId,
        [string]$Branch
    )
    
    $url = "$GITLAB_API_URL/pipelines/$PipelineId/jobs"
    $response = Invoke-RestMethod -Uri $url -Headers $HEADERS
    $jobId = $response | Where-Object { $_.stage -eq "build-image" -and $_.ref -eq $Branch } | ForEach-Object { $_.id }
    
    Write-Host "$Branch build-image job ID: $jobId"
    return $jobId
}

# Function: Get image SHA256 from job trace
function Get-ImageSha256 {
    param (
        [int]$JobId
    )
    
    $url = "$GITLAB_API_URL/jobs/$JobId/trace"
    $response = Invoke-RestMethod -Uri $url -Headers $HEADERS
    $sha256 = $response | Select-String -Pattern "writing image sha256:[a-z0-9]+" -AllMatches | 
              ForEach-Object { $_.Matches.Value -replace 'writing image sha256:([a-z0-9]{12}).*', '$1' }
    
    Write-Host "Extracted SHA256: $sha256"
    return $sha256
}

# Function: Deploy WAR file
function Deploy-War {
    param (
        [string]$Branch,
        [string]$Sha256
    )
    
    Write-Host "Command to execute: ./deploy_se_war.sh deploy $Sha256" -ForegroundColor Yellow
    # Only display the command, do not execute
    # ./deploy_se_war.sh deploy $Sha256
}

# Main logic
foreach ($branch in $BRANCHES) {
    Write-Host "`nProcessing branch $branch..."
    
    # Step 1: Get the latest pipeline ID
    $pipelineId = Get-LatestPipelineId -Branch $branch
    
    if ($pipelineId) {
        # Step 2: Get the job ID for the build-image stage
        $jobId = Get-BuildImageJobId -PipelineId $pipelineId -Branch $branch
        
        if ($jobId) {
            # Step 3: Get image SHA256
            $sha256 = Get-ImageSha256 -JobId $jobId
            
            if ($sha256) {
                # Step 4: Deploy WAR file
                Deploy-War -Branch $branch -Sha256 $sha256
            } else {
                Write-Host "Failed to get SHA256 for $branch, skipping deployment" -ForegroundColor Red
            }
        } else {
            Write-Host "Failed to get build-image job ID for $branch, skipping deployment" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to get latest pipeline ID for $branch, skipping deployment" -ForegroundColor Red
    }
}
