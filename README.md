# WRSecureWithMI
Bicep repo for Wortell Ready - How to secure logic apps with managed identities

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheCloudScout%2FWRSecureWithMI%2Fmain%2Flaw.json)

## Files

| Filename | Description |
| --- | --- |
| AddEnterpriseApplicationApiPermissions.ps1 | PowerShell script to assign API permissions (i.e. Graph) to Enterprise Applications. Used for Managed Identities. |
| definition.json | Workflow definition of Logic App used for Bicep depeloyment. |
| deploy.ps1 | PowerShell script that kicks off Bicep deployment. |
| law.bicep | Bicep definition of Logic App, Log Analytics Workspace, Sentinel solution and more. |
| law.json | ARM template equivalent to Bicep definition. Used for "deploy to Azure" button above. |
| law.parameters.json | Parameters file for either Bicep or ARM deployment. |
| README.md | This readme file. |