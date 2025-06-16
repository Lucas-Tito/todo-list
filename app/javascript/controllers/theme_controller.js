import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sun", "moon"]

  connect() {
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
    // verify if the targets exist before trying to use them
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