# ADB APT Repository

A Debian package repository hosted on GitHub Pages using reprepro.

## Overview

This repository serves as an APT repository that can host `.deb` packages and is automatically deployed to GitHub Pages. Other repositories can upload their packages to this repository through GitHub Actions workflows.

## Quick Start

### Step 1: Push Repository to GitHub
```bash
git add .
git commit -m "Initial APT repository setup"
git push
```

### Step 2: Generate GPG Key Locally
```bash
# Generate GPG key
gpg --full-generate-key
# Choose: RSA, 4096 bits, name: "ADB APT Repository"

# Export public key for repository
gpg --armor --export "ADB APT Repository" > pubkey.gpg

# Get private key for GitHub secrets
gpg --armor --export-secret-keys "ADB APT Repository"
# Copy this output for GitHub secrets
```

### Step 3: Configure GitHub Repository
1. **Settings → Pages → Source**: "GitHub Actions"
2. **Settings → Actions → General**: "Read and write permissions"  
3. **Settings → Secrets and variables → Actions**: Add secrets (see below)

### Step 4: Add Required Secrets
| Secret Name | Value |
|-------------|--------|
| `GPG_PRIVATE_KEY` | Output from `gpg --armor --export-secret-keys` command |
| `GPG_PASSPHRASE` | Your GPG passphrase (if you set one) |

### Step 5: Commit Public Key and Test
```bash
git add pubkey.gpg
git commit -m "Add GPG public key"
git push
```

Your repository will be available at: `https://yourusername.github.io/adb-apt-repo`

## Quick Start

1. **For Repository Setup**: See [SETUP.md](SETUP.md) for detailed instructions
2. **For Package Uploads**: Use the provided scripts or GitHub Actions workflows
3. **For End Users**: Add the repository to your APT sources (see below)

## Repository Structure

```
├── conf/                 # reprepro configuration files
├── scripts/             # Helper scripts for package management
├── .github/workflows/   # GitHub Actions workflows
├── incoming/            # Temporary directory for incoming packages
├── examples/            # Example workflows for other repositories
├── dists/              # Generated repository metadata (auto-generated)
└── pool/               # Package storage (auto-generated)
```

## Required GitHub Secrets

Before the repository will work, you need to set up these GitHub secrets:

### 1. Generate a GPG Key

First, generate a GPG key for signing packages:

```bash
# Generate GPG key
gpg --full-generate-key
# Choose: RSA and RSA, 4096 bits, no expiration
# Use name: "ADB APT Repository"
# Use email: "apt-repo@yourdomain.com"

# Export the private key for GitHub secrets
gpg --armor --export-secret-keys "ADB APT Repository"
# Copy this output for GPG_PRIVATE_KEY secret

# Export the public key for the repository
gpg --armor --export "ADB APT Repository" > pubkey.gpg
```

### 2. Add GitHub Repository Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value | Required |
|-------------|-------|----------|
| `GPG_PRIVATE_KEY` | Output from `gpg --armor --export-secret-keys` | Yes |
| `GPG_PASSPHRASE` | GPG key passphrase (if you set one) | Only if you used a passphrase |

### 3. Configure Repository Settings

1. **Enable GitHub Pages**: Settings → Pages → Source: "GitHub Actions"
2. **Set Workflow Permissions**: Settings → Actions → General → "Read and write permissions"

## Adding Packages

### From External Repositories

To upload packages from your GitHub Actions workflows, use the provided upload script:

```yaml
- name: Upload to APT Repository
  env:
    GITHUB_TOKEN: ${{ secrets.APT_REPO_TOKEN }}  # Personal access token
  run: |
    curl -O https://raw.githubusercontent.com/AdamBirds/adb-apt-repo/main/scripts/upload-to-apt-repo.sh
    chmod +x upload-to-apt-repo.sh
    ./upload-to-apt-repo.sh your-package.deb stable main
```

**Note**: External repositories need a `APT_REPO_TOKEN` secret with a GitHub personal access token that has repository access.

### Manual Upload

1. Place your `.deb` file in the `incoming/` directory
2. The GitHub Actions workflow will automatically process it

## Using the Repository

Add this repository to your APT sources:

```bash
# Add the repository
echo "deb https://adambirds.github.io/adb-apt-repo stable main" | sudo tee /etc/apt/sources.list.d/adb-apt-repo.list

# Add the GPG key (replace with your actual key)
curl -fsSL https://adambirds.github.io/adb-apt-repo/pubkey.gpg | sudo apt-key add -

# Update package list
sudo apt update
```

## Configuration

The repository is configured to support:
- **Distributions**: stable, testing
- **Components**: main, contrib
- **Architectures**: amd64, arm64, armhf

## Security

- All packages are signed with a GPG key
- Only authorized repositories can upload packages via GitHub Actions
- Package validation is performed before inclusion

## Maintenance

The repository is automatically maintained through GitHub Actions:
- Package processing and inclusion
- Repository metadata generation
- Deployment to GitHub Pages
- Cleanup of old packages (optional)
