// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["hidden"]

  connect() {
    this.menuTarget.classList.add(this.hiddenClass);
  }

  toggle(event) {
    event.stopPropagation();
    this.menuTarget.classList.toggle(this.hiddenClass);
  }

  hide(event) {
    // Esconde se o clique foi fora do elemento do controller (<div data-controller="dropdown">)
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add(this.hiddenClass);
    }
  }
}