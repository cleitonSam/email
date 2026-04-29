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
      },
      keyframes: {
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        },
        "fade-in-scale": {
          "0%": { opacity: "0", transform: "scale(0.96)" },
          "100%": { opacity: "1", transform: "scale(1)" }
        },
        "pulse-soft": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.5" }
        },
        "aurora": {
          "0%, 100%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" }
        },
        "float": {
          "0%, 100%": { transform: "translateY(0px) scale(1)" },
          "50%": { transform: "translateY(-20px) scale(1.05)" }
        },
        "glow": {
          "0%, 100%": { boxShadow: "0 0 20px rgba(0, 102, 255, 0.3)" },
          "50%": { boxShadow: "0 0 40px rgba(0, 102, 255, 0.6), 0 0 80px rgba(0, 242, 254, 0.2)" }
        }
      },
      animation: {
        "fade-in": "fade-in 0.4s ease-out forwards",
        "fade-in-scale": "fade-in-scale 0.5s ease-out forwards",
        "pulse-soft": "pulse-soft 2.5s ease-in-out infinite",
        "aurora": "aurora 8s ease infinite",
        "float": "float 6s ease-in-out infinite",
        "float-delayed": "float 6s ease-in-out 2s infinite",
        "glow": "glow 3s ease-in-out infinite"
      }
    }
  },
  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/typography")]
}
