$ErrorActionPreference = "Stop"

# 1. Start fresh
if (Test-Path .git) {
    Remove-Item -Recurse -Force .git -ErrorAction Ignore
}

# Clear any previous dummy files
if (Test-Path dummy_commits.txt) {
    Remove-Item -Force dummy_commits.txt
}

git init
git branch -M main
git remote add origin https://github.com/aziz-rmili/co-voiturage.git

$currentDate = Get-Date

# 2. Make the initial commit with all project files (Day 19 ago)
$initialDate = $currentDate.AddDays(-19).ToString("yyyy-MM-ddTHH:mm:ss")
$env:GIT_COMMITTER_DATE = $initialDate
$env:GIT_AUTHOR_DATE = $initialDate

# Create the first line of the dummy file so we can add to it later
"Initial project setup" | Out-File -FilePath dummy_commits.txt

git add .
git commit -m "Initial commit - Project setup" --date=$initialDate

# 3. Create 19 subsequent dummy commits
for ($i = 18; $i -ge 0; $i--) {
    $dateToUse = $currentDate.AddDays(-$i)
    $dateStr = $dateToUse.ToString("yyyy-MM-ddTHH:mm:ss")
    
    # Modify a file
    $content = "Update dummy text for day $i"
    Out-File -FilePath dummy_commits.txt -InputObject $content -Append

    # Add and commit
    git add dummy_commits.txt
    
    $env:GIT_COMMITTER_DATE = $dateStr
    $env:GIT_AUTHOR_DATE = $dateStr
    git commit -m "Auto-generated commit for $($dateToUse.ToString('yyyy-MM-dd'))" --date=$dateStr
}

# 4. Push to remote
git push -u origin main -f
