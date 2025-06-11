import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  async startAddingBoard(event) {
    event.preventDefault();
    this.element.classList.add("hidden");

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch("/boards", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/vnd.turbo-stream.html",
        },
        body: JSON.stringify({ board: { name: "" } }), // O controller definirá um nome padrão
      });

      if (!response.ok) {
        throw new Error("Falha ao criar o board.");
      }
      // A resposta turbo-stream será processada automaticamente pelo Turbo
    } catch (error) {
      console.error(error);
      this.element.classList.remove("hidden"); // Reaparece o botão se der erro
      alert("Ocorreu um erro ao criar o board.");
    }
  }
}