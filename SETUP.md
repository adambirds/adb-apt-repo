# Setup Guide for ADB APT Repository

## Initial Setup

### 1. Generate GPG Key

**Option A: Use the provided script (if you have reprepro locally)**
```bash
./scripts/generate-gpg-key.sh
```

**Option B: Manual GPG key generation (recommended)**
```bash
# Generate a new GPG key
gpg --full-generate-key

# When prompted, choose:
# - Key type: (1) RSA and RSA (default)
# - Key size: 4096
# - Key validity: 0 (key does not expire) or 2y (2 years)
# - Real name: ADB APT Repository
# - Email: apt-repo@yourdomain.com (use your actual domain)
# - Comment: (leave blank or add description)
# - Passphrase: (optional but recommended)

# Export the public key for the repository
gpg --armor --export "ADB APT Repository" > pubkey.gpg

# Export the private key for GitHub secrets (copy this output)
gpg --armor --export-secret-keys "ADB APT Repository"
```

### 2. Configure GitHub Repository

1. **Enable GitHub Pages**:
   - Go to your repository settings
   - Navigate to "Pages" section
   - Set Source to "GitHub Actions"

2. **Add Repository Secrets**:
   Go to **Repository Settings → Secrets and variables → Actions** and create these secrets:
   
   **Required Secrets:**
   
   | Secret Name | How to Get the Value | Required |
   |-------------|---------------------|----------|
   | `GPG_PRIVATE_KEY` | Run: `gpg --armor --export-secret-keys "ADB APT Repository"` | Yes |
   | `GPG_PASSPHRASE` | The passphrase you set when creating the GPG key | Only if you used a passphrase |
   
   **Step-by-step for GPG_PRIVATE_KEY:**
   ```bash
   # Copy this entire output (including -----BEGIN and -----END lines)
   gpg --armor --export-secret-keys "ADB APT Repository"
   ```
   
   **Step-by-step for adding secrets:**
   1. Go to your repository on GitHub
   2. Click **Settings** tab
   3. Click **Secrets and variables** in the left sidebar
   4. Click **Actions**
   5. Click **New repository secret**
   6. Name: `GPG_PRIVATE_KEY`, Value: (paste the GPG private key)
   7. If you used a passphrase, repeat for `GPG_PASSPHRASE`

3. **Set Repository Permissions**:
   - Go to Settings → Actions → General
   - Set "Workflow permissions" to "Read and write permissions"

### 3. Test the Repository

After setup, test by adding a package:

```bash
# Place a .deb file in the incoming directory
cp /path/to/your/package.deb incoming/

# Commit and push to trigger the workflow
git add .
git commit -m "Add test package"
git push
```

## Using the Repository

### For End Users

Add the repository to your system:

```bash
# Add repository
echo "deb https://adambirds.github.io/adb-apt-repo stable main" | sudo tee /etc/apt/sources.list.d/adb-apt-repo.list

# Add GPG key
curl -fsSL https://adambirds.github.io/adb-apt-repo/pubkey.gpg | sudo apt-key add -

# Update package list
sudo apt update

# Install packages
sudo apt install your-package-name
```

### For Package Maintainers

#### Method 1: Using the Upload Script

Copy the upload script to your project and use it:

```bash
# Copy the script
curl -O https://raw.githubusercontent.com/AdamBirds/adb-apt-repo/main/scripts/upload-to-apt-repo.sh
chmod +x upload-to-apt-repo.sh

# Set your GitHub token
export GITHUB_TOKEN="your-personal-access-token"

# Upload a package
./upload-to-apt-repo.sh your-package.deb stable main
```

#### Method 2: Using GitHub Actions

Copy the example workflow from `examples/upload-workflow.yml` to your repository's `.github/workflows/` directory.

Add a secret called `APT_REPO_TOKEN` to your repository with a GitHub personal access token that has access to the apt repository.

The workflow will automatically upload .deb packages when you create a release.

#### Method 3: Manual GitHub Actions Trigger

You can also manually trigger uploads using repository dispatch:

```bash
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -H "Content-Type: application/json" \
     -d '{
       "event_type": "upload-package",
       "client_payload": {
         "package_url": "https://github.com/your-repo/releases/download/v1.0.0/package.deb",
         "package_name": "package.deb",
         "distribution": "stable",
         "component": "main",
         "sender": "your-username"
       }
     }' \
     "https://api.github.com/repos/AdamBirds/adb-apt-repo/dispatches"
```

## Repository Management

### Adding Packages Manually

```bash
# Using the add-package script
./scripts/add-package.sh package.deb stable main

# Using reprepro directly
reprepro includedeb stable package.deb
```

### Removing Packages

```bash
# Using the remove-package script
./scripts/remove-package.sh package-name stable

# Using reprepro directly
reprepro remove stable package-name
```

### Listing Packages

```bash
# List all packages
reprepro list stable
reprepro list testing

# List specific package
reprepro listfilter stable 'Package (== package-name)'
```

## Security Considerations

1. **GPG Key Management**:
   - Keep your private GPG key secure
   - Use GitHub secrets for automation
   - Consider key rotation policies

2. **Access Control**:
   - Only trusted repositories should have upload access
   - Use personal access tokens with minimal required permissions
   - Regularly audit who has access

3. **Package Validation**:
   - The workflows validate that uploaded files are valid .deb packages
   - Consider adding additional security scanning

## Troubleshooting

### Common Issues

1. **GPG Key Problems**:
   - Ensure the private key is properly imported in GitHub Actions
   - Check that the passphrase is correct
   - Verify the key hasn't expired

2. **Upload Failures**:
   - Check that the GitHub token has the correct permissions
   - Verify the package file is a valid .deb
   - Check the repository dispatch payload format

3. **Repository Not Updating**:
   - Check the GitHub Actions logs
   - Verify GitHub Pages is enabled and configured correctly
   - Ensure the workflow has write permissions

### Debug Commands

```bash
# Check reprepro status
reprepro check

# Verify repository structure
reprepro checkpool fast

# List repository contents
reprepro dumpreferences

# Check GPG key
gpg --list-keys "ADB APT Repository"
```

## Customization

### Adding New Distributions

Edit `conf/distributions` to add new codenames:

```
Origin: ADB APT Repository
Label: ADB APT Repository
Codename: experimental
Architectures: amd64 arm64 armhf
Components: main contrib
Description: ADB experimental packages
SignWith: default
```

### Changing Repository Metadata

Modify the following files:
- `conf/distributions` - Distribution definitions
- `conf/options` - reprepro options
- `.github/workflows/build-deploy.yml` - Build process

## Monitoring

The repository provides several ways to monitor activity:

1. **GitHub Actions Logs** - View build and upload activity
2. **Repository Info Page** - https://adambirds.github.io/adb-apt-repo
3. **Package Lists** - Browse available packages and versions

## Backup and Recovery

### Backing Up

Important files to backup:
- `conf/` directory - Repository configuration
- GPG private key
- `pool/` directory - Actual package files (if using local storage)

### Recovery

To restore the repository:
1. Restore configuration files
2. Import GPG private key
3. Re-run the build workflow to regenerate metadata

## Contributing

To contribute to the repository infrastructure:
1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

For package submissions, use the upload methods described above.
