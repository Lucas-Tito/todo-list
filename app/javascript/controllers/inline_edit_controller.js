// app/javascript/controllers/inline_edit_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "input", "textarea"];
  static values = {
    url: String,
    attribute: String,
    objectName: String, // "board" ou "task"
    originalText: String,
    editing: Boolean,
    startEditing: Boolean, // Para iniciar editando
    mainNewBoardButtonId: String // Opcional: ID do botão principal "Novo Board"
  };

  connect() {
    this.editingValue = false;
    this.fieldToEdit = this.hasInputTarget ? this.inputTarget : this.textareaTarget;

    if (this.startEditingValue) {
      requestAnimationFrame(() => this.edit()); // Adia para garantir que o DOM está pronto
    } else {
      this.switchToDisplayModeVisuals();
    }
  }

  switchToDisplayModeVisuals() {
    this.fieldToEdit.classList.add("hidden");
    if (this.hasDisplayTarget) this.displayTarget.classList.remove("hidden");
  }

  switchToEditModeVisuals() {
    if (this.hasDisplayTarget) this.displayTarget.classList.add("hidden");
    this.fieldToEdit.value = this.originalTextValue;
    this.fieldToEdit.classList.remove("hidden");
    this.fieldToEdit.focus();
    if (typeof this.fieldToEdit.select === "function") {
      this.fieldToEdit.select();
    }
  }

  edit(event) {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    if (this.editingValue && this.fieldToEdit === document.activeElement) return;


    this.editingValue = true;
    this.originalTextValue = this.hasDisplayTarget ? this.displayTarget.textContent.trim() : this.fieldToEdit.value.trim();
    this.switchToEditModeVisuals();
  }

  async save() {
    if (!this.editingValue) return;

    const newValue = this.fieldToEdit.value;

    if (newValue === this.originalTextValue) {
      this.revertToDisplayModeAndNotify("cancel");
      return;
    }

    const payload = {};
    payload[this.objectNameValue] = {}; // Ex: { board: {} } ou { task: {} }
    payload[this.objectNameValue][this.attributeValue] = newValue;

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const data = await response.json();
        if (this.hasDisplayTarget) {
          this.displayTarget.textContent = data[this.attributeValue] || newValue;
        }
        this.originalTextValue = data[this.attributeValue] || newValue;
        this.revertToDisplayModeAndNotify("success", data);
      } else {
        const errorData = await response.json().catch(() => ({}));
        console.error(`Failed to save ${this.objectNameValue}:`, errorData);
        if (this.hasDisplayTarget) this.displayTarget.textContent = this.originalTextValue;
        this.fieldToEdit.value = this.originalTextValue; // Revert input on error too
        // alert(`Error: ${errorData.errors?.[this.attributeValue]?.join(', ') || 'Could not save'}`);
        this.revertToDisplayModeAndNotify("error", errorData);
      }
    } catch (error) {
      console.error(`Error saving ${this.objectNameValue}:`, error);
      if (this.hasDisplayTarget) this.displayTarget.textContent = this.originalTextValue;
      this.fieldToEdit.value = this.originalTextValue;
      this.revertToDisplayModeAndNotify("error", { message: error.message });
    }
  }

  cancel() {
    if (!this.editingValue) return;
    this.fieldToEdit.value = this.originalTextValue; // Revert input before hiding
    if (this.hasDisplayTarget) this.displayTarget.textContent = this.originalTextValue;
    this.revertToDisplayModeAndNotify("cancel");
  }

  revertToDisplayModeAndNotify(eventName, eventDetail = {}) {
    this.editingValue = false;
    this.switchToDisplayModeVisuals();
    this.dispatch(eventName, { detail: eventDetail });

    // Se este controller estava editando um board recém-criado, reexibe o botão principal.
    if (this.objectNameValue === "board" && this.hasMainNewBoardButtonIdValue && this.mainNewBoardButtonIdValue) {
      const mainButton = document.getElementById(this.mainNewBoardButtonIdValue);
      if (mainButton) mainButton.classList.remove("hidden");
    }
  }

  handleBlur(event) {
    // Evita salvar se o clique foi em um botão de ação do próprio controller ou similar
    if (this.element.contains(event.relatedTarget)) {
      return;
    }
    // Pequeno timeout para permitir que "Enter" ou "Escape" sejam processados primeiro
    setTimeout(() => {
      if (this.editingValue && this.fieldToEdit !== document.activeElement) {
        this.save();
      }
    }, 150);
  }

  handleKeydown(event) {
    if (!this.editingValue) return;
    if (event.key === "Escape") {
      event.preventDefault();
      this.cancel();
    } else if (event.key === "Enter") {
      if (this.fieldToEdit.tagName.toLowerCase() === "input") {
        event.preventDefault();
        this.save();
      } else if (this.fieldToEdit.tagName.toLowerCase() === "textarea" && (event.metaKey || event.ctrlKey)) {
        event.preventDefault();
        this.save();
      }
    }
  }
}