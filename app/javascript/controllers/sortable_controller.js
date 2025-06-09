import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { patch } from '@rails/request.js'

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      onEnd: this.onEnd.bind(this),
    });
  }

  onEnd(event) {
    const { newIndex } = event;
    const listId = event.item.dataset.listId;
    const url = this.urlValue.replace(":id", listId);

    patch(url, {
      body: JSON.stringify({ position: newIndex + 1 }),
      responseKind: "turbo-stream"
    });
  }
}