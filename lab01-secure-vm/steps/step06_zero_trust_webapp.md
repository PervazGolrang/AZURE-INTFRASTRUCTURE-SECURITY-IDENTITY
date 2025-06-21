# Step 6 - Zero Trust Web App with WAF and Azure AD Authentication  - WIP

This step simulates a production-grade public web application that uses:
- Azure App Service for hosting
- Azure Front Door for global distribution and TLS termination
- Azure Web Application Firewall (WAF) for Layer 7 protection
- Azure AD login for authentication (OIDC)
- Private Endpoint to isolate backend
- Logging via Diagnostic Settings to Log Analytics

## 6.1 - Create App Service Plan and Web App

```bash
az appservice plan create \
  --name plan-core-weu01 \
  --resource-group rg-secure-vm-01 \
  --sku P1v2 \
  --is-linux

az webapp create \
  --resource-group rg-secure-vm-01 \
  --plan plan-core-weu01 \
  --name app-secure-weu01 \
  --runtime "DOTNETCORE|6.0" \
  --deployment-local-git
```

Push simple app content via Git or use deployment center to upload.

## 6.2 - Create Private Endpoint for Web App

```bash
az network private-endpoint create \
  --name pe-app-secure \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-weu01 \
  --subnet subnet-jumphost-01 \
  --private-connection-resource-id $(az webapp show -n app-secure-weu01 -g rg-secure-vm-01 --query id -o tsv) \
  --group-id sites
```

Confirm DNS resolution via `privatelink.azurewebsites.net`.

## 6.3 - Create Azure Front Door + WAF Policy

```bash
az network front-door create \
  --name afd-secure-core \
  --resource-group rg-secure-vm-01 \
  --backend-address app-secure-weu01.azurewebsites.net

az network front-door waf-policy create \
  --name waf-policy-secure \
  --resource-group rg-secure-vm-01 \
  --mode Prevention

az network front-door waf-policy rule create \
  --policy-name waf-policy-secure \
  --resource-group rg-secure-vm-01 \
  --name block-bots \
  --priority 100 \
  --rule-type MatchRule \
  --match-conditions remoteAddr="*bot*" \
  --action Block
```

Associate the WAF policy to the Front Door endpoint.

## 6.4 - Enable Azure AD Authentication for Web App

```bash
az ad app create \
  --display-name app-secure-weu01 \
  --identifier-uris https://app-secure-weu01.azurewebsites.net

az webapp auth update \
  --name app-secure-weu01 \
  --resource-group rg-secure-vm-01 \
  --enabled true \
  --action LoginWithAzureActiveDirectory
```

Test SSO login using a test user in AAD.

## 6.5 - Enable Diagnostic Logs to Log Analytics

```bash
az monitor diagnostic-settings create \
  --name diag-webapp \
  --resource /subscriptions/<SUB_ID>/resourceGroups/rg-secure-vm-01/providers/Microsoft.Web/sites/app-secure-weu01 \
  --workspace log-core-weu01 \
  --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}]'
```

## Screenshots

Save:
- `15-app-private-endpoint.png`
- `16-frontdoor-waf.png`
- `17-app-login-aad.png`
- `18-log-analytics-webapp.png`

## Validation

- App reachable via Front Door URL only
- App backend is private
- WAF blocks defined patterns
- Logs visible in Log Analytics
- Azure AD login works