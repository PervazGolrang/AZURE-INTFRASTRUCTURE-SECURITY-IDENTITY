# Step 2 - Azure Bastion and NSG Configuration

This step deploys Azure Bastion to enable secure browser-based access to the virtual machine. You will also configure the network security group (NSG) to allow only required traffic for Bastion and monitoring agents. The VM will remain fully isolated from public IP exposure.

## 2.1 - Deploy Azure Bastion Host

Create a public IP for the Bastion host:

```bash
az network public-ip create \
  --resource-group rg-secure-vm-01 \
  --name bastion-pip \
  --sku Standard \
  --location northeurope
```

Then deploy Azure Bastion:

```bash
az network bastion create \
  --name bastion-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-neu01 \
  --location northeurope \
  --public-ip-address bastion-pip \
```

After deployment, go to the portal > Bastion Host > Overview and verify it is running.

## 2.2 - Create and Update NSG Rules

Open inbound access only to allow Bastion and agent services.

You can allow these:

- Allow TCP 3389 (RDP) from Azure Bastion service tag
- Allow TCP 22 (SSH) from Azure Bastion (if using Linux)
- Allow AzureMonitor Service Tag (for diagnostic agents)

```bash
az network nsg create \
  --name nsg-jumphost-01 \
  --resource-group rg-secure-vm-01 \
  --location northeurope

az network vnet subnet update \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-neu01 \
  --name subnet-jumphost01 \
  --network-security-group nsg-jumphost-01

# Rule 1: Allow RDP from Virtual Network (for Bastion)
az network nsg rule create \
  --resource-group rg-secure-vm-01 \
  --nsg-name nsg-jumphost-01 \
  --name Allow-RDP-from-Bastion \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --destination-port-ranges 3389
```

Add additional rules for `AzureMonitor` and port 22 (SSH) if needed.

```bash
# Rule 2: Allow Azure Monitor (for insights/logging)
az network nsg rule create \
  --resource-group rg-secure-vm-01 \
  --nsg-name nsg-jumphost-01 \
  --name Allow-AzureMonitor \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefixes AzureMonitor \
  --destination-port-ranges '*'
```

## 2.3 - Connect via Bastion

1. Go to the VM in the portal
2. Click `Connect` > `Bastion`
3. Log in using the credentials you set during VM deployment

Capture screenshots:
- Bastion connection screen
- VM desktop (if GUI is enabled)
- NSG rule list

Save as:
- `03-bastion-session.png`
- `04-nsg-ruleset.png`

## 2.4 - Test and Validate

Confirm:
- RDP or SSH is working via Bastion
- NSG blocks all other inbound access
- VM still has no public IP
- NSG logging is optionally enabled for diagnostics

You can test that SSH or RDP from your local machine is blocked (should timeout or be denied).
