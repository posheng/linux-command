# Run .\DeployQACommand.ps1 -Token "glpat-xXXXxx9x9XXxXx_XxXXx"
param (
    [string]$Token = $null
)

Write-Host "Token: $Token"

# Constant definitions
$PRIVATE_TOKEN = $Token
$BASE_URL = "https://it-gitlab.intra.acer.com/api/v4"
$PROJECT_ID = 54

# Retrieve issue list
function Get-IssueIids {
    # $issuesUrl = "$BASE_URL/projects/$PROJECT_ID/issues?labels%5B%5D=Ready%20for%20ITQA&state=opened&per_page=100"
    $issuesUrl = "$BASE_URL/projects/$PROJECT_ID/issues?labels%5B%5D=DG%20ready%20to%20QA&state=opened&per_page=100"
    $headers = @{
        "PRIVATE-TOKEN" = $PRIVATE_TOKEN
    }
    
    $response = Invoke-RestMethod -Uri $issuesUrl -Headers $headers -Method Get
    
    $issueIids = @()
    foreach ($issue in $response) {
        $issueIids += $issue.iid
    }
    
    return $issueIids
}

# Retrieve branch names from issue comments
function Get-BranchNamesFromIssueNotes {
    param (
        [int]$issueIid
    )
    
    $notesUrl = "$BASE_URL/projects/$PROJECT_ID/issues/$issueIid/notes?sort=asc&body=created%20branch"
    # Write-Host "Fetching notes for Issue IID: $issueIid from URL: $notesUrl"
    
    $headers = @{
        "PRIVATE-TOKEN" = $PRIVATE_TOKEN
    }
    
    $response = Invoke-RestMethod -Uri $notesUrl -Headers $headers -Method Get
    # Write-Host "Response count: $($response.Count)"
    # Write-Host "Response: $($response | ConvertTo-Json -Depth 10)"
    
    $branchNames = @()
    if ($response.Count -eq 0) {
        return $branchNames
    }
    
    # Check all comments
    foreach ($note in $response) {
        $noteBody = $note.body
        # Write-Host "Processing note: $noteBody"
        
        # Extract branch names using regular expressions
        $pattern = "created branch\s+([^\s]+)"
        $matches = [regex]::Matches($noteBody, $pattern)
        # Write-Host "Found $($matches.Count) matches in note: $noteBody"

        foreach ($match in $matches) {
            $branchName = $match.Groups[1].Value.Replace("[", "").Replace("]", "")
            $branchNames += $branchName
        }
    }
    # Write-Host "branchNames: $branchNames"
    # Write-Host "-------------------------------------"
    return $branchNames
}

# Main Program
try {
    # Retrieve Issue List
    $issueIids = Get-IssueIids
    # Write-Host "Ready for ITQA - Issues: $issueIids"
    # Write-Output "DG ready to QA - Issues: $issueIids"
    
    # etrieve branch names for each issue
    $branches = @()
    foreach ($issueIid in $issueIids) {
        $branchNames = Get-BranchNamesFromIssueNotes -issueIid $issueIid
        # $branch = $branchNames -match '\d+-\d+' | Out-Null
        if ($branchNames -match '(\d{3}-\d{5})') {
            $branch = $matches[1]
            # Write-Host "Branch found: $branch"
            $branches += $branch
        } else {
            Write-Host "No valid branch found in issue $issueIid"
        }
    }

    # Generate Markdown file, the file name is based on the current date
    $dateFormat = Get-Date -Format "yyyyMMdd"
    $markdownFile = Join-Path -Path $PSScriptRoot -ChildPath "Deploy_QA_$dateFormat.md"
    Write-Host "Generating Markdown file: $markdownFile"
    "# Deploy QA - DG Ready for QA - $(Get-Date -Format 'yyyy-MM-dd')" | Out-File -FilePath $markdownFile
    "`n## Branches" | Out-File -FilePath $markdownFile -Append
    "`nDG ready to QA - Issues: $($issueIids -join ', ')" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branches) {
        "- $branch" | Out-File -FilePath $markdownFile -Append
    }
    "`n## Work Area" | Out-File -FilePath $markdownFile -Append

    "`nGo to development directory" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "cd .\Developer\" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nDelete web folder" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "Remove-Item -Recurse -Force .\web\" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nClone the repository" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git clone https://it-gitlab.intra.acer.com/agbs-ejb/web.git" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append
    
    "`nGo to project directory" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "cd .\web\" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Checkout branches" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branches) {
        "Checkout branch : ${branch}" | Out-File -FilePath $markdownFile -Append
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git checkout $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
    }

     "`n## Check if branch is up to date with master" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branches) {
        "Check branch: ${branch}" | Out-File -FilePath $markdownFile -Append
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git merge-base --is-ancestor master $branch && echo 'Up to date' || echo 'Move to Un-Sync Master'" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
    }

    "`n## Backup and update develop branch" | Out-File -FilePath $markdownFile -Append
    "`nCheckout develop branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout develop" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nCreate a backup of the develop branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b bk_develop_$dateFormat develop" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the backup branch to remote" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin bk_develop_$dateFormat" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Merge feature branches into develop" | Out-File -FilePath $markdownFile -Append
    "`nMerge a branch synchronized with master" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branches) {
        "`nMerge branch: ${branch}" | Out-File -FilePath $markdownFile -Append
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git merge $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
        "`nCommit Message: ${branch}" | Out-File -FilePath $markdownFile -Append
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git commit -m 'Merge branch $branch into develop'" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
        '----------' | Out-File -FilePath $markdownFile -Append
    }

    "`nPush the updated develop branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Create the deployQA branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing deployQA branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $PRIVATE_TOKEN`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/deployQA`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new deployQA branch from develop" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b deployQA develop" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the deployQA branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin deployQA" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    Write-Host "Generated Files: $markdownFile" -ForegroundColor Green
    Start-Process "code" -ArgumentList $markdownFile

    # Write-Output "cd .\Developer\"
    # Write-Output "Remove-Item -Recurse -Force .\web\"
    # Write-Output "git clone https://it-gitlab.intra.acer.com/agbs-ejb/web.git"
    # Write-Output "cd .\web\"
    # foreach ($branch in $branches) {
    #     Write-Output "git checkout $branch"
    # }
    # # check if branch is up to date with master
    # foreach ($branch in $branches) {
    #     Write-Output "git merge-base --is-ancestor master $branch && echo 'Up to date' || echo 'Move to Un-Sync Master'"
    # }
    # $dateFormat = Get-Date -Format "yyyyMMdd"
    # Write-Output "git checkout develop"
    # Write-Output "git checkout -b bk_develop_$dateFormat develop"
    # Write-Output "git push -u origin bk_develop_$dateFormat"
    # # merge 分支
    # foreach ($branch in $branches) {
    #     Write-Output "git merge $branch"
    # }
    # Write-Output "git push"
    # Write-Output 'curl --request DELETE --header "PRIVATE-TOKEN: glpat-xXXXxx9x9XXxXx_XxXXx" "https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/deployQA"'
    # Write-Output "git checkout -b deployQA develop"
    # Write-Output "git push -u origin deployQA"
} catch {
    Write-Error "Error: $_"
    Write-Error $_.Exception.StackTrace
}
