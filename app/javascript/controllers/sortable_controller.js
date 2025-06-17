import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      ghostClass: "sortable-ghost-custom",  
      draggable: ".list",
      onStart: this.onStart.bind(this),
      onEnd: this.onEnd.bind(this),
    });
  }

  /**
   * Hides the original element when dragging starts.
  */
  onStart(event) {
    event.item.classList.add("sortable-item-dragging");
  }

  onEnd(event) {
    event.item.classList.remove("sortable-item-dragging");
    
    const { newIndex } = event;
    const listId = event.item.dataset.listId;
    const url = this.urlValue.replace(":id", listId);

    // Searchs for CSRF token from the page to authenticate the request in Rails.
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ position: newIndex + 1 })
    })
    .then(response => {
      if (!response.ok) {
        // Treat errors if the server respond with a fail.
        console.error('Falha ao mover o item.');
      }
      // If responde is Ok, Rails executes the move action with success.
      // No further action is needed
    })
    .catch(error => console.error('Erro de rede:', error));
  }
}