import { Controller } from "@hotwired/stimulus"

// Manages dropdown visibility and closure.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Prepares function to be used with 'addEventListener'
    this.boundHideOnEscape = this.hideOnEscape.bind(this)
  }

  // Shows or hides menu.
  toggle(event) {
    // Prevents the button click close menu immediately
    event.stopPropagation()
    
    this.menuTarget.classList.toggle("hidden")
  }

  // Hids menu if the user clicks out of focus.
  hide(event) {
    if (this.menuTarget.classList.contains("hidden")) {
      return
    }

    if (!this.element.contains(event.target)) {
      this.hideMenu()
    }
  }

  // Hides menu and remove it's listeners.
  hideMenu() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.boundHideOnEscape)
  }
}