# Forked and greatly simplified from https://github.com/goatcorp/DalamudPlugins/blob/api5/Make-PluginMaster.ps1

$ErrorActionPreference = 'SilentlyContinue'

$output = New-Object Collections.Generic.List[object]

$dlTemplate = "https://github.com/awgil/ffxiv_plugin_distribution/raw/master/plugins/{0}/latest.zip"

$apiLevel = 5

$thisPath = Get-Location

Get-ChildItem -Path plugins -File -Recurse -Include *.json |
Foreach-Object {
    $content = Get-Content $_.FullName | ConvertFrom-Json
   	$content | add-member -Force -Name "IsHide" -value "False" -MemberType NoteProperty
        
    $newDesc = $content.Description -replace "\n", "<br>"
    $newDesc = $newDesc -replace "\|", "I"
        
    $content | add-member -Force -Name "IsTestingExclusive" -value "False" -MemberType NoteProperty

    $internalName = $content.InternalName
    
    $updateDate = git log -1 --pretty="format:%ct" plugins/$internalName/latest.zip
    if ($updateDate -eq $null){
        $updateDate = 0;
    }
    $content | add-member -Force -Name "LastUpdate" $updateDate -MemberType NoteProperty

    $link = $dlTemplate -f $internalName
    $content | add-member -Force -Name "DownloadLinkInstall" $link -MemberType NoteProperty
    $content | add-member -Force -Name "DownloadLinkTesting" $link -MemberType NoteProperty
    $content | add-member -Force -Name "DownloadLinkUpdate" $link -MemberType NoteProperty

    $output.Add($content)
}

$outputStr = ConvertTo-Json -InputObject $output

Out-File -Encoding ASCII -FilePath .\pluginmaster.json -InputObject $outputStr
