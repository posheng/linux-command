# 常量定義
$PRIVATE_TOKEN = "glpat-xxxxxxxx_xxxxxxxx"
$BASE_URL = "https://it-gitlab.intra.acer.com/api/v4"
$PROJECT_ID = 54

# 取得 Issue 清單
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

# 從 Issue 的註釋中取得分支名稱
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
    
    # 檢查所有註解
    foreach ($note in $response) {
        $noteBody = $note.body
        # Write-Host "Processing note: $noteBody"
        
        # 使用正則表達式提取分支名稱
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

# 主程序
try {
    # 取得 Issue 清單
    $issueIids = Get-IssueIids
    # Write-Host "Ready for ITQA - Issues: $issueIids"
    Write-Output "DG ready to QA - Issues: $issueIids"
    
    # 針對每個 Issue 取得所有分支名稱
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

    # 生成 Markdown 文件
    $dateFormat = Get-Date -Format "yyyyMMdd"
    $mdFile = Join-Path -Path $PSScriptRoot -ChildPath "GitFlow_Instructions_$dateFormat.md"
    
    # 寫入標題
    "# Git Flow 操作指南 - $(Get-Date -Format 'yyyy-MM-dd')" | Out-File -FilePath $mdFile
    "`n## 已識別的分支" | Out-File -FilePath $mdFile -Append
    "從以下議題找到的分支：$($issueIids -join ', ')" | Out-File -FilePath $mdFile -Append
    foreach ($branch in $branches) {
        "- $branch" | Out-File -FilePath $mdFile -Append
    }
    
    "`n## 準備工作區" | Out-File -FilePath $mdFile -Append
    
    # 每個指令使用單獨的代碼塊，避免使用 "$variable:" 這種格式
    "進入開發目錄" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "cd .\Developer\" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "刪除現有 web 目錄" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "Remove-Item -Recurse -Force .\web\" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "克隆代碼庫" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git clone https://it-gitlab.intra.acer.com/agbs-ejb/web.git" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "進入專案目錄" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "cd .\web\" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "`n## 檢出需要合併的分支" | Out-File -FilePath $mdFile -Append
    foreach ($branch in $branches) {
        "檢出分支 ${branch}" | Out-File -FilePath $mdFile -Append
        '```bash' | Out-File -FilePath $mdFile -Append
        "git checkout $branch" | Out-File -FilePath $mdFile -Append
        '```' | Out-File -FilePath $mdFile -Append
    }
    
    "`n## 檢查分支是否與 master 同步" | Out-File -FilePath $mdFile -Append
    foreach ($branch in $branches) {
        "檢查分支 ${branch}" | Out-File -FilePath $mdFile -Append
        '```bash' | Out-File -FilePath $mdFile -Append
        "git merge-base --is-ancestor master $branch && echo 'Up to date' || echo 'Move to Un-Sync Master'" | Out-File -FilePath $mdFile -Append
        '```' | Out-File -FilePath $mdFile -Append
    }
    
    "`n## 備份並更新 develop 分支" | Out-File -FilePath $mdFile -Append
    "檢出 develop 分支" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git checkout develop" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "創建 develop 分支備份" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git checkout -b bk_develop_$dateFormat develop" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "推送備份分支" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git push -u origin bk_develop_$dateFormat" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "`n## 合併功能分支" | Out-File -FilePath $mdFile -Append
    "合併與 master 同步的分支" | Out-File -FilePath $mdFile -Append
    foreach ($branch in $branches) {
        "合併分支 ${branch}" | Out-File -FilePath $mdFile -Append
        '```bash' | Out-File -FilePath $mdFile -Append
        "git merge $branch" | Out-File -FilePath $mdFile -Append
        '```' | Out-File -FilePath $mdFile -Append
    }
    
    "推送更新的 develop 分支" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git push" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "`n## 創建 deployQA 分支" | Out-File -FilePath $mdFile -Append
    "刪除現有的 deployQA 分支" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    'curl --request DELETE --header "PRIVATE-TOKEN: glpat-bFXHba9h9EHePe_HxVVh" "https://it-gitlab.intra.acer.com/api/v4/projects/54/repository/branches/deployQA"' | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "從 develop 創建新的 deployQA 分支" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git checkout -b deployQA develop" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append
    
    "推送 deployQA 分支" | Out-File -FilePath $mdFile -Append
    '```bash' | Out-File -FilePath $mdFile -Append
    "git push -u origin deployQA" | Out-File -FilePath $mdFile -Append
    '```' | Out-File -FilePath $mdFile -Append

    # 顯示生成成功信息
    Write-Host "已生成操作指南：$mdFile" -ForegroundColor Green
    
    # 打開生成的 Markdown 文件
    Start-Process $mdFile
} catch {
    Write-Error "Error: $_"
    Write-Error $_.Exception.StackTrace
}
