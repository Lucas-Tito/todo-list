import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="multi-select"
export default class extends Controller {
  static targets = ["button", "options", "selectedText", "checkbox", "arrow"]

  connect() {
    // Close dropdown when clicking outside
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener('click', this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnOutsideClick)
  }

  toggle() {
    this.optionsTarget.classList.toggle('hidden')
    this.arrowTarget.classList.toggle('rotate-180')
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  close() {
    this.optionsTarget.classList.add('hidden')
    this.arrowTarget.classList.remove('rotate-180')
  }

  updateSelected() {
    const selected = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.nextElementSibling.textContent.trim())
    
    if (selected.length === 0) {
      this.selectedTextTarget.textContent = 'Escolha os boards...'
    } else if (selected.length === 1) {
      this.selectedTextTarget.textContent = selected[0]
    } else {
      this.selectedTextTarget.textContent = `${selected.length} boards selecionados`
    }
  }
}
