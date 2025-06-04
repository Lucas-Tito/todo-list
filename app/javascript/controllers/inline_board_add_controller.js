// app/javascript/controllers/inline_board_add_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    mainButtonId: String
    // boardsListContainerId: String, // Não é mais necessário se o turbo-stream sempre adiciona ao mesmo container
  };

  connect() {
    // Garante que o botão principal esteja no estado correto ao carregar
    this.showMainButtonIfNotBeingEditedElsewhere();
  }

  async startAddingBoard(event) {
    event.preventDefault();
    this.hideMainButton(); // Esconde o botão principal no topo da página

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    try {
      const response = await fetch("/boards", { // URL para BoardsController#create
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/vnd.turbo-stream.html", // Essencial para que o Rails responda com Turbo Stream
        },
        body: JSON.stringify({ board: { name: "" } }), // Envia um nome vazio, o controller definirá o padrão
      });

      if (!response.ok) {
        // Se a resposta não for OK, tenta ler o corpo como texto para depuração
        const errorText = await response.text();
        throw new Error(
          `Falha ao criar board. Servidor respondeu com status ${response.status}: ${errorText}`
        );
      }
      // Se a resposta for OK e o 'Accept' header estiver correto,
      // o Turbo Drive (do @hotwired/turbo-rails) irá processar o Turbo Stream automaticamente.
      // Não é necessário manipular o response.text() aqui se for um stream válido.
      // O placeholder será substituído e um novo será adicionado pelo stream.
    } catch (error) {
      console.error("Erro ao iniciar a criação do board:", error);
      this.showMainButton(); // Reexibe o botão principal em caso de falha
      // TODO: Seria bom mostrar uma mensagem de erro para o usuário na interface
      alert("Ocorreu um erro ao tentar criar o board. Por favor, tente novamente.");
    }
  }

  // Este método é chamado pelo 'inline-edit-controller' do board recém-adicionado
  // através do data-action="inline-edit:success->inline-board-add#handleExternalEditDone ..."
  // no _board.html.erb. No entanto, essa ligação de evento é para o controller
  // no próprio board, não para este controller do placeholder.
  // A lógica de reexibir o botão principal foi movida para o `inline_edit_controller.js`.
  // Esta função pode ser removida ou repensada se a comunicação entre controllers for diferente.
  // handleExternalEditDone() {
  //   this.showMainButton();
  // }

  hideMainButton() {
    const mainButton = document.getElementById(this.mainButtonIdValue);
    if (mainButton) {
      mainButton.classList.add("hidden");
    }
  }

  showMainButton() {
    const mainButton = document.getElementById(this.mainButtonIdValue);
    if (mainButton) {
      mainButton.classList.remove("hidden");
    }
  }

  // Verifica se algum outro board (recém-adicionado) está em modo de edição inicial
  // para decidir se o botão principal deve ser exibido.
  showMainButtonIfNotBeingEditedElsewhere() {
    // O `inline_edit_controller` no novo board agora é responsável por mostrar o botão principal
    // quando sua edição inicial (save/cancel) é concluída.
    // Esta função no connect() do placeholder garante que, se nenhum board estiver
    // nessa fase de "edição inicial", o botão principal seja mostrado.
    const isAnyNewBoardBeingEdited = document.querySelector(
      '[data-controller="inline-edit"][data-inline-edit-main-new-board-button-id-value]'
    );
    if (!isAnyNewBoardBeingEdited) {
      this.showMainButton();
    } else {
      // Se encontrou um, significa que o botão principal já deve ter sido escondido
      // pelo clique no placeholder, ou será escondido.
      this.hideMainButton();
    }
  }

  disconnect() {
    // Se o placeholder for removido (por exemplo, durante uma navegação Turbo),
    // é uma boa prática tentar garantir que o botão principal esteja visível
    // se nenhuma edição de "novo board" estiver em andamento.
    // this.showMainButtonIfNotBeingEditedElsewhere();
  }
}