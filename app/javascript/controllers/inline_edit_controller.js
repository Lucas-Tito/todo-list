// app/javascript/controllers/inline_edit_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // Adicionamos "nameDisplay" como um target opcional
  static targets = ["display", "input", "textarea", "nameDisplay"];
  static values = {
    url: String,
    attribute: String,
    objectName: String,
    originalText: String,
    editing: Boolean,
    startEditing: Boolean,
    mainNewBoardButtonId: String
  };

  connect() {
    this.editingValue = false;
    this.fieldToEdit = this.hasInputTarget ? this.inputTarget : (this.hasTextareaTarget ? this.textareaTarget : null);

    if (!this.fieldToEdit) {
      console.warn("InlineEditController: No input or textarea target found for attribute:", this.attributeValue, "on element:", this.element);
      return;
    }

    if (this.startEditingValue) {
      if (this.objectNameValue === "board" && this.hasMainNewBoardButtonIdValue) {
        this.manageMainButtonVisibility(false);
      }
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
    if (this.editingValue && this.fieldToEdit === document.activeElement) return;

    if (!this.fieldToEdit) return;

    this.editingValue = true;
    
    // *** LÓGICA CORRIGIDA ***
    // Se o target específico 'nameDisplay' existir, usa ele para ler o texto.
    // Senão, usa o comportamento antigo com 'displayTarget'.
    const textSource = this.hasNameDisplayTarget ? this.nameDisplayTarget : this.displayTarget;
    this.originalTextValue = this.hasDisplayTarget ? textSource.textContent.trim() : this.fieldToEdit.value.trim();

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
          Accept: "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const data = await response.json();

        // *** LÓGICA CORRIGIDA ***
        // Se o target 'nameDisplay' existir, atualiza o texto nele.
        // Senão, usa o comportamento antigo.
        const textTarget = this.hasNameDisplayTarget ? this.nameDisplayTarget : this.displayTarget;
        if (this.hasDisplayTarget) {
          textTarget.textContent = data[this.attributeValue] || newValue;
        }
        
        this.originalTextValue = data[this.attributeValue] || newValue;
        this.revertToDisplayModeAndNotify("success", data);
      } else {
        const errorData = await response.json().catch(() => ({}));
        console.error(`Failed to save ${this.objectNameValue}:`, errorData);
        if (this.hasDisplayTarget) {
          const textTarget = this.hasNameDisplayTarget ? this.nameDisplayTarget : this.displayTarget;
          textTarget.textContent = this.originalTextValue;
        }
        this.fieldToEdit.value = this.originalTextValue;
        this.revertToDisplayModeAndNotify("error", errorData);
      }
    } catch (error) {
      console.error(`Error saving ${this.objectNameValue}:`, error);
      if (this.hasDisplayTarget) {
        const textTarget = this.hasNameDisplayTarget ? this.nameDisplayTarget : this.displayTarget;
        textTarget.textContent = this.originalTextValue;
      }
      this.fieldToEdit.value = this.originalTextValue;
      this.revertToDisplayModeAndNotify("error", { message: error.message });
    }
  }

  cancel() {
    if (!this.editingValue || !this.fieldToEdit) return;
    this.fieldToEdit.value = this.originalTextValue;
    if (this.hasDisplayTarget) {
      const textTarget = this.hasNameDisplayTarget ? this.nameDisplayTarget : this.displayTarget;
      textTarget.textContent = this.originalTextValue;
    }
    this.revertToDisplayModeAndNotify("cancel");
  }

  revertToDisplayModeAndNotify(eventName, eventDetail = {}) {
    this.editingValue = false;
    this.switchToDisplayModeVisuals();
    this.dispatch(eventName, { detail: eventDetail });

    if (this.objectNameValue === "board" && this.hasMainNewBoardButtonIdValue) {
      this.manageMainButtonVisibility(true);
    }
  }

  manageMainButtonVisibility(show) {
    if (this.hasMainNewBoardButtonIdValue) {
      const mainButton = document.getElementById(this.mainNewBoardButtonIdValue);
      if (mainButton) {
        mainButton.classList[show ? "remove" : "add"]("hidden");
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