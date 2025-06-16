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
        body: JSON.stringify({ board: { name: "" } }), // Controller defines default name
      });

      if (!response.ok) {
        throw new Error("Falha ao criar o board.");
      }
    } catch (error) {
      console.error(error);
      this.element.classList.remove("hidden"); // Re render button if there is a error
      alert("Ocorreu um erro ao criar o board.");
    }
  }
}