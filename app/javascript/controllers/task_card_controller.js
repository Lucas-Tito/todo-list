import { Controller } from "@hotwired/stimulus"

/**
 * Controla o estado de seleção de um card de tarefa.
 */
export default class extends Controller {
  static targets = [
    "options", "removeIcon",
    "addDateButton", "addDateForm",
    "addPriorityButton", "addPriorityForm"
  ]
  static classes = [ "active" ]

  connect() {
    // A função 'bind' é necessária para que o 'this' se refira ao controller
    // dentro da função 'deselectIfOutside' quando ela for chamada pelo clique.
    this.boundDeselectIfOutside = this.deselectIfOutside.bind(this);
  }

  disconnect() {
    // Garante que o listener seja removido se o controller for desconectado da DOM,
    // evitando memory leaks.
    document.removeEventListener("click", this.boundDeselectIfOutside);
  }

  // Ação principal, chamada ao clicar no card.
  select(event) {
    // Impede que a seleção aconteça ao clicar em botões, links, etc.
    if (event.target.closest('a, button, input, textarea, select, form, [data-controller~="inline-edit"]')) {
      return
    }

    const isAlreadySelected = this.element.classList.contains(this.activeClass)

    // Deseleciona todos os outros cards
    document.querySelectorAll('[data-controller="task-card"]').forEach(controllerElement => {
      if (this.element !== controllerElement) {
        this.application.getControllerForElementAndIdentifier(controllerElement, "task-card")?.deselect()
      }
    });

    // Alterna a seleção do card atual
    if (isAlreadySelected) {
      this.deselect()
    } else {
      this.selectCard()
    }
  }

  // Ativa o modo de "seleção" no card.
  selectCard() {
    this.element.classList.add(this.activeClass)
    // Mostra o container de opções (formulários de data/prioridade)
    if (this.hasOptionsTarget) this.optionsTarget.classList.remove("hidden")

    // ouve cliques no documento inteiro para garantir que o card seja deselecionado no out of focus.
    document.addEventListener("click", this.boundDeselectIfOutside);
  }

  // Desativa o modo de "seleção".
  deselect() {
    this.element.classList.remove(this.activeClass)
    // Esconde o container de opções
    if (this.hasOptionsTarget) this.optionsTarget.classList.add("hidden")

    // Garante que os formulários de adição sejam escondidos ao desmarcar
    if (this.hasAddDateFormTarget) this.addDateFormTarget.classList.add('hidden');
    if (this.hasAddDateButtonTarget) this.addDateButtonTarget.classList.remove('hidden');

    if (this.hasAddPriorityFormTarget) this.addPriorityFormTarget.classList.add('hidden');
    if (this.hasAddPriorityButtonTarget) this.addPriorityButtonTarget.classList.remove('hidden');

    // Para de "ouvir" os cliques para não gastar recursos à toa.
    document.removeEventListener("click", this.boundDeselectIfOutside);
  }

  deselectIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.deselect();
    }
  }

  // Ação para revelar o formulário de adicionar data
  showAddDateForm(event) {
    event.preventDefault()
    event.stopPropagation() // Impede que o card seja desmarcado
    this.addDateButtonTarget.classList.add("hidden")
    this.addDateFormTarget.classList.remove("hidden")
    this.addDateFormTarget.querySelector('input[type="date"]').focus()
  }

  // Ação para revelar o formulário de adicionar prioridade
  showAddPriorityForm(event) {
    event.preventDefault()
    event.stopPropagation()
    this.addPriorityButtonTarget.classList.add("hidden")
    this.addPriorityFormTarget.classList.remove("hidden")
    this.addPriorityFormTarget.querySelector('select').focus()
  }
}