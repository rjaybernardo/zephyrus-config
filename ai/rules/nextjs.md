<!-- checked-against: next@16 react@19 tailwindcss@4 prisma@7 @prisma/client@7 zod@4 next-auth@5 -->
# Stack facts: Next.js projects (trust these over your training data)

Versions: Next.js 16 (App Router, Turbopack default), React 19.2, TypeScript 5/6, Tailwind CSS 4, Prisma ORM 7, Zod 4, Auth.js v5 (`next-auth@5` beta). Your training data is older: Next 14, Prisma 5, Tailwind 3 and Zod 3 patterns below are WRONG here.

## Next.js 16
- `middleware.ts` is deprecated: the file is `proxy.ts` in the **project root** (or `src/`), next to `app/` — never inside `app/`. Export `export function proxy(request: NextRequest) {}` plus an optional `export const config = { matcher: "/about/:path*" }`. Nothing to add in next.config. Runs on Node.js only (no edge). Config flags renamed too (`skipProxyUrlNormalize`).
- Request APIs are async. `params` and `searchParams` are Promises; `cookies()`, `headers()`, `draftMode()` must be awaited:
  ```tsx
  export default async function Page({ params }: { params: Promise<{ id: string }> }) {
    const { id } = await params;
  }
  ```
  Same for `generateMetadata`, route handlers (`{ params }: { params: Promise<...> }`), OG images, sitemap `id`.
- Caching: `revalidateTag(tag, 'max')` needs a second argument (cacheLife profile). In Server Actions, `updateTag(tag)` expires + refreshes immediately (read-your-writes). `revalidatePath(path)` still works. `refresh()` refreshes the client router from a Server Action.
- `'use cache'` with `cacheLife()` / `cacheTag()` (needs `cacheComponents: true` in next.config). `experimental.dynamicIO` / `useCache` are removed.
- `next lint` is removed (run ESLint directly, flat config). AMP and runtime config (`publicRuntimeConfig`) are removed. `images.domains` is deprecated: use `images.remotePatterns`.
- Mutations: Server Actions (`'use server'`) + `useActionState` from `react` (not `useFormState` from `react-dom`).

## Tailwind CSS 4
- No `tailwind.config.js` by default; no `@tailwind base/components/utilities`. In `app/globals.css`:
  ```css
  @import "tailwindcss";
  @theme { --color-brand: oklch(0.6 0.2 30); }   /* gives bg-brand, text-brand */
  @custom-variant dark (&:is(.dark *));
  ```
- Plugins: `@plugin "…";`. Extra sources: `@source "…";`.

## Prisma ORM 7
- `schema.prisma` generator: `provider = "prisma-client"` with a required `output` (e.g. `"../lib/generated/prisma"`). NOT `prisma-client-js`.
- Import the client from that output: `import { PrismaClient } from "@/lib/generated/prisma/client";`
- Database URL lives in `prisma.config.ts` (not in `schema.prisma`), and `.env` is not auto-loaded:
  ```ts
  import "dotenv/config";
  import { defineConfig, env } from "prisma/config";
  export default defineConfig({ schema: "prisma/schema.prisma", datasource: { url: env("DATABASE_URL") } });
  ```
- A driver adapter is required at runtime:
  ```ts
  import { PrismaPg } from "@prisma/adapter-pg";
  const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }) });
  ```
  Reuse one client in dev via `globalThis`; keep it server-only (`import "server-only"`).

## Zod 4
- String formats are top-level: `z.email()`, `z.url()`, `z.uuid()`. `z.string().email()` is deprecated.
- `z.infer<typeof Schema>` unchanged; `schema.safeParse(data)` → `{ success, data, error }`.

## Auth.js v5 (next-auth@5)
- `auth.ts`: `export const { handlers, auth, signIn, signOut } = NextAuth({ ... })`.
- Route: `app/api/auth/[...nextauth]/route.ts` → `export const { GET, POST } = handlers;`
- Get the session anywhere on the server with `await auth()` (no `getServerSession`). Env vars use the `AUTH_` prefix: `AUTH_SECRET`, `AUTH_GOOGLE_ID`, `AUTH_GOOGLE_SECRET`.
