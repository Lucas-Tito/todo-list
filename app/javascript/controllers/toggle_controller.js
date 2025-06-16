import { Controller } from "@hotwired/stimulus"

// Manages a element exibition (ex: list of completed tasks)
// and icon rotation.
export default class extends Controller {
  static targets = ["toggleable", "icon"]

  // Action called by 'data-action="click->toggle#fire"'
  fire() {
    // Toggle the 'hidden' class inside target
    this.toggleableTarget.classList.toggle("hidden")

    // Toggle icon rotation class
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("rotate-180")
    }
  }
}