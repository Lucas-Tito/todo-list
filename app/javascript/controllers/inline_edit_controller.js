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
    startEditing: Boolean,
    mainNewBoardButtonId: String // Opcional: ID do botão principal "Novo Board"
  };

  connect() {
    this.editingValue = false;
    // Determina qual campo de input usar (input ou textarea)
    this.fieldToEdit = this.hasInputTarget ? this.inputTarget : (this.hasTextareaTarget ? this.textareaTarget : null);

    if (!this.fieldToEdit) {
      console.warn("InlineEditController: No input or textarea target found for attribute:", this.attributeValue, "on element:", this.element);
      return;
    }

    if (this.startEditingValue) {
      // Esconde o botão principal se estivermos começando a editar um NOVO board
      if (this.objectNameValue === "board" && this.hasMainNewBoardButtonIdValue) {
        this.manageMainButtonVisibility(false); // false para esconder
      }
      // Adia a chamada para edit() para garantir que o DOM esteja pronto, especialmente após Turbo Streams
      requestAnimationFrame(() => this.edit());
    } else {
      this.switchToDisplayModeVisuals();
    }
  }

  switchToDisplayModeVisuals() {
    if (this.fieldToEdit) this.fieldToEdit.classList.add("hidden");
    if (this.hasDisplayTarget) this.displayTarget.classList.remove("hidden");
  }

  switchToEditModeVisuals() {
    if (this.hasDisplayTarget) this.displayTarget.classList.add("hidden");
    if (this.fieldToEdit) {
      this.fieldToEdit.value = this.originalTextValue;
      this.fieldToEdit.classList.remove("hidden");
      this.fieldToEdit.focus();
      if (typeof this.fieldToEdit.select === "function") {
        this.fieldToEdit.select();
      }
    }
  }

  edit(event) {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    // Evita reentrar no modo de edição se já estiver editando e o campo de input já estiver focado
    if (this.editingValue && this.fieldToEdit === document.activeElement) return;

    if (!this.fieldToEdit) return; // Não faz nada se não houver campo de edição

    this.editingValue = true;
    this.originalTextValue = this.hasDisplayTarget ? this.displayTarget.textContent.trim() : this.fieldToEdit.value.trim();
    this.switchToEditModeVisuals();
  }

  async save() {
    if (!this.editingValue || !this.fieldToEdit) return;

    const newValue = this.fieldToEdit.value;

    if (newValue === this.originalTextValue) {
      this.revertToDisplayModeAndNotify("cancel");
      return;
    }

    const payload = {};
    payload[this.objectNameValue] = {};
    payload[this.objectNameValue][this.attributeValue] = newValue;

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          Accept: "application/json", // Espera JSON de volta para atualizar o display
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
        this.fieldToEdit.value = this.originalTextValue;
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
    if (!this.editingValue || !this.fieldToEdit) return;
    this.fieldToEdit.value = this.originalTextValue;
    if (this.hasDisplayTarget) this.displayTarget.textContent = this.originalTextValue;
    this.revertToDisplayModeAndNotify("cancel");
  }

  revertToDisplayModeAndNotify(eventName, eventDetail = {}) {
    this.editingValue = false;
    this.switchToDisplayModeVisuals();
    this.dispatch(eventName, { detail: eventDetail });

    // Se este controller estava editando um board recém-criado, reexibe o botão principal.
    if (this.objectNameValue === "board" && this.hasMainNewBoardButtonIdValue) {
      this.manageMainButtonVisibility(true); // true para mostrar
    }
  }

  manageMainButtonVisibility(show) {
    if (this.hasMainNewBoardButtonIdValue) {
      const mainButton = document.getElementById(this.mainNewBoardButtonIdValue);
      if (mainButton) {
        if (show) {
          mainButton.classList.remove("hidden");
        } else {
          mainButton.classList.add("hidden");
        }
      }
    }
  }

  handleBlur(event) {
    if (this.element.contains(event.relatedTarget)) {
      return;
    }
    setTimeout(() => {
      if (this.editingValue && this.fieldToEdit && this.fieldToEdit !== document.activeElement) {
        this.save();
      }
    }, 150);
  }

  handleKeydown(event) {
    if (!this.editingValue || !this.fieldToEdit) return;
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
