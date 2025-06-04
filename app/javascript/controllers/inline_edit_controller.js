// app/javascript/controllers/inline_edit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "input", "textarea"] // Removido "form"
  static values = {
    url: String,
    attribute: String,
    originalText: String,
    editing: Boolean // Para rastrear o estado de edição
  }

  connect() {
    this.editingValue = false;
    // Esconder input/textarea inicialmente se não for feito via CSS
    if (this.hasInputTarget) this.inputTarget.classList.add("hidden");
    if (this.hasTextareaTarget) this.textareaTarget.classList.add("hidden");
  }

  edit(event) {
    if (this.editingValue) return; // Já está editando, não faça nada

    event.stopPropagation();
    this.editingValue = true;
    this.originalTextValue = this.displayTarget.textContent.trim();

    this.displayTarget.classList.add("hidden");

    let fieldToEdit;
    if (this.attributeValue === "name" && this.hasInputTarget) {
      fieldToEdit = this.inputTarget;
    } else if (this.attributeValue === "description" && this.hasTextareaTarget) {
      fieldToEdit = this.textareaTarget;
    }

    if (fieldToEdit) {
      fieldToEdit.value = this.originalTextValue;
      fieldToEdit.classList.remove("hidden");
      fieldToEdit.focus();
    } else {
      this.revertToDisplayMode(); // Caso o target não exista
    }
  }

  async save() {
    if (!this.editingValue) return; // Não está editando, não salve

    let newValue;
    let fieldWithValue;

    if (this.attributeValue === "name" && this.hasInputTarget) {
      fieldWithValue = this.inputTarget;
      newValue = fieldWithValue.value;
    } else if (this.attributeValue === "description" && this.hasTextareaTarget) {
      fieldWithValue = this.textareaTarget;
      newValue = fieldWithValue.value;
    } else {
      console.error("Unknown attribute for inline edit:", this.attributeValue);
      this.revertToDisplayMode();
      return;
    }

    // Se o valor não mudou, apenas reverta para o modo de exibição sem chamada à API
    if (newValue === this.originalTextValue) {
      this.revertToDisplayMode();
      return;
    }

    const payload = { board: {} };
    payload.board[this.attributeValue] = newValue;

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        const data = await response.json();
        this.displayTarget.textContent = data[this.attributeValue] || newValue;
        this.originalTextValue = this.displayTarget.textContent; // Atualiza o valor original
      } else {
        const errorData = await response.json();
        console.error("Failed to save:", errorData);
        this.displayTarget.textContent = this.originalTextValue; // Reverte em caso de falha
        // Poderia mostrar uma mensagem de erro para o usuário aqui
      }
    } catch (error) {
      console.error("Error saving:", error);
      this.displayTarget.textContent = this.originalTextValue; // Reverte em caso de erro de rede
    }
    this.revertToDisplayMode();
  }

  cancel() {
    if (!this.editingValue) return; // Não está editando, não cancele

    this.displayTarget.textContent = this.originalTextValue;
    this.revertToDisplayMode();
  }

  revertToDisplayMode() {
    this.editingValue = false;
    if (this.hasInputTarget) this.inputTarget.classList.add("hidden");
    if (this.hasTextareaTarget) this.textareaTarget.classList.add("hidden");
    this.displayTarget.classList.remove("hidden");
  }

  // Manipuladores de eventos para o input/textarea
  handleBlur(event) {
    // Pequeno timeout para permitir que o evento de 'Escape' seja processado antes do blur,
    // caso o usuário clique fora enquanto o foco está no campo.
    // Sem isso, o save() pode ser chamado antes do cancel() via Escape, se o blur ocorrer rápido.
    setTimeout(() => {
      if (this.editingValue) { // Verifica se ainda estamos em modo de edição
        this.save();
      }
    }, 100);
  }

  handleKeydown(event) {
    if (!this.editingValue) return;

    if (event.key === "Escape") {
      event.preventDefault();
      this.cancel();
    } else if (event.key === "Enter") {
      if (this.attributeValue === "name") { // Salvar com Enter apenas para o input de nome (uma linha)
        event.preventDefault();
        this.save();
      }
      // Para o textarea, Enter geralmente cria uma nova linha, então não salvamos por padrão.
      // Se você quiser salvar o textarea com Enter (ou Shift+Enter), adicione a lógica aqui.
    }
  }
}