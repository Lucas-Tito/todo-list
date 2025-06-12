// app/javascript/controllers/theme_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sun", "moon"]

  connect() {
    // A função applyTheme já faz o que precisamos na conexão inicial.
    this.applyTheme();
    this.updateIcons();
  }

  toggle() {
    if (localStorage.theme === 'dark') {
      localStorage.theme = 'light';
    } else {
      localStorage.theme = 'dark';
    }
    this.applyTheme();
    this.updateIcons();
  }

  applyTheme() {
    if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }

  updateIcons() {
    // Verifica se os targets existem antes de tentar usá-los
    if (this.hasSunTarget && this.hasMoonTarget) {
      if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        this.sunTarget.classList.remove('hidden');
        this.moonTarget.classList.add('hidden');
      } else {
        this.sunTarget.classList.add('hidden');
        this.moonTarget.classList.remove('hidden');
      }
    }
  }
}