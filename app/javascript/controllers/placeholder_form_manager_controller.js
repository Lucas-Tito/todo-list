import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { mainButtonId: String };

  connect() {
    // hides the main button when this placeholder form show up
    this.hideMainButton();
  }

  disconnect() {

  }

  hideMainButton() {
    if (this.hasMainButtonIdValue) {
      const mainButton = document.getElementById(this.mainButtonIdValue);
      if (mainButton) {
        mainButton.classList.add("hidden");
      }
    }
  }
}
