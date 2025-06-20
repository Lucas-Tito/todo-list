import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static values = { url: String };

  select(event) {
    event.preventDefault();
    const newColor = event.currentTarget.dataset.listColorColorParam;
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    const payload = {
      list: {
        color: newColor,
      },
    };

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html",
      },
      body: JSON.stringify(payload),
    })
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html))
    .catch(error => {
      console.error("Erro ao atualizar a cor da lista:", error);
    });
  }
}