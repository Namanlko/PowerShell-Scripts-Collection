# ⚡ PowerShell-Scripts-Collection

> **A practical and enterprise-focused collection of PowerShell automation scripts for System Administrators and DevOps Engineers**

This repository contains a structured set of **PowerShell scripts** created to automate, manage, and simplify day-to-day administrative tasks across **Active Directory**, **VMware vSphere**, and **Windows Server environments**.

The scripts are written with real-world production use cases in mind and are especially useful for **Windows / VMware administrators**, **Infrastructure engineers**, and **DevOps aspirants**.

## 📂 Repository Structure

```
/PowerShell-Scripts-Collection
├── Active-Directory/          # Active Directory Domain Services automation
├── VMware-PowerCLI/           # VMware vSphere automation using PowerCLI
├── Windows-Server-Native/     # Native Windows Server administration scripts
└── README.md                  # Project documentation
```

## 🏢 1️⃣ Active Directory

This folder contains **automation scripts related to Active Directory Domain Services (AD DS)**. These scripts help administrators reduce manual effort and minimize human errors while managing users and groups.

#### Example Use Cases

* ✅ Check **user account status** (enabled / disabled)
* ➕ Add users to **Active Directory**
* ➖ Remove users from AD
* 👥 Add or remove users from **security & distribution groups**
* 🔐 Reset user passwords
* ⏳ Bulk user operations using CSV files
* 📊 Fetch user and group-related reports

Ideal for **L1/L2 administrators** and anyone preparing for **Windows Server / AD interviews**.

## ☁️ 2️⃣ VMware PowerCLI

This folder contains **VMware PowerCLI-based automation scripts** for managing **vSphere environments** such as ESXi hosts, clusters, and virtual machines.

#### Example Use Cases

* 🔄 Fetch **virtual machines restarted by HA**
* 🛠️ Upgrade **VMware Tools** on VMs
* 📋 Get VM inventory and power status
* ⚙️ Perform bulk VM operations
* 🧾 Generate reports for VMs and hosts

These scripts help administrators automate repetitive VMware tasks and improve operational efficiency.

## 🖥️ 3️⃣ Windows Server Native

This section contains **native Windows Server PowerShell scripts** that are not dependent on AD or VMware modules.

#### Example Use Cases

* 📦 Install software packages silently
* 🔍 Check **service status**
* 🔁 Start, stop, or restart Windows services
* 📡 Check **ping / connectivity status** of servers
* 🧹 Perform basic system health checks
* 📄 Fetch system and OS-related information

Perfect for **Windows Server administration**, troubleshooting, and automation.


## 🛠️ Prerequisites

### ✅ PowerShell

* Windows PowerShell **5.1+**
* or **PowerShell 7+ (Core)**

### ✅ Required Modules

* **Active Directory scripts**:
  `ActiveDirectory` module (via RSAT)

* **VMware scripts**:
  `VMware.PowerCLI`

  ```powershell
  Install-Module VMware.PowerCLI -Scope CurrentUser
  ```

* **Windows Server Native scripts**:
  Built-in PowerShell modules (no extra installation required)


## 🚀 Getting Started

1. Clone the repository

   ```bash
   git clone https://github.com/Namanlko/PowerShell-Scripts-Collection.git
   ```

2. Navigate to the repository

   ```bash
   cd PowerShell-Scripts-Collection
   ```

3. Open the required folder and execute scripts as per your environment

> ⚠️ Always test scripts in a **non-production environment** before running them in production.

## 📄 License

**Unlicensed**

This repository is provided **as-is**, without any warranty or guarantee. You are free to use and modify the scripts for learning and professional purposes.

## ⭐ Support

If you find this repository helpful:

* ⭐ Star the repository
* 🍴 Fork it for your own use
* 🤝 Contribute improvements and new scripts

Happy scripting! 🚀
