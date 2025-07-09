import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="multi-select"
export default class extends Controller {
  static targets = ["button", "options", "selectedText", "checkbox", "arrow"]
  static values = { defaultText: String }

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

  toggleCheckbox(event) {
    event.stopPropagation()
    const customCheckbox = event.target.closest('.dropwdown-checkbox')
    const hiddenCheckbox = customCheckbox.previousElementSibling
    
    hiddenCheckbox.checked = !hiddenCheckbox.checked
    hiddenCheckbox.dispatchEvent(new Event('change'))
  }

  updateSelected() {
    const selected = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => {
        // Find the span with the board name (it's the sibling of the div container)
        const container = checkbox.parentElement
        const label = container.parentElement
        const span = label.querySelector('span')
        return span.textContent.trim()
      })
    
    // Update visual state of custom checkboxes
    this.checkboxTargets.forEach(checkbox => {
      const customCheckbox = checkbox.nextElementSibling
      const checkIcon = customCheckbox.querySelector('svg')
      
      if (checkbox.checked) {
        customCheckbox.classList.add('checked')
        checkIcon.classList.remove('hidden')
      } else {
        customCheckbox.classList.remove('checked')
        checkIcon.classList.add('hidden')
      }
    })
    
    if (selected.length === 0) {
      this.selectedTextTarget.textContent = this.defaultTextValue
    } else if (selected.length === 1) {
      this.selectedTextTarget.textContent = selected[0]
    } else {
      this.selectedTextTarget.textContent = `${selected.length} boards selecionados`
    }
  }
}
