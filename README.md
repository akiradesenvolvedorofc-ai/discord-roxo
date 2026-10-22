# Discord Roxo / Violet Community

Aplicação de comunidades com visual roxo premium, construída com Next.js 14 App Router, TypeScript, Tailwind CSS, Framer Motion e Supabase.

## Requisitos
- Node.js 18.17+ (recomendado Node.js 20 LTS)
- npm
- Projeto Supabase

## 1. Configurar o Supabase
1. Abra o [SQL Editor do Supabase](https://supabase.com/dashboard/project/_/sql/new).
2. Abra `supabase/schema.sql` neste repositório, copie todo o conteúdo e execute no SQL Editor.
3. Em **Authentication → URL Configuration**, configure a Site URL para `http://localhost:3000` durante o desenvolvimento. Adicione também `http://localhost:3000/**` às Redirect URLs. Ao publicar, adicione a URL do seu domínio/Vercel (por exemplo `https://seu-projeto.vercel.app/**`).
4. Em **Database → Replication** (ou Database → Publications), confirme que `public.messages` está habilitada na publicação `supabase_realtime`. O SQL tenta adicioná-la automaticamente.
5. Se a confirmação de e-mail estiver ativa, confirme o e-mail recebido antes de fazer login. O trigger cria o perfil, o servidor padrão **Meu Servidor** e o canal **geral** quando o usuário é inserido em `auth.users`.

> Execute o schema em um projeto Supabase de desenvolvimento/novo. O SQL cria políticas e tabelas com nomes próprios e pode substituir triggers/policies que tenham exatamente os mesmos nomes.

## 2. Variáveis de ambiente
O `.env.local` incluído contém a URL do projeto e a chave publishable/anon fornecida. Para usar outro projeto, copie `.env.local.example` para `.env.local` e preencha os valores:

```bash
cp .env.local.example .env.local
```

Nunca coloque `service_role`, chaves secretas ou tokens administrativos em variáveis `NEXT_PUBLIC_*`. A chave publishable/anon é destinada ao cliente e o acesso aos dados deve ser protegido pelas políticas RLS.

## 3. Instalar e executar
Na pasta `discord-roxo/`:

```bash
npm install
npm run dev
```

Acesse http://localhost:3000. Para validar a compilação de produção:

```bash
npm run build
npm run start
```

## 4. GitHub
O `.gitignore` exclui `.env.local`, `node_modules`, `.next` e diretórios de build. O exemplo de ambiente pode ser commitado. Antes de publicar, confirme que o arquivo real `.env.local` não foi adicionado ao Git:

```bash
git status --short
```

Se já tiver sido commitado anteriormente, remova-o do índice (`git rm --cached .env.local`) e faça a rotação das credenciais afetadas.

## 5. Deploy na Vercel
1. Envie o repositório ao GitHub.
2. Importe-o na [Vercel](https://vercel.com/new).
3. Em **Settings → Environment Variables**, cadastre `NEXT_PUBLIC_SUPABASE_URL` e `NEXT_PUBLIC_SUPABASE_ANON_KEY` com os valores do seu projeto Supabase.
4. Em Supabase Authentication → URL Configuration, adicione o domínio de produção da Vercel às Redirect URLs e ajuste a Site URL.
5. Faça deploy. Não é necessário editar configurações de build: a Vercel detecta Next.js.

## Rota de mensagens diretas

O Next.js reserva nomes de pastas iniciados por `@` para parallel routes. Para evitar conflito de build, a página fica fisicamente em `app/channels/me/page.tsx`; o middleware reescreve `/channels/@me` para essa rota, mantendo o endereço solicitado no navegador.

## Recursos incluídos
- Cadastro/login com Supabase Auth e sessão em cookies via `@supabase/ssr`.
- Middleware para proteger `/channels/**` e redirecionar sessões autenticadas.
- Criação automática de perfil, servidor padrão e canal `geral` via trigger SQL.
- Listagem de servidores, criação de servidor e criação de canais de texto/voz (canais de voz são estrutura visual, sem áudio WebRTC).
- Chat com histórico, inserção em tempo real por Supabase Realtime, envio com Enter e quebra de linha com Shift+Enter.
- Indicador de digitação via broadcast Realtime e hook de presença online.
- Tabelas base e políticas RLS para mensagens diretas, participantes de DM e amizades.
- Layout responsivo, tema roxo, animações e estados de carregamento.

## Limitações e notas importantes
- Mensagens diretas e amizades têm o schema/RLS preparado, mas a interface de gestão completa ainda não está implementada nesta primeira versão.
- O sistema de voz apresenta canais de voz visualmente; chamadas reais exigem sinalização e mídia WebRTC/serviço de voz.
- A presença online está disponível no hook `usePresence`; o painel completo de membros online ainda não está conectado à interface.
- O cadastro pode exigir confirmação de e-mail conforme as configurações de Auth do seu projeto.
- O Realtime precisa estar habilitado para `public.messages` no Supabase. As policies RLS continuam sendo a barreira de segurança dos dados.

## Estrutura
```text
discord-roxo/
├── .env.local
├── .env.local.example
├── .gitignore
├── README.md
├── middleware.ts
├── next.config.js
├── package.json
├── postcss.config.js
├── tailwind.config.ts
├── tsconfig.json
├── app/
│   ├── globals.css
│   ├── layout.tsx
│   ├── page.tsx
│   ├── login/page.tsx
│   └── channels/
│       ├── me/page.tsx (rewrite para /channels/@me)
│       └── [serverId]/[channelId]/page.tsx
├── components/
├── hooks/
├── lib/supabase/
└── supabase/schema.sql
```
