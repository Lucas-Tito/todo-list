import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="card-hover"
export default class extends Controller {
  static targets = ["card", "gif"]

  connect() {
    // Initially hide the GIF
    this.gifTarget.style.display = "none"
  }

  showGif() {
    // Hide the card and show the GIF
    this.cardTarget.style.display = "none"
    this.gifTarget.style.display = "flex"
  }

  hideGif() {
    // Show the card and hide the GIF
    this.cardTarget.style.display = "flex"
    this.gifTarget.style.display = "none"
  }
}
