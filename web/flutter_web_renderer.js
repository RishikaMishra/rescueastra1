// This script ensures Flutter uses the HTML renderer for web
// which is required for Google Maps to work properly

// Set the renderer to HTML mode
window.flutterWebRenderer = "html";

console.log("Flutter web renderer set to HTML mode for Google Maps compatibility");
