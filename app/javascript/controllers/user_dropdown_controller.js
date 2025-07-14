import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    // Close dropdown when clicking outside
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.menuTarget.classList.contains('hidden')) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden')
  }

  close() {
    this.menuTarget.classList.add('hidden')
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  async logout() {
    try {
      console.log("Initiating logout...")
      
      // Sign out from Firebase if available
      if (window.firebase && window.firebase.auth) {
        await window.firebase.auth().signOut()
      }
      
      // Clear session on server
      const response = await fetch('/logout', {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()
      console.log("Logout response:", data)
      
      if (data.status === 'success') {
        // Show success message
        this.showFlashMessage("Logout realizado com sucesso!", 'success')
        
        // Redirect to login page
        setTimeout(() => {
          window.location.href = '/'
        }, 1000)
      } else {
        throw new Error(data.message || 'Erro no logout')
      }
      
    } catch (error) {
      console.error("Logout error:", error)
      this.showFlashMessage(`Erro no logout: ${error.message}`, 'error')
    }
  }

  showFlashMessage(message, type) {
    const flashDiv = document.getElementById('flash')
    if (flashDiv) {
      const alertClass = type === 'success' ? 'bg-green-100 border-green-500 text-green-700' : 'bg-red-100 border-red-500 text-red-700'
      
      flashDiv.innerHTML = `
        <div class="${alertClass} border-l-4 p-4 mb-4" role="alert">
          <p>${message}</p>
        </div>
      `
      
      // Auto-hide after 5 seconds
      setTimeout(() => {
        if (flashDiv) {
          flashDiv.innerHTML = ''
        }
      }, 5000)
    }
  }
}
