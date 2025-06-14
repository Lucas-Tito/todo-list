module.exports = {
  // habilita o dark mode baseado em classe
  darkMode: 'class',

  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        // Cores principais com DEFAULT
        primary: {
          DEFAULT: '#3b82f6',
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a'
        },

        secondary: {
          DEFAULT: '#64748b',
          50: '#f8fafc',
          100: '#f1f5f9',
          200: '#e2e8f0',
          300: '#cbd5e1',
          400: '#94a3b8',
          500: '#64748b',
          600: '#475569',
          700: '#334155',
          800: '#1e293b',
          900: '#0f172a'
        },

        success: {
          DEFAULT: '#22c55e',
          light: '#dcfce7',
          dark: '#15803d'
        },

        danger: {
          DEFAULT: '#ef4444',
          light: '#fee2e2',
          dark: '#b91c1c'
        },

        warning: {
          DEFAULT: '#f59e0b',
          light: '#fef3c7',
          dark: '#d97706'
        },

        // Cores semânticas específicas
        background: {
          DEFAULT: '#f8fafc',
          dark: '#374151'
        },
        
        surface: {
          DEFAULT: '#ffffff',
          dark: '#000000'
        },

        textcolor: {
          DEFAULT: '#374151',
          muted: '#6b7280',
          dark: '#ffffff'
        },

        border: {
          DEFAULT: '#e5e7eb',
          dark: '#ef4444'
        }
      }
    }
  },

  plugins: []
}