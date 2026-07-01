# Generate a self-signed TLS certificate for accounts.localhost
# and create a Kubernetes TLS secret YAML

$dnsName = "accounts.localhost"
$pfxPath = "$env:TEMP\accounts-tls.pfx"
$certPath = "$env:TEMP\accounts-tls.crt"
$keyPath = "$env:TEMP\accounts-tls.key"
$password = "password"

# Generate self-signed certificate
Write-Host "Generating self-signed certificate for $dnsName ..."
$cert = New-SelfSignedCertificate -DnsName $dnsName -CertStoreLocation "Cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(1)

# Export certificate (DER format)
Export-Certificate -Cert $cert -FilePath $certPath -Type CERT | Out-Null

# Export PFX with private key
$securePwd = ConvertTo-SecureString -String $password -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePwd | Out-Null

# Read the PFX back with Exportable flag to extract private key
$certWithKey = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$certWithKey.Import($pfxPath, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Export private key as PEM (PKCS#8 format)
$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certWithKey)
$keyBytes = $rsa.Key.ExportPkcs8PrivateKey()
$keyB64 = [Convert]::ToBase64String($keyBytes)

# Read certificate and base64 encode
$certBytes = [System.IO.File]::ReadAllBytes($certPath)
$certB64 = [Convert]::ToBase64String($certBytes)

# Create TLS secret YAML
$yaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: accounts-tls
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: $certB64
  tls.key: $keyB64
"@

$yamlPath = Join-Path $PSScriptRoot "..\deploy\overlays\k3d\accounts-tls-secret.yaml"
$yaml | Out-File -FilePath $yamlPath -Encoding ascii
Write-Host "TLS secret YAML written to: $yamlPath"
Write-Host "Certificate thumbprint: $($cert.Thumbprint)"
Write-Host ""
Write-Host "To apply: kubectl apply -f $yamlPath"
Write-Host "To trust (run as Admin): Import-Certificate -FilePath $certPath -CertStoreLocation 'Cert:\LocalMachine\Root'"
