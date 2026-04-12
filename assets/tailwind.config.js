module.exports = {
  darkMode: false,
  content: ["./js/**/*.js", "./css/**/*.*css", "../lib/*_web/**/*.*ex", "../extra/**/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        gray: {
          950: "#0A1F3D"
        },
        fluxo: {
          50: "#E6F0FF",
          100: "#CCE0FF",
          200: "#99C2FF",
          300: "#66A3FF",
          400: "#3385FF",
          500: "#0066FF",
          600: "#0052CC",
          700: "#003D99",
          800: "#0A1F3D",
          900: "#0D2B52",
          950: "#020617"
        },
        cyan: {
          50: "#E6FEFF",
          100: "#CCFDFE",
          200: "#99FBFD",
          300: "#66F8FC",
          400: "#33F5FB",
          500: "#00F2FE",
          600: "#00C2CB",
          700: "#009199",
          800: "#006166",
          900: "#003033"
        }
      },
      fontFamily: {
        sans: ["Poppins", "Inter", "system-ui", "sans-serif"],
        display: ["Montserrat", "Inter", "system-ui", "sans-serif"]
      },
      backgroundImage: {
        "fluxo-gradient": "linear-gradient(135deg, #0066FF 0%, #00F2FE 100%)",
        "fluxo-gradient-dark": "linear-gradient(135deg, #020617 0%, #0A1F3D 50%, #003D99 100%)"
      },
      boxShadow: {
        "fluxo": "0 4px 14px rgba(0, 102, 255, 0.25)",
        "fluxo-lg": "0 10px 40px -5px rgba(0, 102, 255, 0.35)"
      }
    }
  },
  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/typography")]
}
