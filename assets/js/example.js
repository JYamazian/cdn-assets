/**
 * CDN Assets - Example JavaScript
 * This file demonstrates the CDN structure
 * 
 * 💡 TIP: jsDelivr auto-minifies JS/CSS files!
 *    Just add .min before the extension:
 *    - example.js     → example.min.js (auto-minified)
 *    - style.css      → style.min.css (auto-minified)
 */

(function(global) {
  'use strict';

  /**
   * CDN Utils - A simple utility library
   */
  const CDNUtils = {
    version: '1.0.0',

    /**
     * Log a message with timestamp
     * @param {string} message - The message to log
     */
    log: function(message) {
      const timestamp = new Date().toISOString();
      console.log(`[CDN ${timestamp}] ${message}`);
    },

    /**
     * Check if CDN asset loaded successfully
     * @returns {boolean}
     */
    isLoaded: function() {
      return true;
    },

    /**
     * Get the CDN base URL
     * @param {string} user - GitHub username
     * @param {string} repo - Repository name
     * @param {string} version - Version/branch/commit
     * @returns {string}
     */
    getBaseUrl: function(user, repo, version) {
      version = version || 'main';
      return `https://cdn.jsdelivr.net/gh/${user}/${repo}@${version}`;
    },

    /**
     * Generate asset URL
     * @param {string} user - GitHub username
     * @param {string} repo - Repository name
     * @param {string} path - Asset path
     * @param {string} version - Version/branch/commit
     * @param {boolean} minified - Use auto-minified version
     * @returns {string}
     */
    assetUrl: function(user, repo, path, version, minified) {
      const base = this.getBaseUrl(user, repo, version);
      
      // Add .min before extension for auto-minification
      if (minified && (path.endsWith('.js') || path.endsWith('.css'))) {
        path = path.replace(/\.(js|css)$/, '.min.$1');
      }
      
      return `${base}/assets/${path}`;
    }
  };

  // Export for different module systems
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = CDNUtils;
  } else if (typeof define === 'function' && define.amd) {
    define(function() { return CDNUtils; });
  } else {
    global.CDNUtils = CDNUtils;
  }

})(typeof window !== 'undefined' ? window : this);
