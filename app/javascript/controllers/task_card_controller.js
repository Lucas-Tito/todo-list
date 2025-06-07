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

  // Ação principal, chamada ao clicar no card.
  select(event) {
    if (event.target.closest('a, button, input, textarea, select, form, [data-controller~="inline-edit"]')) {
      return
    }

    const isAlreadySelected = this.element.classList.contains(this.activeClass)

    document.querySelectorAll('[data-controller="task-card"]').forEach(controllerElement => {
      if (this.element !== controllerElement) {
        this.application.getControllerForElementAndIdentifier(controllerElement, "task-card")?.deselect()
      }
    });

    if (isAlreadySelected) {
      this.deselect()
    } else {
      this.selectCard()
    }
  }

  // Ativa o modo de "seleção" no card.
  selectCard() {
    this.element.classList.add(this.activeClass)
    if (this.hasOptionsTarget) this.optionsTarget.classList.remove("hidden")
    this.removeIconTargets.forEach(icon => icon.classList.remove("hidden"))
  }

  // Desativa o modo de "seleção".
  deselect() {
    this.element.classList.remove(this.activeClass)
    if (this.hasOptionsTarget) this.optionsTarget.classList.add("hidden")
    this.removeIconTargets.forEach(icon => icon.classList.add("hidden"))

    // Garante que os formulários de adição sejam escondidos ao desmarcar
    if (this.hasAddDateFormTarget) this.addDateFormTarget.classList.add('hidden');
    if (this.hasAddDateButtonTarget) this.addDateButtonTarget.classList.remove('hidden');

    if (this.hasAddPriorityFormTarget) this.addPriorityFormTarget.classList.add('hidden');
    if (this.hasAddPriorityButtonTarget) this.addPriorityButtonTarget.classList.remove('hidden');
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