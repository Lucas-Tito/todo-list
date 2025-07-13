import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Wait for Firebase to be available
    this.waitForFirebase();
  }

  waitForFirebase() {
    if (typeof firebase !== 'undefined' && firebase.apps.length > 0) {
      this.auth = firebase.auth();
      console.log('Authentication controller connected with Firebase');
      
      // Check for redirect result when page loads
      this.handleRedirectResult();
      
      // Also listen for auth state changes (but avoid infinite loops)
      this.auth.onAuthStateChanged(async (user) => {
        console.log('Auth state changed:', user ? user.email : 'no user');
        
        // Only proceed if user is signed in AND we're on the login page
        if (user && window.location.pathname === '/') {
          // User is signed in and on login page, send token to server
          try {
            const idToken = await user.getIdToken();
            const csrfToken = document.querySelector("meta[name='csrf-token']").content;

            console.log('Sending token to server via auth state change...');
            const response = await fetch('/login', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': csrfToken
              },
              body: JSON.stringify({ id_token: idToken })
            });

            if (response.ok) {
              console.log('Login successful via auth state, redirecting to app...');
              window.location.href = '/app';
            } else {
              const errorData = await response.json();
              console.error('Login failed via auth state:', errorData);
            }
          } catch (error) {
            console.error('Error processing auth state change:', error);
          }
        }
      });
    } else {
      // Retry after a short delay
      setTimeout(() => this.waitForFirebase(), 100);
    }
  }

  async login() {
    if (!this.auth) {
      console.error('Firebase auth not initialized');
      return;
    }

    const provider = new firebase.auth.GoogleAuthProvider();
    try {
      // Use redirect instead of popup to avoid CORS issues
      await this.auth.signInWithRedirect(provider);
    } catch (error) {
      console.error('Login redirect failed:', error);
    }
  }

  // Handle redirect result when user returns from Google
  async handleRedirectResult() {
    if (!this.auth) {
      console.error('Firebase auth not initialized');
      return;
    }

    try {
      console.log('Checking for redirect result...');
      const result = await this.auth.getRedirectResult();
      
      console.log('Redirect result:', result);
      
      if (result && result.user) {
        console.log('User found in redirect result:', result.user.email);
        const idToken = await result.user.getIdToken();
        const csrfToken = document.querySelector("meta[name='csrf-token']").content;

        console.log('Sending token to server...');
        const response = await fetch('/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ id_token: idToken })
        });

        if (response.ok) {
          console.log('Login successful, redirecting to app...');
          window.location.href = '/app';
        } else {
          const errorData = await response.json();
          console.error('Login failed:', errorData);
        }
      } else {
        console.log('No redirect result found');
      }
    } catch (error) {
      console.error('Error handling redirect result:', error);
    }
  }

  async logout() {
    if (!this.auth) {
      console.error('Firebase auth not initialized');
      return;
    }

    try {
      await this.auth.signOut();
      const csrfToken = document.querySelector("meta[name='csrf-token']").content;

      const response = await fetch('/logout', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        }
      });

      if (response.ok) {
        window.location.href = '/';
      } else {
        console.error('Logout failed');
      }
    } catch (error) {
      console.error(error);
    }
  }
}