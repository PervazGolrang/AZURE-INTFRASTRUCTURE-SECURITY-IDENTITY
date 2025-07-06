# Step 5 - Landing Zone Lite with Azure Firewall and Governance

This step sets up a simplified "landing zone" with baseline governance controls and perimeter firewalling. It introduces policies, tagging, cost alerts, and a stateful Azure Firewall with UDR to enforce inspection.

## 5.1 - Create a Azure Firewall and Subnet

```bash
# Create the Azure Firewall subnet
az network vnet subnet create \
  --name AzureFirewallSubnet \
  --vnet-name vnet-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --address-prefix 10.100.2.0/24

# Create a zone-redundant Standard public IP
az network public-ip create \
  --resource-group rg-secure-vm-01 \
  --name pip-fw-core-neu01 \
  --sku Standard \
  --location northeurope

# Create the Azure Firewall instance
az network firewall create \
  --name fw-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --location northeurope

# Attach the public IP and subnet to the firewall
az network firewall ip-config create \
  --firewall-name fw-core-neu01 \
  --name fw-config \
  --public-ip-address pip-fw-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-neu01
```

Wait for deployment. Note the firewall private IP.

## 5.2 - Create a UDR and Route Traffic via Firewall

```bash
# Create a new route table to control outbound routing
az network route-table create \
  --name rt-secure \
  --resource-group rg-secure-vm-01 \
  --location northeurope

# Add a default route to the route table that forces all outbound traffic (0.0.0.0/0) to go through the Azure Firewall
az network route-table route create \
  --resource-group rg-secure-vm-01 \
  --route-table-name rt-secure \
  --name fw-default-route \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address 10.100.2.4

# Associate the route table with the target subnet
az network vnet subnet update \
  --name subnet-jumphost01 \
  --vnet-name vnet-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --route-table rt-secure
```

Verify all outbound traffic is forced through the firewall.

## 5.3 - Add Firewall Rules (FQDN)

```bash
# Creates an application rule on the firewall to allow outbound HTTP/HTTPS traffic to *.windowsupdate.com from the 10.100.1.0/24 subnet
az network firewall application-rule create \
  --firewall-name fw-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --collection-name app-allow \
  --name allow-ms-update \
  --priority 100 \
  --action allow \
  --target-fqdns "*.windowsupdate.com" \
  --source-addresses 10.100.1.0/24 \
  --protocols Http=80 Https=443
```

Test connectivity to `microsoft.com` from inside the VM.

## 5.4 - Set a Budget Alert

### Note:

The budget was created in the Azure Portal because the CLI JSON method failed. I named it budget-secure-rg, set it to reset monthly, with a limit of 10 USD. Alert triggers at 80 percent, sending an email to **my personal email**. This ensures I get notified if costs approach the limit.

## Screenshots

- [`10-firewall-deployment`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/10-firewall-deployment.png)
- [`11-budget-input.png`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/11-budget-input.png)
- [`12-budget-alert.png`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/12-budget-alert.png)
- [`13-policy-eval.png`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/13-policy-eval.png)