# Step 5 - Landing Zone Lite with Azure Firewall and Governance  - WIP

This step sets up a simplified "landing zone" with baseline governance controls and perimeter firewalling. It introduces policies, tagging, cost alerts, and a stateful Azure Firewall with UDR to enforce inspection.

## 5.1 - Create Azure Firewall and Subnet

```bash
az network vnet subnet create \
  --name AzureFirewallSubnet \
  --vnet-name vnet-core-weu01 \
  --resource-group rg-secure-vm-01 \
  --address-prefix 10.100.2.0/24

az network public-ip create \
  --resource-group rg-secure-vm-01 \
  --name pip-fw-core-weu01 \
  --sku Standard \
  --location westeurope

az network firewall create \
  --name fw-core-weu01 \
  --resource-group rg-secure-vm-01 \
  --location westeurope

az network firewall ip-config create \
  --firewall-name fw-core-weu01 \
  --name fw-config \
  --public-ip-address pip-fw-core-weu01 \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-weu01
```

Wait for deployment. Note the firewall private IP.

## 5.2 - Create UDR and Route Traffic via Firewall

```bash
az network route-table create \
  --name rt-secure \
  --resource-group rg-secure-vm-01 \
  --location westeurope

az network route-table route create \
  --resource-group rg-secure-vm-01 \
  --route-table-name rt-secure \
  --name fw-default-route \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address <FIREWALL_PRIVATE_IP>

az network vnet subnet update \
  --name subnet-jumphost-01 \
  --vnet-name vnet-core-weu01 \
  --resource-group rg-secure-vm-01 \
  --route-table rt-secure
```

Verify all outbound traffic is forced through the firewall.

## 5.3 - Add Firewall Rules (FQDN)

```bash
az network firewall application-rule create \
  --firewall-name fw-core-weu01 \
  --resource-group rg-secure-vm-01 \
  --collection-name app-allow \
  --rule-name allow-ms-update \
  --priority 100 \
  --action allow \
  --rule-type ApplicationRule \
  --target-fqdns "*.windowsupdate.com" \
  --source-addresses 10.100.1.0/24 \
  --protocols Http=80 Https=443
```

Test connectivity to `windowsupdate.com` or `microsoft.com` from inside the VM.

## 5.4 - Add Azure Policy for Tags

```bash
az policy definition create \
  --name enforce-tag-dept \
  --display-name "Enforce Dept Tag" \
  --description "Requires 'Dept' tag on resources" \
  --rules rules.json \
  --params params.json \
  --mode Indexed

az policy assignment create \
  --name assign-dept-tag \
  --policy enforce-tag-dept \
  --scope /subscriptions/<SUB_ID>/resourceGroups/rg-secure-vm-01
```

You can use built-in definitions as well via:
```bash
az policy definition list --query "[?contains(displayName, 'tag')]"
```

## 5.5 - Set Budget Alert

```bash
az consumption budget create \
  --amount 50 \
  --time-grain monthly \
  --budget-name budget-secure-rg \
  --resource-group rg-secure-vm-01 \
  --start-date 2025-01-01 \
  --end-date 2025-12-31 \
  --category cost \
  --notification-budget-exceeded \
    enabled=true \
    operator=GreaterThan \
    threshold=80 \
    contactEmails=user@example.com
```

Budget alert will trigger at 80% usage.

## Screenshots

Save:
- `11-firewall-deployment.png`
- `12-fw-logs.png`
- `13-budget-alert.png`
- `14-policy-eval.png`