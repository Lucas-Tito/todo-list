// app/javascript/controllers/placeholder_form_manager_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { mainButtonId: String };

  connect() {
    // Esconde o botão principal quando este formulário placeholder aparece
    this.hideMainButton();
  }

  disconnect() {
    // Quando este placeholder é removido (ex: substituído por um board real),
    // a lógica para reexibir o botão principal será tratada pelo
    // inline-edit-controller do novo board.
    // Se este for o último placeholder e ele for removido sem um board
    // tomando seu lugar (improvável no fluxo normal), o botão principal
    // poderia ficar escondido. A melhor abordagem é o inline-edit do novo board
    // sempre tentar mostrar o botão principal ao finalizar sua edição inicial.
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
