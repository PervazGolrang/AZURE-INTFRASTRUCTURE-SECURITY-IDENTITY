# Step 6 - Zero Trust Web App with WAF and Microsoft Entra ID Authentication

This step sets up a secure public web application following Zero Trust principles. It uses Azure Front Door for global access and TLS termination, Azure WAF for Layer 7 protection, and Microsoft Entra ID (OIDC) for user authentication. The backend is isolated using a Private Endpoint, where all activity is logged via Diagnostic Settings to Log Analytics.

## 6.1 - Create an App Service Plan and Web App

```bash
az appservice plan create \
  --name plan-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --sku P1v2 \
  --is-linux

az webapp create \
  --resource-group rg-secure-vm-01 \
  --plan plan-core-neu01 \
  --name app-secure-neu01 \
  --runtime "DOTNET|8" \
  --deployment-local-git
```

Using .NET 8 due to LTS stability, avoid .NET 9 and preview .NET 10.

Push simple app content via Git or use deployment center to upload.

## 6.2 - Create a Private Endpoint for Web App

```bash
az network private-endpoint create \
  --name pe-app-secure \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-neu01 \
  --subnet subnet-jumphost01 \
  --private-connection-resource-id $(az webapp show -n app-secure-neu01 -g rg-secure-vm-01 --query id -o tsv) \
  --group-id sites
  --connection-name pe-link-app-secure
```

Confirm DNS resolution via `privatelink.azurewebsites.net`.

## 6.3 - Create a Azure Front Door + WAF Policy

This three-step-section creates an Azure Front Door profile, and attaching a WAF policy with a custom rule to block bots.

### Step 1 - Create the Front Door profile
- Name: `afd-secure-core`
- Resource Group: `rg-secure-vm-01`
- Backend address: `app-secure-neu01.azurewebsites.net`
- Purpose: Acts as a global entry point with CDN, HTTPS, and load balancing

### Step 2 - Create a WAF Policy
- Name: `wafpolicysecure01` (Must ONLY contain letters or numbers)
- Resource Group: `rg-secure-vm-01`
- Mode: `Prevention ` (actively blocks malicious requests)
- Purpose: Define rules to protect against OWASP attacks or custom filters

### Step 3 - Add a Custom WAF Rule
Located in the WAF `Policy > wafpolicysecure01 > Settings-Tab > Custom rules`

- Rule Name: `blockbots` (Must ONLY contain letters or numbers)
- Priority: `100` (lower number = higher priority)
- Match type: `String `
- Match variable: `RequestHeader`
- Header name: `User-Agent`
- Operation: `is`
- Operator: `contains`
- Transformation: `Lowercase`
- Match values: `bot` (matches suspicious bot-like IPs)
- Then: `Deny traffic` (any request matching this rule will be dropped)

## 6.4 - Enable Microsoft Entra ID Authentication for the Web App

```bash
az ad app create \
  --display-name app-secure-neu01 \

az webapp auth update \
  --name app-secure-neu01 \
  --resource-group rg-secure-vm-01 \
  --enabled true \
  --action LoginWithAzureActiveDirectory
```

### Note:
Azure Active Directory (AAD) has been renamed to Microsoft Entra ID, however, the CLI and API paramters still use the `AzureActiveDirectory` as the identifier. Rebranding to Entra ID took place in 2023, two years later in 2025, it has not been updated for backwards compatability.

## Screenshots

- [`14_custom_rule_waf`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/14_custom_rule_waf.png)
- [`15-app-private-endpoint`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/15-app-private-endpoint.png)
- [`16-frontdoor-waf`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/16-frontdoor-waf.png)