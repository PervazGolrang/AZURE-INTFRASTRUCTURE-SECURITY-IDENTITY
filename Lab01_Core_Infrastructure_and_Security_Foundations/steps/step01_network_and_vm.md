# Step 1 - Network, Subnet, NSG, and VM Deployment

This step sets up the foundational infrastructure: virtual network, subnets, network security group, and the virtual machine. The VM will be deployed without a public IP and placed in a secured subnet. This lays the groundwork for later steps involving Bastion, logging, and identity.

## 1.1 - Create Resource Group

```bash
az group create --name rg-secure-vm-01 --location northeurope
```

Confirm it's created either via Azure Portal or CLI. In the portal, go to “Resource Groups” and verify `rg-secure-vm-01` exists in West Europe.

## 1.2 - Deploy VNet and Subnets

You need two subnets:

- `subnet-jumphost01`: for the VM
- `AzureBastionSubnet`: reserved name for Bastion

```bash
az network vnet create \
  --name vnet-core-neu01 \
  --resource-group rg-secure-vm-01 \
  --location northeurope \
  --address-prefix 10.100.0.0/16 \
  --subnet-name subnet-jumphost01 \
  --subnet-prefix 10.100.1.0/24
```

Then create the Bastion subnet:

```bash
az network vnet subnet create \
  --name AzureBastionSubnet \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-neu01 \
  --address-prefix 10.100.0.0/27
```

## 1.3 - Create Network Security Group

Deny-by-default (no inbound allowed initially):

```bash
az network nsg create \
  --resource-group rg-secure-vm-01 \
  --name nsg-jumphost01 \
  --location westeurope
```

Then associate it with the subnet:

```bash
az network vnet subnet update \
  --vnet-name vnet-core-neu01 \
  --name subnet-jumphos01 \
  --resource-group rg-secure-vm-01 \
  --network-security-group nsg-jumphos01
```

## 1.4 - Deploy the Virtual Machine

This machine will have no public IP and be placed behind the NSG.

```bash
az vm create \
  --resource-group rg-secure-vm-01 \
  --name vm-jhost-neu01 \                   ## Keep lower than 15-characters
  --image Win2022Datacenter \
  --admin-username labadmin \
  --admin-password <StrongPasswordHere> \
  --vnet-name vnet-core-neu01 \
  --subnet subnet-jumphost01 \
  --nsg "" \
  --public-ip-address "" \
  --assign-identity \
  --enable-agent true \
  --enable-auto-update true \
  --size Standard_B2s \
  --location northeurope
```

Replace `<StrongPasswordHere>` with a valid, complex password. After deployment, verify that the VM has no public IP and that the managed identity is enabled. I wrote `Strongpass123`.

## 1.5 - Validate in Azure Portal

In the portal, open the VM and check:

- No public IP address is assigned
- NIC is in subnet `subnet-jumphost-01` under `vnet-core-neu01`
- Managed identity is enabled

## Screenshots:

![01-vm-no-public-ip.png](images/01-vm-no-public-ip.png)
![02-vnet-subnet-nsg.png](images/02-vnet-subnet-nsg.png)
