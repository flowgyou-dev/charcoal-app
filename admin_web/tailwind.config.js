/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        charcoal: {
          header: '#243D3C',
          dark: '#1B2F2E',
          sidebar: '#293E3E',
          hover: '#344E4D',
          canvas: '#F3F5F4',
          border: '#DCE2E0',
          ink: '#1E2929',
          muted: '#617070',
          eco: '#3E7C59',
          sage: '#D5DDD9',
        },
      },
    },
  },
  plugins: [],
}
