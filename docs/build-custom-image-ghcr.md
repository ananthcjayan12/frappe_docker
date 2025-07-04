# Building and Pushing Custom Frappe Docker Images to GHCR

This guide explains how to build a custom Frappe Docker image with your apps and push it to GitHub Container Registry (GHCR).

## Prerequisites

1. Docker installed and running
2. GitHub account with GHCR access
3. GitHub Personal Access Token (PAT) with appropriate permissions
4. Your custom apps ready to be included

## Steps

### 1. Configure apps.json

Create or modify `apps.json` in your project root to include your custom apps. Example:

```json
[
  {
    "url": "https://github.com/yourusername/your-custom-app",
    "branch": "develop"
  },
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  }
]
```

### 2. Convert apps.json to Base64

```bash
export APPS_JSON_BASE64=$(openssl base64 -A < apps.json)
```

### 3. Set up GHCR credentials

```bash
# Set your GHCR username and Personal Access Token
export GHCR_USER="your-github-username"
export GHCR_PAT="your-github-pat"

# Login to GHCR
echo $GHCR_PAT | docker login ghcr.io --username $GHCR_USER --password-stdin
```

### 4. Build the Custom Image

```bash
docker build \
  --file images/layered/Containerfile \
  --build-arg FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg FRAPPE_BRANCH=version-15 \
  --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag ghcr.io/$GHCR_USER/frappe-custom:your-tag \
  .
```

### 5. Push the Image to GHCR

```bash
docker push ghcr.io/$GHCR_USER/frappe-custom:your-tag
```

## Using Build Cache (Optional)

To speed up subsequent builds, you can use the previously built image as a cache source:

1. Pull the existing image:
```bash
docker pull ghcr.io/$GHCR_USER/frappe-custom:your-tag
```

2. Build with cache:
```bash
docker build \
  --file images/layered/Containerfile \
  --cache-from ghcr.io/$GHCR_USER/frappe-custom:your-tag \
  --build-arg FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg FRAPPE_BRANCH=version-15 \
  --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag ghcr.io/$GHCR_USER/frappe-custom:new-tag \
  .
```

## Important Notes

1. Replace `your-github-username` with your actual GitHub username
2. Replace `your-github-pat` with your actual GitHub Personal Access Token
3. Choose appropriate tags for your images (e.g., v15-with-custom-apps)
4. Make sure your PAT has the necessary permissions for GHCR
5. Keep your PAT secure and never commit it to version control

## Troubleshooting

If you encounter authentication issues:
1. Verify your PAT has the correct permissions
2. Ensure you're logged in to GHCR
3. Check if your PAT hasn't expired

For build issues:
1. Verify your apps.json is correctly formatted
2. Ensure all repository URLs are accessible
3. Check if the specified branches exist 