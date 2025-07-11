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

    # Helper function to append content to the markdown file
    function Append-ToMarkdown {
        param (
            [Parameter(ValueFromPipeline = $true)]
            [string]$Content
        )
        $Content | Out-File -FilePath $markdownFile -Append
    }

    # Helper function to add bash code block
    function Add-BashCodeBlock {
        param (
            [Parameter(ValueFromPipeline = $true)]
            [string[]]$Commands
        )
        
        Append-ToMarkdown '```bash'
        foreach ($cmd in $Commands) {
            Append-ToMarkdown $cmd
        }
        Append-ToMarkdown '```'
    }

    # Helper function to add section separator
    function Add-Separator {
        Append-ToMarkdown ''
        Append-ToMarkdown '----------'
    }

    # Initialize the markdown file with header and branches
    "# Deploy PRD - Deploy List - $(Get-Date -Format 'yyyy-MM-dd')" | Out-File -FilePath $markdownFile
    
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

    # Create a backup of the master branch
    Append-ToMarkdown "`n## Create a backup of the master branch"
    Add-BashCodeBlock @("git checkout -b bk_master_$dateFormat master")
    Add-BashCodeBlock @("git push -u origin bk_master_$dateFormat")

    # Merge all branches from the deployment list into master
    Append-ToMarkdown "`n## Merge all branches from the deployment list into master"
    foreach ($branch in $branchList) {
        Append-ToMarkdown "`n### branch: ${branch}"
        Add-BashCodeBlock @("git checkout $branch")
        Add-BashCodeBlock @("git merge master")
        Add-BashCodeBlock @("git push")
        Add-BashCodeBlock @("git checkout master")
        Add-BashCodeBlock @("git merge $branch")
        Add-BashCodeBlock @("git push")
        
        Append-ToMarkdown "`nCheck the status of the [GitLab pipeline](https://it-gitlab.intra.acer.com/agbs-ejb/web/-/pipelines)"
        Add-Separator
    }

    # Deploy to Live section
    Append-ToMarkdown "`n## Deploy to Live (After merging all branches and model build) - Create each Live branch from master"
    
    # Create PRD branches
    $prdBranches = @("prdAAP", "prdACA", "prdAIL", "prdAPIN")
    foreach ($branch in $prdBranches) {
        Append-ToMarkdown "`n### Create the $branch branch"
        Add-BashCodeBlock @("curl --request DELETE --header `"PRIVATE-TOKEN: $Token`" `"https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/$branch`"")
        Add-BashCodeBlock @("git checkout -b $branch master")
        Add-BashCodeBlock @("git push -u origin $branch")
        
        Append-ToMarkdown "`nCheck the status of the [GitLab pipeline](https://it-gitlab.intra.acer.com/agbs-ejb/web/-/pipelines)"
        Add-Separator
    }

    # Start Server section
    Append-ToMarkdown "`n## Start Server"
    
    # prdAAP
    Append-ToMarkdown "`n### prdAAP (Copy from GitLab Pipeline - Build prdAAP Image) (Physical) (Every Mon and Thu)"
    Add-BashCodeBlock @("sudo su - agbsaap")
    Add-BashCodeBlock @("cd /home/agbsaap")
    Add-BashCodeBlock @("./deploy_se_war.sh deploy [dc6c681ab693]")
    Append-ToMarkdown "`nex. writing image sha256:dc6c681ab693f98c2037a337532f82aa147a4d62c3bfe7c7719ea8c8006d55cc done"
    Add-Separator
    
    # prdACA
    Append-ToMarkdown "`n### prdACA (Docker) (Every Mon and Thur)"
    Add-BashCodeBlock @("sudo su - agbsaap")
    Add-BashCodeBlock @("cd /app/jbHome")
    Add-BashCodeBlock @("./agbsejb-web-prdaca.sh restart")
    Add-Separator
    
    # prdAIL
    Append-ToMarkdown "`n### prdAIL (Copy from GitLab Pipeline - Build prdAIL Image) (Physical) (Every Tue and Fri - AM 8:10)"
    Add-BashCodeBlock @("sudo su - agbsaap")
    Add-BashCodeBlock @("cd /home/agbsaap")
    Add-BashCodeBlock @("./deploy_se_war.sh deploy [dc6c681ab693]")
    Append-ToMarkdown "`nex. writing image sha256:dc6c681ab693f98c2037a337532f82aa147a4d62c3bfe7c7719ea8c8006d55cc done"
    Add-Separator

    # prdAPIN
    Append-ToMarkdown "`n### prdAPIN (Copy from GitLab Pipeline - Build prdAPIN Image) (Physical) (Every Tue and Fri)"
    Add-BashCodeBlock @("sudo su - deploy")
    Add-BashCodeBlock @("cd /home/deploy/")
    Add-BashCodeBlock @("./deploy_se_war.sh deploy [dc6c681ab693]")
    Append-ToMarkdown "`nex. writing image sha256:dc6c681ab693f98c2037a337532f82aa147a4d62c3bfe7c7719ea8c8006d55cc done"
    Add-Separator
    
    # Delete branches section
    Append-ToMarkdown "`n## Delete branches that have already been merged"
    foreach ($branch in $branchList) {
        Append-ToMarkdown "`n### branch: ${branch}"
        Add-BashCodeBlock @("git branch -d $branch")
        Add-BashCodeBlock @("git push origin --delete $branch")
        Add-Separator
    }

    Write-Host "Generated Files: $markdownFile" -ForegroundColor Green
    Start-Process "code" -ArgumentList $markdownFile
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Error $_.Exception.StackTrace
}
