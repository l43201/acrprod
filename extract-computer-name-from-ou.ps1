# 🔧 Set your target OU DN
$targetOU = "OU=Vaše OU

# Export computer names to CSV
Get-ADComputer -SearchBase $targetOU -Filter * -Properties Name |
    Select-Object Name |
    Export-Csv -Path "C:\Script\computers_from_ou.csv" -NoTypeInformation
