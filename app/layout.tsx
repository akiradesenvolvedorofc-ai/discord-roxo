import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Violet — sua comunidade", description: "Converse, crie comunidades e fique perto de quem importa." };
export default function RootLayout({ children }: Readonly<{children: React.ReactNode}>) { return <html lang="pt-BR"><body>{children}</body></html>; }
