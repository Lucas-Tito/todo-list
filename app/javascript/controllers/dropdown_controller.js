import { Controller } from "@hotwired/stimulus"

// Controla um menu dropdown, gerenciando sua visibilidade e fechamento.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Prepara a função para ser usada com 'addEventListener'
    this.boundHideOnEscape = this.hideOnEscape.bind(this)
  }

  // Mostra ou esconde o menu.
  toggle(event) {
    // Impede que o clique no botão feche o menu imediatamente
    event.stopPropagation()
    
    const isHidden = this.menuTarget.classList.toggle("hidden")

    // Adiciona ou remove o listener para a tecla 'Escape'
    // apenas quando o menu está aberto.
    if (!isHidden) {
      document.addEventListener("keydown", this.boundHideOnEscape)
    } else {
      document.removeEventListener("keydown", this.boundHideOnEscape)
    }
  }

  // Esconde o menu se o clique ocorrer fora dele.
  hide(event) {
    // Se o menu já está escondido, não faz nada.
    if (this.menuTarget.classList.contains("hidden")) {
      return
    }

    // Se o clique foi fora do elemento do controller, esconde o menu.
    if (!this.element.contains(event.target)) {
      this.hideMenu()
    }
  }

  // Função dedicada para esconder o menu e remover listeners.
  hideMenu() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.boundHideOnEscape)
  }

  // Esconde o menu se a tecla 'Escape' for pressionada.
  hideOnEscape(event) {
    if (event.key === "Escape") {
      this.hideMenu()
    }
  }

  disconnect() {
    // Garante que o listener seja removido se o elemento sumir da página.
    document.removeEventListener("keydown", this.boundHideOnEscape)
  }
}