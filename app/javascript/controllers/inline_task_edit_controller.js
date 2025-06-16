import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "input"] // 'input' can be <input> or <textarea>
  static values = {
    url: String,
    attribute: String,
    originalText: String,
    editing: Boolean,
    startEditing: Boolean
  }

  connect() {
    this.editingValue = false;
    if (this.hasInputTarget) {
      this.inputTarget.classList.add("hidden");
    }
    if (this.hasDisplayTarget) {
      this.displayTarget.classList.remove("hidden");
    }

    if (this.startEditingValue) {
      requestAnimationFrame(() => { // Ensures element is fully rendered by Turbo Stream
        this.edit();
      });
    }
  }

  edit(event) {
    if (event) {
      event.stopPropagation(); // Prevent event bubbling if called by click
      event.preventDefault();  // Prevent default action if it's a link/button
    }
    if (this.editingValue) return;

    this.editingValue = true;
    this.originalTextValue = this.displayTarget.textContent.trim();

    this.displayTarget.classList.add("hidden");
    this.inputTarget.value = this.originalTextValue; // Set value for input/textarea
    this.inputTarget.classList.remove("hidden");
    this.inputTarget.focus();
    if (this.inputTarget.select && typeof this.inputTarget.select === 'function') {
      this.inputTarget.select();
    }
  }

  async save() {
    if (!this.editingValue) return;

    const newValue = this.inputTarget.value;

    if (newValue === this.originalTextValue) {
      this.revertToDisplayMode();
      return;
    }

    const payload = { task: {} };
    payload.task[this.attributeValue] = newValue;

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json" // Expecting JSON response with updated task
        },
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        const data = await response.json();
        this.displayTarget.textContent = data[this.attributeValue] || newValue; // Update from server response
        this.originalTextValue = this.displayTarget.textContent;
        // If controller responded with a Turbo Stream to replace, this manual update might be redundant
        // but good for JSON API pattern.
      } else {
        const errorData = await response.json().catch(() => ({ errors: ["Server error"] }));
        console.error("Failed to save task:", errorData);
        this.displayTarget.textContent = this.originalTextValue; // Revert on failure
        // Consider a more robust error display than alert
        const errorMessage = errorData.errors?.[this.attributeValue]?.join(', ') || errorData.errors?.join(', ') || "Update failed.";
        alert(`Failed to update ${this.attributeValue}: ${errorMessage}`);
      }
    } catch (error) {
      console.error("Error saving task:", error);
      this.displayTarget.textContent = this.originalTextValue;
      alert("Error saving task. Please check your connection.");
    }
    this.revertToDisplayMode();
  }

  cancel() {
    if (!this.editingValue) return;
    this.inputTarget.value = this.originalTextValue; // Revert input value as well
    this.displayTarget.textContent = this.originalTextValue;
    this.revertToDisplayMode();
  }

  revertToDisplayMode() {
    this.editingValue = false;
    this.inputTarget.classList.add("hidden");
    this.displayTarget.classList.remove("hidden");
  }

  handleKeydown(event) {
    if (!this.editingValue) return;

    if (event.key === "Escape") {
      event.preventDefault();
      this.cancel();
    } else if (event.key === "Enter") {
      if (this.inputTarget.tagName.toLowerCase() === "input") {
        event.preventDefault();
        this.save();
      } else if (this.inputTarget.tagName.toLowerCase() === "textarea" && (event.metaKey || event.ctrlKey)) {
        // For textarea, save on Cmd/Ctrl+Enter
        event.preventDefault();
        this.save();
      }
      // Allow Enter for new lines in textarea if not Cmd/Ctrl modified
    }
  }
}