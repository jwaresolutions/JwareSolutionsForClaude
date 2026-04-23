# Domain: Component Testing
**Loaded when:** Agent is writing or reviewing frontend component tests (Vitest + Testing Library).
**Key concern:** Every component with conditional render branches must have each branch tested. An untested branch is an untested feature.

---

## Testing Pattern: Render, Interact, Assert

```typescript
render(<PositionsTable positions={mockPositions} />);
await userEvent.click(screen.getByRole("button", { name: "Sort" }));
expect(screen.getByText("AAPL")).toBeInTheDocument();
```

## Query Priority

| Priority | Query | When |
|---|---|---|
| 1 | `getByRole` | Buttons, links, headings, inputs |
| 2 | `getByLabelText` | Form inputs with labels |
| 3 | `getByText` | Static text content |
| 4 | `getByTestId` | Last resort only |

## The Four States

Every data-fetching component has four states. All four must be tested:

```typescript
test("shows skeleton while loading", () => {
  render(<Positions loading={true} positions={[]} />);
  expect(screen.getByTestId("loading-skeleton")).toBeInTheDocument();
});

test("shows error message on failure", () => {
  render(<Positions loading={false} error="Network error" positions={[]} />);
  expect(screen.getByText("Network error")).toBeInTheDocument();
});

test("shows empty message when no data", () => {
  render(<Positions loading={false} positions={[]} />);
  expect(screen.getByText("No open positions")).toBeInTheDocument();
});

test("renders data correctly", () => {
  render(<Positions loading={false} positions={mockPositions} />);
  expect(screen.getByText("AAPL")).toBeInTheDocument();
});
```

## Mocking Strategy

Mock at the API boundary, not component internals:

```typescript
// RIGHT: mock the API module
vi.mock("@/lib/api", () => ({
  fetchPositions: vi.fn().mockResolvedValue(mockPositions),
}));

// WRONG: mock internal state
vi.mock("react", () => ({ useState: vi.fn() }));
```

For complex multi-endpoint scenarios, use MSW (Mock Service Worker) to intercept HTTP requests.

## User Events

Use `userEvent` (not `fireEvent`) -- it simulates real user behavior including focus, blur, and keyboard events:

```typescript
const user = userEvent.setup();
await user.type(screen.getByLabelText("Quantity"), "100");
await user.click(screen.getByRole("button", { name: "Submit" }));
```

## Async Assertions

Use `waitFor` when asserting state that updates asynchronously:

```typescript
await waitFor(() => {
  expect(screen.getByText("AAPL")).toBeInTheDocument();
});
```

For absence after async update: `expect(screen.queryByTestId("skeleton")).not.toBeInTheDocument()`.

## Conditional Branches

If a component has an `if`/ternary that changes rendering, both branches need tests:

```typescript
test("green for profit", () => {
  render(<PnL value={100} />);
  expect(screen.getByText("+$100.00")).toHaveClass("text-success-500");
});

test("red for loss", () => {
  render(<PnL value={-50} />);
  expect(screen.getByText("-$50.00")).toHaveClass("text-danger-500");
});
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| Only testing populated state | Loading/error/empty untested | Test all four states |
| `fireEvent` instead of `userEvent` | Misses focus/blur side effects | Use `userEvent.setup()` |
| `.toBeTruthy()` for DOM presence | Passes when element is null | Use `.toBeInTheDocument()` |
| Mocking hooks or internal state | Tests pass when component is broken | Mock at API boundary |
| Missing `waitFor` on async | Flaky tests, false passes | Wrap async assertions in `waitFor` |
| Snapshot tests as primary strategy | Break on any change, test nothing | Use behavioral assertions |
| `getBy*` for absence check | Throws before assertion runs | Use `queryBy*` + `.not.toBeInTheDocument()` |
