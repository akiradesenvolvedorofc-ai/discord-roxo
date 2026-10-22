import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./app/**/*.{js,ts,jsx,tsx,mdx}", "./components/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: { extend: {
    colors: { surface: {950:"#08040f",900:"#0d0618",800:"#150a24",700:"#1d1032",600:"#271540",500:"#331a52"}, brand: {300:"#c9a1ff",400:"#b57bff",500:"#9b5cff",600:"#7c3aed",700:"#6d28d9",800:"#5522b3"} },
    fontFamily: { sans: ["Inter", "ui-sans-serif", "system-ui"] },
    boxShadow: { glow: "0 0 35px rgba(155,92,255,.22)" },
    animation: { float: "float 9s ease-in-out infinite", gradient: "gradient 14s ease infinite", pulseglow: "pulseglow 2.6s ease-in-out infinite" },
    keyframes: { float: {"0%,100%":{transform:"translate3d(0,0,0)"},"50%":{transform:"translate3d(22px,-24px,0)"}}, gradient: {"0%,100%":{backgroundPosition:"0% 50%"},"50%":{backgroundPosition:"100% 50%"}}, pulseglow: {"0%,100%":{boxShadow:"0 0 18px rgba(155,92,255,.35)"},"50%":{boxShadow:"0 0 38px rgba(155,92,255,.75)"}} }
  }}, plugins: []
};
export default config;
