# Run .\DeployUATCommand.ps1 -Branches "679-69422,631-69029,608-68854,550-68400" -Token "glpat-xXXXxx9x9XXxXx_XxXXx"
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
    $markdownFile = Join-Path -Path $PSScriptRoot -ChildPath "Deploy_UAT_$dateFormat.md"
    Write-Host "Generating Markdown file: $markdownFile"
    "# Deploy UAT - Deploy List - $(Get-Date -Format 'yyyy-MM-dd')" | Out-File -FilePath $markdownFile
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

    "`n## Sync Master" | Out-File -FilePath $markdownFile -Append
    foreach ($branch in $branchList) {
        "Sync branch : ${branch}" | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git checkout master" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git checkout $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git merge master" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '```bash' | Out-File -FilePath $markdownFile -Append
        "git push" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append

        '----------' | Out-File -FilePath $markdownFile -Append
    }

    "`n## Create a backup of the release branch" | Out-File -FilePath $markdownFile -Append
    "`nCheckout release branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nCreate a backup of the release branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b bk_release_$dateFormat release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the backup branch to remote" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin bk_release_$dateFormat" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Merge feature branches into release" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append
    '----------' | Out-File -FilePath $markdownFile -Append

    foreach ($branch in $branchList) {
        "`nMerge branch: ${branch}" | Out-File -FilePath $markdownFile -Append
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git merge $branch" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
        
        "`nCommit Message: ${branch}" | Out-File -FilePath $markdownFile -Append
        '```bash' | Out-File -FilePath $markdownFile -Append
        "git commit -m 'Merge branch $branch into release'" | Out-File -FilePath $markdownFile -Append
        '```' | Out-File -FilePath $markdownFile -Append
        '----------' | Out-File -FilePath $markdownFile -Append
    }

    "`nPush the updated release branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Create the deployUAT branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing deployUAT branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/deployUAT`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new deployUAT branch from release" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b deployUAT release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the deployUAT branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin deployUAT" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Create the uatACA branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing uatACA branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/uatACA`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nCreate a new uatACA branch from release" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b uatACA release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the uatACA branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin uatACA" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Create the uatAIL branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing uatAIL branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/uatAIL`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new uatAIL branch from release" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b uatAIL release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the uatAIL branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin uatAIL" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Create the uatAPIN branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing uatAPIN branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/uatAPIN`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new uatAPIN branch from release" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b uatAPIN release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the uatAPIN branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin uatAPIN" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`n## Create the uatCN branch" | Out-File -FilePath $markdownFile -Append
    "`nDelete the existing uatCN branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/uatCN`"" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

     "`nCreate a new uatCN branch from release" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git checkout -b uatCN release" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    "`nPush the uatCN branch" | Out-File -FilePath $markdownFile -Append
    '```bash' | Out-File -FilePath $markdownFile -Append
    "git push -u origin uatCN" | Out-File -FilePath $markdownFile -Append
    '```' | Out-File -FilePath $markdownFile -Append

    Write-Host "Generated Files: $markdownFile" -ForegroundColor Green
    Start-Process "code" -ArgumentList $markdownFile
} catch {
    Write-Host "An error occurred: $_"
    Write-Error $_.Exception.StackTrace
}