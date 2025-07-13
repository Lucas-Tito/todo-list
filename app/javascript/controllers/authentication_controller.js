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
      const result = await this.auth.signInWithPopup(provider);
      const idToken = await result.user.getIdToken();
      const csrfToken = document.querySelector("meta[name='csrf-token']").content;

      const response = await fetch('/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ id_token: idToken })
      });

      if (response.ok) {
        window.location.href = '/app';
      } else {
        console.error('Login failed');
      }
    } catch (error) {
      console.error(error);
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