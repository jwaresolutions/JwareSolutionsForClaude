# Frontend Assertion Standards

> **Loaded when:** Agent is writing or reviewing frontend tests (React, Next.js, Testing Library).
> Weak DOM assertions are the leading cause of false-positive frontend tests.

---

## Rules

### 1. Use `.toBeInTheDocument()` for DOM Presence
Never use `.toBeTruthy()`, `.toBeDefined()`, or `.not.toBeNull()` to check if an element exists in the DOM. These matchers do not verify DOM presence -- they verify JavaScript truthiness.

```typescript
// REQUIRED
expect(screen.getByRole("button", { name: "Submit" })).toBeInTheDocument();

// PROHIBITED
expect(screen.queryByText("Submit")).toBeTruthy();
expect(screen.queryByRole("button")).toBeDefined();
expect(screen.queryByText("Submit")).not.toBeNull();
```

### 2. Use `.toHaveTextContent()` for Text Verification
Do not check `.textContent` manually or use `.toBeTruthy()` on a query result to verify text. Use the semantic matcher.

```typescript
// REQUIRED
expect(screen.getByTestId("total")).toHaveTextContent("$1,234.56");

// PROHIBITED
expect(screen.getByTestId("total").textContent).toBe("$1,234.56");
expect(screen.queryByText("$1,234.56")).toBeTruthy();
```

### 3. Use `.toHaveAttribute()` for Attribute Checks
Verify attributes with the dedicated matcher, not by accessing the property directly.

```typescript
// REQUIRED
expect(screen.getByRole("link")).toHaveAttribute("href", "/dashboard");

// PROHIBITED
expect(screen.getByRole("link").getAttribute("href")).toBe("/dashboard");
```

### 4. Assert Order and Content, Not Just Count
For sort, filter, and list tests, assert the actual rendered content and order. Element count alone does not prove correctness.

```typescript
// REQUIRED: verifies actual order
const rows = screen.getAllByRole("row");
expect(rows[0]).toHaveTextContent("AAPL");
expect(rows[1]).toHaveTextContent("GOOG");
expect(rows[2]).toHaveTextContent("MSFT");

// PROHIBITED: only verifies count, not order or content
expect(screen.getAllByRole("row")).toHaveLength(3);
```

### 5. Test Props by Behavior, Not Render Structure
Do not test prop-threading by checking that a child component received a prop. Instead, verify the behavior that prop causes.

```typescript
// REQUIRED: verify the behavior the prop controls
render(<PriceDisplay value={1234.56} currency="USD" />);
expect(screen.getByText("$1,234.56")).toBeInTheDocument();

// PROHIBITED: testing implementation detail
const child = wrapper.find(FormattedNumber);
expect(child.prop("value")).toBe(1234.56);
```

### 6. Use Accessible Queries
Prefer queries in this order: `getByRole` > `getByLabelText` > `getByPlaceholderText` > `getByText` > `getByTestId`. Accessible queries verify the component is usable, not just rendered.

```typescript
// PREFERRED: tests accessibility and presence
expect(screen.getByRole("button", { name: "Delete" })).toBeInTheDocument();

// ACCEPTABLE: when role-based query isn't practical
expect(screen.getByTestId("delete-btn")).toBeInTheDocument();
```

### 7. Do Not Test Stubs or Placeholders
If a component is a stub or placeholder awaiting real implementation, do not write unit tests for it. Add a code comment instead.

```typescript
// In the component file:
/** Placeholder -- real implementation in Sprint 3. No tests until then. */
export function AISentimentWidget() {
  return <div>Coming soon</div>;
}
```

---

## Prohibited Patterns

```typescript
// TRUTHINESS CHECK ON QUERY (passes when element is null)
expect(screen.queryByText("Total")).toBeTruthy();

// SNAPSHOT ABUSE (tests nothing specific, breaks on any change)
expect(container).toMatchSnapshot();

// TESTING INTERNAL STATE
expect(component.state.isLoading).toBe(false);

// TESTING CSS CLASSES INSTEAD OF VISUAL BEHAVIOR
expect(element).toHaveClass("active");
// Better: test what "active" means visually
expect(element).toHaveStyle({ backgroundColor: "rgb(0, 123, 255)" });
// Or test the behavior: clicking it navigates, shows content, etc.
```

---

## ESLint Enforcement

Enable these rules in your ESLint config to catch violations automatically:

```json
{
  "plugins": ["jest-dom", "testing-library"],
  "rules": {
    "jest-dom/prefer-in-document": "error",
    "jest-dom/prefer-to-have-text-content": "error",
    "jest-dom/prefer-to-have-attribute": "error",
    "testing-library/prefer-screen-queries": "error",
    "testing-library/no-node-access": "warn"
  }
}
```

---

## Absence Assertions

To verify an element is NOT in the DOM, use `queryBy*` (which returns null) with `.not.toBeInTheDocument()`. Never use `getBy*` for absence checks -- it throws before the assertion runs.

```typescript
// REQUIRED
expect(screen.queryByText("Error")).not.toBeInTheDocument();

// PROHIBITED (throws if element is absent, defeating the purpose)
expect(screen.getByText("Error")).not.toBeInTheDocument();
```
