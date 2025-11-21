// Disable right-click context menu globally
document.addEventListener('contextmenu', function(e) {
  e.preventDefault();
  return false;
}, false);

console.log('✅ Browser context menu disabled');