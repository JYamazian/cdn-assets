# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 

### Changed
- 

### Fixed
- 

---

## [1.0.0] - 2024-12-08

### Added
- Initial CDN assets repository setup
- `publish-cdn.sh` automation script with:
  - Version tagging support (`-t v1.0.0`)
  - Cache purging (`-p`)
  - Dry run mode (`-d`)
  - Repository visibility checking
  - Environment variable configuration
- Example assets:
  - `assets/css/example.css` - Sample stylesheet
  - `assets/js/example.js` - CDNUtils library with auto-minification support
  - `assets/data/manifest.json` - Project manifest
- Directory structure for css, js, images, fonts, and data
- Comprehensive README with jsDelivr documentation
- MIT License

### CDN URLs (v1.0.0)
```
https://cdn.jsdelivr.net/gh/JYamazian/cdn-assets@v1.0.0/assets/js/example.js
https://cdn.jsdelivr.net/gh/JYamazian/cdn-assets@v1.0.0/assets/css/example.css
https://cdn.jsdelivr.net/gh/JYamazian/cdn-assets@v1.0.0/assets/data/manifest.json
```

---

[Unreleased]: https://github.com/JYamazian/cdn-assets/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/JYamazian/cdn-assets/releases/tag/v1.0.0
