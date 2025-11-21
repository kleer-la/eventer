// Add role badges to the current user display in ActiveAdmin header
document.addEventListener('DOMContentLoaded', function() {
  addRoleBadgesToUserMenu();
});

// Also handle Turbolinks if it's being used
document.addEventListener('turbolinks:load', function() {
  addRoleBadgesToUserMenu();
});

function addRoleBadgesToUserMenu() {
  // Find the current user menu item
  var userMenuItem = document.querySelector('#utility_nav #current_user a');

  if (!userMenuItem) {
    return;
  }

  // Check if badges are already added
  if (userMenuItem.querySelector('.role-badge')) {
    return;
  }

  // Fetch user roles via data attribute or AJAX
  // For now, we'll add a data attribute to the menu item
  var userEmail = userMenuItem.textContent.trim();

  // Fetch roles from a custom endpoint
  fetch('/admin/current_user_roles.json')
    .then(response => response.json())
    .then(data => {
      if (data.roles && data.roles.length > 0) {
        var badgesHTML = data.roles.map(function(role) {
          var roleSlug = role.toLowerCase().replace(/\s+/g, '-');
          return '<span class="role-badge role-badge-' + roleSlug + '">' + role + '</span>';
        }).join(' ');

        userMenuItem.innerHTML = data.email + ' ' + badgesHTML;
      }
    })
    .catch(error => {
      console.log('Could not load user roles:', error);
    });
}
