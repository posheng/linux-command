# Run .\DeployPRDCommand.ps1 -Branches "679-69422,631-69029,608-68854,550-68400" -Token "glpat-xXXXxx9x9XXxXx_XxXXx"
param (
    [string]$Token = $null,
    [string]$Branches = $null
)

Write-Host "Token: $Token"
Write-Host "Branches: $Branches"

# split branches by comma to list
$branchList = $Branches -split ','
foreach ($branch in $branchList) {
    Write-Host "Processing branch: $branch"
}

try {
    $dateFormat = Get-Date -Format "yyyyMMdd"
    $markdownFile = Join-Path -Path $PSScriptRoot -ChildPath "Deploy_PRD_$dateFormat.md"
    Write-Host "Generating Markdown file: $markdownFile"
    "# Deploy PRD - Deploy List - $(Get-Date -Format 'yyyy-MM-dd')" | Out-File -FilePath $markdownFile
     "`n## Branches" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branchList) {
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

    "`n## Create a backup of the master branch" | Out-File -FilePath $markdownFile -Append
    "`nCreate a backup of the master branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b bk_master_$dateFormat master" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the backup branch to remote" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin bk_master_$dateFormat" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Merge all branches from the deployment list into master" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branchList) {
        "`nMerge branch: ${branch}" | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git checkout $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git merge master" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git push" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git checkout master" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git merge $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git push" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
        "`nCheck the commit status in the [GitLab pipeline](https://it-gitlab.intra.acer.com/agbs-ejb/web/-/pipelines) after each push." | Out-File -FilePath $markdownFile -Append

        '----------' | Out-File -FilePath $markdownFile -Append
    }

    "`n## Deploy to Live (After merging all branches and model build) - Create each Live branch from master" | Out-File -FilePath $markdownFile -Append

    "`n### Create the prdAAP branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing prdAAP branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/prdAAP`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new prdAAP branch from master" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b prdAAP master" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the prdAAP branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin prdAAP" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n### Create the prdAIL branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing prdAIL branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/prdAIL`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new prdAIL branch from master" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b prdAIL master" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the prdAIL branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin prdAIL" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n### Create the prdAPIN branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing prdAPIN branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/prdAPIN`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new prdAPIN branch from master" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b prdAPIN master" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the prdAPIN branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin prdAPIN" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n### Delete branches that have already been merged" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branchList) {
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git branch -d $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git push origin --delete $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
    }

    Write-Host "Generated Files: $markdownFile" -ForegroundColor Green
    Start-Process "code" -ArgumentList $markdownFile
} catch {
    Write-Host "An error occurred: $_"
    Write-Error $_.Exception.StackTrace
}