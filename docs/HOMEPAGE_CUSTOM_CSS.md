/* AVRAI Homepage Custom CSS - Enhanced Modern Design */

/* Main content container */
article {
  max-width: 1200px !important;
  margin: 0 auto !important;
  padding: 4rem 2rem !important;
}

/* Smooth scrolling */
html {
  scroll-behavior: smooth !important;
}

/* Headings with modern typography */
h1 {
  font-size: 3rem !important;
  font-weight: 800 !important;
  line-height: 1.1 !important;
  margin-bottom: 2rem !important;
  margin-top: 4rem !important;
  color: #0a0a0a !important;
  letter-spacing: -0.02em !important;
  background: linear-gradient(135deg, #0a0a0a 0%, #333 100%) !important;
  -webkit-background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
  background-clip: text !important;
}

h2 {
  font-size: 2.5rem !important;
  font-weight: 700 !important;
  line-height: 1.2 !important;
  margin-bottom: 2rem !important;
  margin-top: 5rem !important;
  color: #1a1a1a !important;
  letter-spacing: -0.01em !important;
  position: relative !important;
  padding-bottom: 1rem !important;
}

h2::after {
  content: '' !important;
  position: absolute !important;
  bottom: 0 !important;
  left: 0 !important;
  width: 60px !important;
  height: 4px !important;
  background: linear-gradient(90deg, #0066cc, #00a8ff) !important;
  border-radius: 2px !important;
}

h3 {
  font-size: 1.75rem !important;
  font-weight: 600 !important;
  line-height: 1.3 !important;
  margin-bottom: 1.25rem !important;
  margin-top: 2.5rem !important;
  color: #1a1a1a !important;
}

/* Paragraphs with better readability */
p {
  font-size: 1.1875rem !important;
  line-height: 1.8 !important;
  margin-bottom: 1.75rem !important;
  color: #444 !important;
  font-weight: 400 !important;
}

/* Lists with modern styling */
ul, ol {
  margin-bottom: 2.5rem !important;
  padding-left: 2rem !important;
  line-height: 1.8 !important;
}

li {
  margin-bottom: 1rem !important;
  font-size: 1.125rem !important;
  line-height: 1.75 !important;
  color: #444 !important;
  position: relative !important;
}

ul li::marker {
  color: #0066cc !important;
}

/* Strong/bold text */
strong {
  font-weight: 700 !important;
  color: #1a1a1a !important;
}

/* Hero section - first H1 (larger and more prominent) */
article > div:first-child h1,
article > section:first-child h1 {
  margin-top: 0 !important;
  font-size: 4rem !important;
  font-weight: 900 !important;
  line-height: 1.05 !important;
  margin-bottom: 2rem !important;
}

/* Section separators with gradient */
hr {
  border: none !important;
  height: 1px !important;
  background: linear-gradient(90deg, transparent, #e0e0e0 20%, #e0e0e0 80%, transparent) !important;
  margin: 5rem 0 !important;
}

/* Better spacing between sections */
article > div,
article > section {
  margin-bottom: 3rem !important;
  transition: transform 0.2s ease !important;
}

/* Links with modern hover effects */
a {
  color: #0066cc !important;
  text-decoration: none !important;
  transition: all 0.3s ease !important;
  border-bottom: 2px solid transparent !important;
  padding-bottom: 2px !important;
  font-weight: 500 !important;
}

a:hover {
  color: #0052a3 !important;
  border-bottom-color: #0052a3 !important;
  transform: translateY(-1px) !important;
}

/* Warning/notice boxes with modern design */
p:has(strong:contains("WARNING")) {
  background: linear-gradient(135deg, #fff9e6 0%, #fff4d6 100%) !important;
  border-left: 5px solid #ff9500 !important;
  padding: 1.5rem 1.75rem !important;
  margin: 2rem 0 !important;
  border-radius: 8px !important;
  box-shadow: 0 2px 8px rgba(255, 149, 0, 0.1) !important;
  font-weight: 500 !important;
}

/* Buttons (if you add button styles) */
button,
.button,
a[href*="waitlist"] {
  display: inline-block !important;
  padding: 1rem 2.5rem !important;
  background: linear-gradient(135deg, #0066cc 0%, #0052a3 100%) !important;
  color: white !important;
  border: none !important;
  border-radius: 8px !important;
  font-weight: 600 !important;
  font-size: 1.125rem !important;
  text-decoration: none !important;
  transition: all 0.3s ease !important;
  box-shadow: 0 4px 12px rgba(0, 102, 204, 0.3) !important;
  cursor: pointer !important;
}

button:hover,
.button:hover,
a[href*="waitlist"]:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 6px 20px rgba(0, 102, 204, 0.4) !important;
  background: linear-gradient(135deg, #0052a3 0%, #004080 100%) !important;
}

/* Card/feature sections */
h3 + p,
h3 + ul {
  background: #f8f9fa !important;
  padding: 1.5rem !important;
  border-radius: 8px !important;
  border: 1px solid #e9ecef !important;
  margin-top: 1rem !important;
}

/* Better list styling for feature lists */
ul:has(+ p strong),
ul:has(li strong:first-child) {
  background: transparent !important;
  padding: 0 !important;
  border: none !important;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  article {
    padding: 2rem 1rem !important;
  }
  
  h1 {
    font-size: 2.25rem !important;
  }
  
  article > div:first-child h1,
  article > section:first-child h1 {
    font-size: 2.75rem !important;
  }
  
  h2 {
    font-size: 2rem !important;
  }
  
  h3 {
    font-size: 1.5rem !important;
  }
  
  p {
    font-size: 1.0625rem !important;
  }
}

/* Subtle fade-in animation for sections */
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

article > div,
article > section {
  animation: fadeInUp 0.6s ease-out !important;
}

/* Selection styling */
::selection {
  background: #0066cc !important;
  color: white !important;
}

::-moz-selection {
  background: #0066cc !important;
  color: white !important;
}
