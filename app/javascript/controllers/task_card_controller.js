import { Controller } from "@hotwired/stimulus"

/**
 * Manages the active state of a task_card.
 */
export default class extends Controller {
  static targets = [
    "options", "removeIcon",
    "addDateButton", "addDateForm",
    "addPriorityButton", "addPriorityForm"
  ]
  static classes = [ "active" ]

  connect() {
    // "bind" function is necessary to the "this" refers to the controller
    // inside 'deselectIfOutside' when it's called by click.
    this.boundDeselectIfOutside = this.deselectIfOutside.bind(this);
  }

  disconnect() {
    // Ensures the listener will be removed if the controller is disconnected from DOM,
    // preventing memory leaks.
    document.removeEventListener("click", this.boundDeselectIfOutside);
  }

  // Main action, called when card is clicked in.
  select(event) {
    // Prevents the selection happen when buttons or links are clicked.
    if (event.target.closest('a, button, input, textarea, select, form, [data-controller~="inline-edit"]')) {
      return
    }

    const isAlreadySelected = this.element.classList.contains(this.activeClass)

    // Deselect all other cards
    document.querySelectorAll('[data-controller="task-card"]').forEach(controllerElement => {
      if (this.element !== controllerElement) {
        this.application.getControllerForElementAndIdentifier(controllerElement, "task-card")?.deselect()
      }
    });

    // Toggle card selection
    if (isAlreadySelected) {
      this.deselect()
    } else {
      this.selectCard()
    }
  }

  // Activte selection mode in card.
  selectCard() {
    this.element.classList.add(this.activeClass)
    // Shows date and priority forms
    if (this.hasOptionsTarget) this.optionsTarget.classList.remove("hidden")

    // Listen for clicks in the entire document to 
    // esure the card is deselect when a click happen out of focus.
    document.addEventListener("click", this.boundDeselectIfOutside);
  }

  // Desable the selection mode.
  deselect() {
    this.element.classList.remove(this.activeClass)
    // Hide date and priority options
    if (this.hasOptionsTarget) this.optionsTarget.classList.add("hidden")

    // Ensure the add forms will be hidden when unselected
    if (this.hasAddDateFormTarget) this.addDateFormTarget.classList.add('hidden');
    if (this.hasAddDateButtonTarget) this.addDateButtonTarget.classList.remove('hidden');

    if (this.hasAddPriorityFormTarget) this.addPriorityFormTarget.classList.add('hidden');
    if (this.hasAddPriorityButtonTarget) this.addPriorityButtonTarget.classList.remove('hidden');

    // Stop listening for click to save resources.
    document.removeEventListener("click", this.boundDeselectIfOutside);
  }

  deselectIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.deselect();
    }
  }

  // Action to reveal date form
  showAddDateForm(event) {
    event.preventDefault()
    event.stopPropagation() // Prevent the card diselection
    this.addDateButtonTarget.classList.add("hidden")
    this.addDateFormTarget.classList.remove("hidden")
    this.addDateFormTarget.querySelector('input[type="date"]').focus()
  }

  // Action to reveal priority form
  showAddPriorityForm(event) {
    event.preventDefault()
    event.stopPropagation()
    this.addPriorityButtonTarget.classList.add("hidden")
    this.addPriorityFormTarget.classList.remove("hidden")
    this.addPriorityFormTarget.querySelector('select').focus()
  }
}