# Domain: TypeScript Patterns
**Loaded when:** Agent is writing or reviewing TypeScript code (frontend or backend).
**Key concern:** Strict mode is non-negotiable. No `any`, no non-null assertions without documented justification.

---

## Strict Mode

The project uses `strict: true` in `tsconfig.json`. This enables:

- `strictNullChecks`: `null` and `undefined` are distinct types
- `noImplicitAny`: Every value must have a type
- `strictFunctionTypes`: Function parameter types are checked contravariantly
- `strictPropertyInitialization`: Class properties must be initialized

Do not weaken these settings. Do not use `// @ts-ignore` or `// @ts-expect-error` without a comment explaining why.

## Interfaces vs Types

Use `interface` for contracts that will be extended or implemented. Use `type` for unions, intersections, and computed types that cannot be expressed as interfaces.

## Discriminated Unions for State Machines

Use discriminated unions to model states. The discriminant field (`status`, `type`, `kind`) enables exhaustive checking.

```typescript
type RequestState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: Position[] }
  | { status: "error"; message: string };

function renderState(state: RequestState) {
  switch (state.status) {
    case "idle":
      return null;
    case "loading":
      return <Spinner />;
    case "success":
      return <Table data={state.data} />;
    case "error":
      return <ErrorBanner message={state.message} />;
    // No default -- TypeScript errors if a case is missing
  }
}
```

Add an `assertNever(x: never): never` helper in the `default` branch to catch missing cases at compile time.

## Null Handling

**No blind `!` assertions.** Every non-null assertion must have a comment explaining why the value cannot be null. Prefer explicit null checks (`if (!user) throw`) over `!`.

**Use `??` not `||` for defaults.** `||` treats `0`, `""`, and `false` as falsy. `??` only triggers on `null`/`undefined`. `config.timeout || 30` is a bug when timeout is `0`.

## Function Patterns

**Explicit return types on exports.** Public functions must declare return types to prevent accidental type widening. Use `extends` to constrain generics -- never `any` as a generic parameter.

## Testing Type Behavior

Type assertions in tests should verify that the type matters for behavior, not just that TypeScript compiled.

```typescript
// WRONG: testing that TypeScript works
const order: Order = createOrder();
expect(order).toBeDefined(); // This tests nothing

// RIGHT: testing that the type discriminant drives behavior
const state: RequestState = { status: "error", message: "Network down" };
const { getByText } = render(<StatusDisplay state={state} />);
expect(getByText("Network down")).toBeInTheDocument();
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| `as any` to silence errors | Hides real type bugs | Fix the actual type issue |
| Non-null assertion without comment | Crashes at runtime on null | Add explicit null check or justification |
| `\|\|` for default values | Treats `0`, `""`, `false` as missing | Use `??` for null/undefined only |
| Missing exhaustive switch check | Silent bugs when new variants added | Add `assertNever` in default |
| Implicit return types on exports | Type widening, accidental changes | Add explicit return type annotation |
| `Object` or `{}` as type | Matches almost anything | Use specific interface or `Record<string, unknown>` |
