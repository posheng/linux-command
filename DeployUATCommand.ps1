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
    Write-Host "Generating Markdown file: $markdownFile" -ForegroundColor Cyan

    # Helper functions for markdown generation
    function Append-ToMarkdown {
        param([string]$text)
        $text | Out-File -FilePath $markdownFile -Append
    }

    function Add-BashCodeBlock {
        param([string[]]$codeLines)
        '```bash' | Out-File -FilePath $markdownFile -Append
        foreach ($line in $codeLines) {
            $line | Out-File -FilePath $markdownFile -Append
        }
        '```' | Out-File -FilePath $markdownFile -Append
    }

    function Add-Separator {
        '----------' | Out-File -FilePath $markdownFile -Append
    }

    # Initialize markdown file with header and branches
    "# Deploy UAT - Deploy List - $(Get-Date -Format 'yyyy-MM-dd')" | Out-File -FilePath $markdownFile
    
    Append-ToMarkdown "`n## Branches"
    foreach ($branch in $branchList) {
        Append-ToMarkdown "- $branch"
    }

    # Work Area section
    Append-ToMarkdown "`n## Work Area"
    Add-BashCodeBlock @("cd .\Developer\")
    Add-BashCodeBlock @("Remove-Item -Recurse -Force .\web\")
    Add-BashCodeBlock @("git clone https://it-gitlab.intra.acer.com/agbs-ejb/web.git")
    Add-BashCodeBlock @("cd .\web\")

    # Sync Master section
    Append-ToMarkdown "`n## Sync Master"
    foreach ($branch in $branchList) {
        Append-ToMarkdown "`n### branch: ${branch}"
        Add-BashCodeBlock @("git checkout master")
        Add-BashCodeBlock @("git checkout $branch")
        Add-BashCodeBlock @("git merge master")
        Add-BashCodeBlock @("git push")
        Add-Separator
    }

    # Create backup of release branch
    Append-ToMarkdown "`n## Create a backup of the release branch"
    Add-BashCodeBlock @("git checkout release")
    Add-BashCodeBlock @("git checkout -b bk_release_$dateFormat release")
    Add-BashCodeBlock @("git push -u origin bk_release_$dateFormat")

    # Merge feature branches into release
    Append-ToMarkdown "`n## Merge feature branches into release"
    Add-BashCodeBlock @("git checkout release")
    Add-Separator

    foreach ($branch in $branchList) {
        Append-ToMarkdown "`n### branch: ${branch}"
        Add-BashCodeBlock @("git merge $branch")
        Add-BashCodeBlock @("git commit -m 'Merge branch $branch into release'")
        Add-Separator
    }

    # Push the updated release branch
    Append-ToMarkdown "`n## Push the updated release branch"
    Add-BashCodeBlock @("git push")
    Append-ToMarkdown "`nCheck the status of the [GitLab pipeline](https://it-gitlab.intra.acer.com/agbs-ejb/web/-/pipelines)"

    # Deploy to UAT section - Create UAT branches
    Append-ToMarkdown "`n## Deploy to UAT (After merging all branches) - Create each UAT branch from release"

    # Function to add a UAT branch creation section
    function Add-UatBranchSection {
        param([string]$branchName)
        Append-ToMarkdown "`n### Create the $branchName branch"
        Add-BashCodeBlock @("curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/$branchName`"")
        Add-BashCodeBlock @("git checkout -b $branchName release")
        Add-BashCodeBlock @("git push -u origin $branchName")
        Append-ToMarkdown "`nCheck the status of the [GitLab pipeline](https://it-gitlab.intra.acer.com/agbs-ejb/web/-/pipelines)"
        Append-ToMarkdown ""
        Add-Separator
    }

    # Add sections for each UAT branch
    Add-UatBranchSection "deployUAT"
    Add-UatBranchSection "uatACA"
    Add-UatBranchSection "uatAIL"
    Add-UatBranchSection "uatAPIN"
    Add-UatBranchSection "uatCN"

    # Start Server section
    Append-ToMarkdown "`n## Start Server"

    # deployUAT (Dcoker) 
    Append-ToMarkdown "`n### deployUAT (Dcoker)"
    Add-BashCodeBlock @("sudo su - agbsaap")
    Add-BashCodeBlock @("cd /app/jbHome")
    Add-BashCodeBlock @("./agbsejb-web-uat.sh restart")
    Add-Separator

    # uatACA (Dcoker)
    Append-ToMarkdown "`n### uatACA (Dcoker)"
    Add-BashCodeBlock @("sudo su - agbsaap")
    Add-BashCodeBlock @("cd /app/jbHome")
    Add-BashCodeBlock @("./agbsejb-web-uataca.sh restart")
    Add-Separator

    # uatAIL (Copy from GitLab Pipeline - Build AIL Image) (Physical)
    Append-ToMarkdown "`n### uatAIL (Copy from GitLab Pipeline - Build AIL Image) (Physical)"
    Add-BashCodeBlock @("sudo su - agbsaap")
    Add-BashCodeBlock @("cd /home/agbsaap")
    Add-BashCodeBlock @("./deploy_se_war.sh deploy [dc6c681ab693]")
    Append-ToMarkdown "`nex. writing image sha256:dc6c681ab693f98c2037a337532f82aa147a4d62c3bfe7c7719ea8c8006d55cc done"

    # uatAPIN Auto start server
    Append-ToMarkdown "`n### uatAPIN (Auto start server)"
    
    # uatCN Auto start server
    Append-ToMarkdown "`n### uatCN (Auto start server)"

    # Open the markdown file in VS Code
    Write-Host "Generated Files: $markdownFile" -ForegroundColor Green
    Start-Process "code" -ArgumentList $markdownFile
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Error $_.Exception.StackTrace
}
