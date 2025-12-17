# CDN Assets Repository

A **public** GitHub repository for hosting static assets via [jsDelivr CDN](https://www.jsdelivr.com/).

> ⚠️ **Important**: This repository **must be public** for jsDelivr to work.  
> jsDelivr mirrors GitHub files through unauthenticated HTTP requests.  
> Private repositories require authentication, which jsDelivr cannot perform.

---

## 📁 Directory Structure

```text
cdn-assets/
├── assets/
│   ├── css/           # Stylesheets (CSS files)
│   ├── data/          # Data files (JSON, CSV, XML, etc.)
│   ├── files/         # Downloadable files (ZIP, PDF, executables, etc.)
│   ├── icons/         # Icon files (ICO, SVG, PNG icons)
│   ├── images/        # Images (PNG, JPG, SVG, WebP, GIF, etc.)
│   └── js/            # JavaScript files
├── publish-cdn.sh     # Automation script
├── release.sh         # Github release creation script
├── .gitignore
└── README.md
```

---

## 🚀 Quick Start

### 1. Create a Public GitHub Repository

```bash
# Create new public repo on GitHub named "cdn-assets"
# Clone it locally
git clone https://github.com/YOUR_USERNAME/cdn-assets.git
cd cdn-assets
```

### 2. Configure the Script

Edit `publish-cdn.sh` and set your configuration:

```bash
USER="your-github-username"
REPO="cdn-assets"
BRANCH="main"
```

### 3. Add Your Assets

Place your files in the `assets/` directory:

```text
assets/
├── css/style.css
├── js/app.js
└── images/logo.png
```

### 4. Publish

```bash
chmod +x publish-cdn.sh
./publish-cdn.sh
```

---

## 🛠️ Script Features

The `publish-cdn.sh` script includes powerful automation features:

| Feature | Description |
|---------|-------------|
| **Repository Visibility Check** | Automatically warns if repo is private (jsDelivr won't work) |
| **Version Tagging** | Create immutable versioned URLs with `-t v1.0.0` |
| **Cache Purging** | Purge jsDelivr cache after upload with `-p` flag |
| **Dry Run Mode** | Preview changes without committing with `-d` flag |
| **Environment Variables** | Secure config via env vars (no hardcoded tokens) |
| **Colored Output** | Clear visual feedback with status icons |
| **Multiple URL Formats** | Displays branch, version, and commit URLs |
| **File Statistics** | Shows file count and total size |

### Command Line Options

```text
Options:
  -t, --tag VERSION    Create a git tag for versioned CDN URLs (e.g., v1.0.0)
  -m, --message MSG    Custom commit message
  -p, --purge          Purge jsDelivr cache after upload
  -d, --dry-run        Show what would be done without making changes
  -h, --help           Show help message
```

### Environment Variables

Instead of editing the script, you can use environment variables:

```bash
export CDN_GITHUB_USER="your-username"
export CDN_GITHUB_REPO="cdn-assets"
export CDN_GITHUB_BRANCH="main"
export CDN_GITHUB_TOKEN="ghp_xxxx"  # Optional, for authenticated push
export CDN_ASSETS_DIR="./assets"
```

### Usage Examples

```bash
# Basic upload
./publish-cdn.sh

# Upload with version tag (creates immutable URLs)
./publish-cdn.sh -t v1.0.0

# Upload and purge CDN cache
./publish-cdn.sh -p

# Full release with custom message
./publish-cdn.sh -t v1.0.0 -p -m "Release 1.0.0"

# Preview without making changes (dry run)
./publish-cdn.sh -d

# Combine options
./publish-cdn.sh -t v2.0.0 -p -m "Major update with new assets"
```

---

## 🔗 jsDelivr URL Format

### Latest Version (from main branch)

```text
https://cdn.jsdelivr.net/gh/USER/REPO@BRANCH/assets/PATH
```

### Specific Commit (immutable, recommended for production)

```text
https://cdn.jsdelivr.net/gh/USER/REPO@COMMIT_SHA/assets/PATH
```

### With Version Tags

```text
https://cdn.jsdelivr.net/gh/USER/REPO@v1.0.0/assets/PATH
```

### Auto-Minification (JS/CSS only)

jsDelivr automatically minifies JavaScript and CSS files on-the-fly. Just add `.min` before the extension:

```text
# Original file
https://cdn.jsdelivr.net/gh/USER/REPO@main/assets/js/example.js

# Auto-minified version (no extra file needed!)
https://cdn.jsdelivr.net/gh/USER/REPO@main/assets/js/example.min.js
```

> 💡 **You don't need to create separate `.min.js` files** — jsDelivr generates them automatically!

### Examples

```html
<!-- CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/USER/cdn-assets@main/assets/css/style.css">

<!-- JavaScript -->
<script src="https://cdn.jsdelivr.net/gh/USER/cdn-assets@main/assets/js/app.min.js"></script>

<!-- Image -->
<img src="https://cdn.jsdelivr.net/gh/USER/cdn-assets@main/assets/images/logo.png">
```

---

## ⚡ jsDelivr Features

### Minification (automatic)

Append `.min` before the extension:

```text
/assets/js/app.js      → /assets/js/app.min.js
/assets/css/style.css  → /assets/css/style.min.css
```

### Combine Multiple Files

```text
https://cdn.jsdelivr.net/combine/gh/USER/REPO@main/assets/js/file1.js,gh/USER/REPO@main/assets/js/file2.js
```

---

## 🔄 Cache & Purging

- **Branch URLs** (`@main`): Cached for 24 hours
- **Commit URLs** (`@abc123`): Cached permanently (immutable)
- **Tag URLs** (`@v1.0.0`): Cached permanently (immutable)

### Purge Cache Manually

```text
https://purge.jsdelivr.net/gh/USER/REPO@BRANCH/assets/PATH
```

The `publish-cdn.sh` script automatically purges cache after upload.

---

## 📋 Best Practices

1. **Use version tags** for production to ensure immutable URLs
2. **Use commit SHAs** for critical assets that must never change
3. **Use branch references** only for development/testing
4. **Minify files** before uploading for smaller payloads
5. **Use descriptive filenames** with version numbers when needed
6. **Keep repository public** - jsDelivr cannot access private repos

---

## 🛡️ Security Notes

- Never store sensitive data (API keys, credentials, etc.)
- All files are publicly accessible via CDN
- Use SRI (Subresource Integrity) hashes in production:

```html
<script src="https://cdn.jsdelivr.net/gh/USER/REPO@COMMIT/assets/js/app.js"
        integrity="sha384-HASH"
        crossorigin="anonymous"></script>
```

---

## 📝 License

Assets in this repository are provided under [MIT License](LICENSE) unless otherwise specified.
