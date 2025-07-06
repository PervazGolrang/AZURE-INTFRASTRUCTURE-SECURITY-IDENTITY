# Step 2 - Azure Bastion and NSG Configuration

This step deploys Azure Bastion to enable secure browser-based access to the virtual machine. This will also configure the network security group (NSG) to allow only required traffic for both Bastion and the monitoring agents. The VM will remain **fully isolated** from public IP exposure.

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

After deployment, go to the `Azure Portal > Bastion Host > Overview` and verify it is running.

## 2.2 - Create and Update the NSG Rules

Open inbound access only to allow Bastion and agent services.

Allow these rules:

- `TCP 3389 (RDP)` from Azure Bastion service tag
- AzureMonitor Service Tag (for diagnostic agents)
- `TCP 22 (SSH)` from Azure Bastion

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
```

Adding rules for `AzureMonitor` for Bastion and logging.

```bash
# Rule 1: Allow RDP from Virtual Network used for Bastion
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

# Rule 2: Allow Azure Monitor used for logging
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

1. Access the VM through the Azure Portal
2. Click `Connect` > `Bastion`
3. Login using the credentials that were set during VM deployment

## 2.4 - Test and Validate

Confirm:
- RDP or SSH is working via Bastion
- NSG blocks all other inbound access
- VM still has no public IP
- NSG logging is optionally enabled for diagnostics

## Screenshots:

- [`03-bastion-session.png`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/03-bastion-session.png)
- [`04-nsg-ruleset.png`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/04-nsg-ruleset.png)