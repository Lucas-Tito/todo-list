import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    mainButtonId: String
  };

  connect() {
    // Ensure main button is in a correct state to load
    this.showMainButtonIfNotBeingEditedElsewhere();
  }

  async startAddingList(event) {
    event.preventDefault();
    this.hideMainButton(); // Hides main button in the top of page

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch("/lists", { // URL to ListsController#create
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/vnd.turbo-stream.html", // Essential to rails respond with Turbo Stream
        },
        body: JSON.stringify({ list: { name: "" } }), // Sends empty name, controller will define default name
      });

      if (!response.ok) {
        // If reponse is different from OK, trys to read body with text for debugging
        const errorText = await response.text();
        throw new Error(
          `Falha ao criar list. Servidor respondeu com status ${response.status}: ${errorText}`
        );
      }
    } catch (error) {
      console.error("Erro ao iniciar a criação do list:", error);
      this.showMainButton(); // Reexibe o botão principal em caso de falha
      // TODO: Seria bom mostrar uma mensagem de erro para o usuário na interface
      alert("Ocorreu um erro ao tentar criar o list. Por favor, tente novamente.");
    }
  }

  hideMainButton() {
    const mainButton = document.getElementById(this.mainButtonIdValue);
    if (mainButton) {
      mainButton.classList.add("hidden");
    }
  }

  showMainButton() {
    const mainButton = document.getElementById(this.mainButtonIdValue);
    if (mainButton) {
      mainButton.classList.remove("hidden");
    }
  }

  // Verifies if some other list list (added recently) is in initial edit mode,
  // to decide if the main button should be shown.
  showMainButtonIfNotBeingEditedElsewhere() {
    // This function inside connect() ensures that, 
    // if no list is in initial edit phase, the main button will be shown.
    const isAnyNewListBeingEdited = document.querySelector(
      '[data-controller="inline-edit"][data-inline-edit-main-new-list-button-id-value]'
    );
    if (!isAnyNewListBeingEdited) {
      this.showMainButton();
    } else {
      // If one is found, it means that the main button is already hidden
      // by the click in placeholder, or will be hidden.
      this.hideMainButton();
    }
  }

  disconnect() {

  }
}