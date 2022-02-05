$ErrorActionPreference = 'SilentlyContinue'

$output = New-Object Collections.Generic.List[object]

$dlTemplateInstall = "https://kamori.goats.dev/Plugin/Download/{0}?isUpdate=False&isTesting={1}&branch=api5"
$dlTemplateUpdate = "https://raw.githubusercontent.com/goatcorp/DalamudPlugins/api5/{0}/{1}/latest.zip"

$apiLevel = 5

$thisPath = Get-Location

$table = ""

Get-ChildItem -Path plugins -File -Recurse -Include *.json |
Foreach-Object {
    $content = Get-Content $_.FullName | ConvertFrom-Json
   	$content | add-member -Force -Name "IsHide" -value "False" -MemberType NoteProperty
        
    $newDesc = $content.Description -replace "\n", "<br>"
    $newDesc = $newDesc -replace "\|", "I"
        
    if ($content.DalamudApiLevel -eq $apiLevel) {
        if ($content.RepoUrl) {
            $table = $table + "| " + $content.Author + " | [" + $content.Name + "](" + $content.RepoUrl + ") | " + $newDesc + " |`n"
        }
        else {
            $table = $table + "| " + $content.Author + " | " + $content.Name + " | " + $newDesc + " |`n"
        }
    }

    $testingPath = Join-Path $thisPath -ChildPath "testing" | Join-Path -ChildPath $content.InternalName | Join-Path -ChildPath $_.Name
    if ($testingPath | Test-Path)
    {
        $testingContent = Get-Content $testingPath | ConvertFrom-Json
        $content | add-member -Force -Name "TestingAssemblyVersion" -value $testingContent.AssemblyVersion -MemberType NoteProperty
    }
    $content | add-member -Force -Name "IsTestingExclusive" -value "False" -MemberType NoteProperty

    $internalName = $content.InternalName
    
    $updateDate = git log -1 --pretty="format:%ct" plugins/$internalName/latest.zip
    if ($updateDate -eq $null){
        $updateDate = 0;
    }
    $content | add-member -Force -Name "LastUpdate" $updateDate -MemberType NoteProperty

    $installLink = $dlTemplateInstall -f $internalName, "False"
    $content | add-member -Force -Name "DownloadLinkInstall" $installLink -MemberType NoteProperty
    
    $installLink = $dlTemplateInstall -f $internalName, "True"
    $content | add-member -Force -Name "DownloadLinkTesting" $installLink -MemberType NoteProperty
    
    $updateLink = $dlTemplateUpdate -f "plugins", $internalName
    $content | add-member -Force -Name "DownloadLinkUpdate" $updateLink -MemberType NoteProperty

    $output.Add($content)
}

$outputStr = $output | ConvertTo-Json

Out-File -FilePath .\pluginmaster.json -InputObject $outputStr

$template = Get-Content -Path mdtemplate.txt
$template = $template + $table
Out-File -FilePath .\plugins.md -InputObject $template
