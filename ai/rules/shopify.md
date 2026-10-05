<!-- checked-against: @shopify/shopify-app-react-router@3 react-router@7 react@18 prisma@6 @prisma/client@6 -->
# Stack facts: Shopify app (trust these over your training data)

Built from Shopify's **React Router app template** (`@shopify/shopify-app-react-router`, React Router 7, React 18, TypeScript, Prisma 6 + SQLite for sessions). It is NOT Remix: never import from `@remix-run/*`, never use `json()` from Remix — return plain objects.

## Files
- `app/shopify.server.ts`: app config, exports `authenticate`, `apiVersion` (`ApiVersion.July26`).
- `app/routes/app.*.tsx`: embedded admin pages (`app.tsx` is the layout with `<s-app-nav>`).
- `app/routes/webhooks.*.tsx`: webhook handlers. Subscriptions are declared in `shopify.app.toml` under `[webhooks]` (`api_version = "2026-10"`).
- `app/db.server.ts`: Prisma client (`prisma-client-js` here, unlike the Next.js projects).

## Loaders, actions, Admin GraphQL
```ts
import type { LoaderFunctionArgs, ActionFunctionArgs } from "react-router";
import { authenticate } from "../shopify.server";

export const loader = async ({ request }: LoaderFunctionArgs) => {
  const { admin, session } = await authenticate.admin(request);
  const response = await admin.graphql(
    `#graphql
      query Products($first: Int!) { products(first: $first) { nodes { id title } } }`,
    { variables: { first: 5 } },
  );
  const { data } = await response.json();
  return { products: data.products.nodes };
};
```
- Read loader data with `useLoaderData<typeof loader>()`; submit with `useFetcher()` from `react-router`.
- Webhooks: `const { topic, shop, payload } = await authenticate.webhook(request);`
- Use the **Admin GraphQL API** only (REST Admin is legacy). Use `nodes` / `edges { node }`, `first`/`after` pagination, global IDs like `gid://shopify/Product/123`. Mutations return `userErrors { field message }`: always check them.

## UI: Polaris web components (not `@shopify/polaris` React)
- Tags: `<s-page heading="…">`, `<s-section heading="…">`, `<s-stack>`, `<s-box>`, `<s-heading>`, `<s-text>`, `<s-paragraph>`, `<s-button>`, `<s-link>`, `<s-unordered-list>` / `<s-list-item>`, `<s-app-nav>`.
- App Bridge: `const shopify = useAppBridge();` from `@shopify/app-bridge-react`, e.g. `shopify.toast.show("Saved")`.
- Toast after a fetcher save (template pattern): react to the action's returned data in a `useEffect`:
  ```tsx
  const fetcher = useFetcher<typeof action>();
  const shopify = useAppBridge();
  useEffect(() => {
    if (fetcher.data?.product?.id) shopify.toast.show("Product saved");
  }, [fetcher.data?.product?.id, shopify]);
  ```
  Busy state: `["loading", "submitting"].includes(fetcher.state)`.

## Rules
- Do not invent GraphQL fields, scopes or webhook topics. If unsure, say so and point to shopify.dev docs.
- Scopes live in `shopify.app.toml` (`[access_scopes]`); changing them needs `shopify app deploy`.
