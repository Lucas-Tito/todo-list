import { Controller } from "@hotwired/stimulus"

// Manages dropdown visibility and closure.
export default class extends Controller {
  static targets = ["menu"]

  // Shows or hides menu.
  toggle(event) {
    // Prevents the button click close menu immediately
    event.stopPropagation()
    
    this.menuTarget.classList.toggle("hidden")
  }

  // Esconde o menu se o usuário clicar fora do seu foco.
  hide(event) {
    // Does nothing is menu already hidden.
    if (this.menuTarget.classList.contains("hidden")) {
      return
    }
    
    // Hids menu if the user clicks out of focus.
    if (!this.element.contains(event.target)) {
      this.hideMenu()
    }
  }

  hideMenu() {
    this.menuTarget.classList.add("hidden")
  }
}