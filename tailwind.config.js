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
    }
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
