/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './templates/**/*.haml',
    './lib/**/*.rb',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
      colors: {
        // Patreon dark theme backgrounds
        page:          '#000000',   // main page background
        card:          '#000000',   // card surface (same as page)
        raised:        '#282626',   // elevated / hover surface

        // Patreon dark theme accents
        accent:        '#e9def3',   // light lavender — badge text, active links
        'accent-muted':'#c0b4ce',   // muted lavender — nav links, secondary text
        'accent-dim':  '#55515a',   // dark purple-grey — badge backgrounds
        'accent-high': '#615d63',   // badge hover

        // Translucent-white helpers (avoid /opacity in HAML class shorthand)
        'white-10': 'rgba(255,255,255,0.10)',
        'white-20': 'rgba(255,255,255,0.20)',
        'white-25': 'rgba(255,255,255,0.25)',
        'white-30': 'rgba(255,255,255,0.30)',
        'white-35': 'rgba(255,255,255,0.35)',
        'white-55': 'rgba(255,255,255,0.55)',
        'white-60': 'rgba(255,255,255,0.60)',
      },
    }
  },
  safelist: [
    'ring-1', 'ring-accent', 'bg-accent', 'text-page',
  ],
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
