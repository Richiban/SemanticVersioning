# param(
#     [string] $branchName, 
#     [string] $buildCounter,
#     $overwriteBuildNumber,
#     [ValidateSet('Breaking','NonBreaking','Invisible')] $changeType,
#     [string] $branchIsDefault)

$branchName = "heads/task/5445-AddFeature"
$buildCounter = "101"
$overwriteBuildNumber = $true
$changeType = "Invisible"
$branchIsDefault = $false
$gitPath = "git"

if(-not $branchName) { throw "branchName is empty" }
if(-not $buildCounter) { throw "buildCounter is empty" }

$branchIsDefault = ([System.Convert]::ToBoolean($branchIsDefault))

write-host "$(@{ branchIsDefault = $branchIsDefault; buildCounter = $buildCounter})"

function Truncate-String([String] $s, [Int] $length)
{
    $length = [System.Math]::Min($length, $s.Length)

    return $s.Substring(0, $length)
}

$lastTag = & $gitPath describe --tags --always --abbrev=0

if($lastTag -match "(\d+)\.(\d+)\.(\d+).*")
{
    write-host "Build tag found: $lastTag"

    $lastMajorVersion = [int]$matches[1]
    $lastMinorVersion = [int]$matches[2]
    $lastPatchVersion = [int]$matches[3]

    Write-Host "Build tag parsed as: $lastMajorVersion, $lastMinorVersion, $lastPatchVersion"

    switch($changeType)
    {
        "Breaking" {
            Write-Host "Breaking changes selected. Incrementing major version number."

            $newMajorVersion = $lastMajorVersion + 1
            $newMinorVersion = 0
            $newPatchVersion = 0
        }
        "NonBreaking" {
            Write-Host "Backwards-compatible changes selected. Incrementing minor version number."

            $newMajorVersion = $lastMajorVersion
            $newMinorVersion = $lastMinorVersion + 1
            $newPatchVersion = 0
        }
        "Invisible" {
            Write-Host "Invisible changes selected. Incrementing patch number."

            $newMajorVersion = $lastMajorVersion
            $newMinorVersion = $lastMinorVersion
            $newPatchVersion = $lastPatchVersion + 1
        }
    }
}
else
{
    write-host "Build tag not found"

    $newMajorVersion = 0
    $newMinorVersion = 0
    $newPatchVersion = 1
}


if($branchIsDefault -eq $true)
{
    $prereleaseTag = ""

    $assemblyVersionNumber = "$newMajorVersion.$newMinorVersion.$newPatchVersion"
}
else
{
    $prereleaseTag = ("-rc-$buildCounter+" + ($branchName -split "/" | select -last 1))
    #$prereleaseTag = Truncate-string $prereleaseTag 20

    write-host "Branch is not default, prelease tag set to $prereleaseTag"

    $assemblyVersionNumber = "$newMajorVersion.$newMinorVersion.$newPatchVersion.$buildCounter"
}

$semanticVersionNumber = "$newMajorVersion.$newMinorVersion.$newPatchVersion$prereleaseTag"

write-host "assemblyVersionNumber: $assemblyVersionNumber"
write-host "semanticVersionNumber: $semanticVersionNumber"

if($overwriteBuildNumber)
{
	write-host "Overwriting build number"
	Write-Host "##teamcity[buildNumber '$semanticVersionNumber']"
}

Write-Host "##teamcity[setParameter name='VersionNumber.Assembly' value='$assemblyVersionNumber']"
Write-Host "##teamcity[setParameter name='VersionNumber.Semantic' value='$semanticVersionNumber']"