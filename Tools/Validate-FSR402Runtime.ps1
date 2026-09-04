param([Parameter(Mandatory=$true)][string]$Dll)
$ErrorActionPreference='Stop'
if(!(Test-Path -LiteralPath $Dll)){throw 'File not found.'}
if($Dll -match '(?i)4\.0\.2c|402c'){throw 'FSR 4.0.2c is blocked by Lifeline policy.'}
$i=Get-Item -LiteralPath $Dll
$sig=Get-AuthenticodeSignature -LiteralPath $Dll
$hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $Dll).Hash
[pscustomobject]@{Name=$i.Name;FileVersion=$i.VersionInfo.FileVersion;ProductVersion=$i.VersionInfo.ProductVersion;Signature=$sig.Status;Signer=$(if($sig.SignerCertificate){$sig.SignerCertificate.Subject}else{''});SHA256=$hash}|Format-List
