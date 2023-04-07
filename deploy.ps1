
New-AzResourceGroupDeployment -Name WortellReadySentinel -ResourceGroupName rg-wortellready-weu `
  -TemplateFile law.bicep `
  -TemplateParameterFile law.parameters.json
