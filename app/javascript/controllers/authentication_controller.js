import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loginButton", "logoutButton", "userEmail"]

  connect() {
    console.log("Authentication controller initializing...");
    this.initializeFirebase();
  }

  initializeFirebase() {
    if (typeof window.firebase !== 'undefined') {
      console.log("Authentication controller connected with Firebase");
      this.auth = window.firebase.auth();
      this.setupAuthStateListener();
      this.checkForRedirectResult();
    } else {
      console.error("Firebase not available, retrying in 1 second...");
      setTimeout(() => this.initializeFirebase(), 1000);
    }
  }

  setupAuthStateListener() {
    this.auth.onAuthStateChanged((user) => {
      console.log("Auth state changed:", user ? "user logged in" : "no user");
      if (user) {
        this.handleSuccessfulAuth(user);
      } else {
        this.handleAuthLogout();
      }
    });
  }

  async signInWithGoogle() {
    try {
      const provider = new window.firebase.auth.GoogleAuthProvider();
      provider.addScope('profile');
      provider.addScope('email');

      let result;
      
      // Use popup for development, redirect for production
      if (window.FIREBASE_DEV_MODE) {
        console.log("Starting Google sign-in popup (development mode)...");
        result = await this.auth.signInWithPopup(provider);
      } else {
        console.log("Starting Google sign-in redirect (production mode)...");
        await this.auth.signInWithRedirect(provider);
        return; // signInWithRedirect doesn't return a result immediately
      }

      console.log("Sign-in successful:", result.user.email);
      // User state change will be handled by the auth state listener
      
    } catch (error) {
      console.error("Sign-in error:", error);
      this.showError(`Erro no login: ${error.message}`);
    }
  }

  async checkForRedirectResult() {
    try {
      console.log("Checking for redirect result...");
      const result = await this.auth.getRedirectResult();
      console.log("Redirect result:", result);
      
      if (result.user) {
        console.log("User from redirect:", result.user.email);
        // User state change will be handled by the auth state listener
      } else {
        console.log("No redirect result found");
      }
    } catch (error) {
      console.error("Error getting redirect result:", error);
      this.showError(`Erro na autenticação: ${error.message}`);
    }
  }

  async handleSuccessfulAuth(user) {
    try {
      console.log("Processing authentication for user:", user.email);
      
      // Get the ID token
      const idToken = await user.getIdToken();
      console.log("Got ID token, sending to server...");

      // Send token to Rails backend
      const response = await fetch('/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ id_token: idToken })
      });

      const data = await response.json();
      console.log("Server response:", data);

      if (data.status === 'success') {
        console.log("Authentication successful, updating UI...");
        this.updateUI(data.user);
        this.showSuccess(`Bem-vindo, ${data.user.name || data.user.email}!`);
        
        // Redirect to boards page after successful login
        setTimeout(() => {
          window.location.href = '/boards';
        }, 1000);
      } else {
        console.error("Server authentication failed:", data.message);
        this.showError(`Erro na autenticação: ${data.message}`);
        await this.signOut();
      }
    } catch (error) {
      console.error("Error processing authentication:", error);
      this.showError(`Erro no processamento: ${error.message}`);
      await this.signOut();
    }
  }

  async signOut() {
    try {
      console.log("Signing out...");
      
      // Sign out from Firebase
      await this.auth.signOut();
      
      // Clear session on server
      const response = await fetch('/logout', {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      });

      const data = await response.json();
      console.log("Logout response:", data);
      
      this.showSuccess("Logout realizado com sucesso!");
      
      // Redirect to login page
      setTimeout(() => {
        window.location.href = '/';
      }, 1000);
      
    } catch (error) {
      console.error("Logout error:", error);
      this.showError(`Erro no logout: ${error.message}`);
    }
  }

  handleAuthLogout() {
    console.log("User logged out, updating UI...");
    this.updateUI(null);
  }

  updateUI(user) {
    if (user) {
      // User is logged in
      if (this.hasLoginButtonTarget) {
        this.loginButtonTarget.style.display = 'none';
      }
      if (this.hasLogoutButtonTarget) {
        this.logoutButtonTarget.style.display = 'block';
      }
      if (this.hasUserEmailTarget) {
        this.userEmailTarget.textContent = user.email;
        this.userEmailTarget.style.display = 'block';
      }
    } else {
      // User is logged out
      if (this.hasLoginButtonTarget) {
        this.loginButtonTarget.style.display = 'block';
      }
      if (this.hasLogoutButtonTarget) {
        this.logoutButtonTarget.style.display = 'none';
      }
      if (this.hasUserEmailTarget) {
        this.userEmailTarget.style.display = 'none';
      }
    }
  }

  showSuccess(message) {
    this.showFlashMessage(message, 'success');
  }

  showError(message) {
    this.showFlashMessage(message, 'error');
  }

  showFlashMessage(message, type) {
    const flashDiv = document.getElementById('flash');
    if (flashDiv) {
      const alertClass = type === 'success' ? 'bg-green-100 border-green-500 text-green-700' : 'bg-red-100 border-red-500 text-red-700';
      
      flashDiv.innerHTML = `
        <div class="${alertClass} border-l-4 p-4 mb-4" role="alert">
          <p>${message}</p>
        </div>
      `;
      
      // Auto-hide after 5 seconds
      setTimeout(() => {
        if (flashDiv) {
          flashDiv.innerHTML = '';
        }
      }, 5000);
    }
  }

  // Legacy methods for compatibility
  async login() {
    return this.signInWithGoogle();
  }

  async logout() {
    return this.signOut();
  }
}