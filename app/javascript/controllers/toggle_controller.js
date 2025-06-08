// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

// Controla a exibição de um elemento (ex: lista de tarefas concluídas)
// e a rotação de um ícone.
export default class extends Controller {
  static targets = ["toggleable", "icon"]

  // Esta ação é chamada pelo 'data-action="click->toggle#fire"'
  fire() {
    // Alterna a classe 'hidden' no elemento alvo (a lista)
    this.toggleableTarget.classList.toggle("hidden")

    // Alterna uma classe para girar o ícone da seta
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("rotate-180")
    }
  }
}