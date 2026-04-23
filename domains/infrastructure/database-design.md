# Domain: Database Design & Management
**Loaded when:** Agent is designing schemas, writing migrations, or optimizing queries.
**Key concern:** Migrations. A bad migration on a production table with millions of rows can lock the database for hours.

---

## Schema Design

Normalize to 3NF by default. Denormalize deliberately for measured read performance problems, never accidentally.

| Form | Rule | Violation example |
|---|---|---|
| 1NF | No repeating groups | `tags: "a,b,c"` in a single column |
| 2NF | No partial key dependencies | Non-key depends on part of composite key |
| 3NF | No transitive dependencies | `order.customer_name` when `customer_id` exists |

**Primary keys:** Auto-increment or UUIDv7 (time-ordered, good index locality). Never use business data (email, SKU) as PK.

## Indexing

Index what you query. Put equality conditions first in composite indexes, range conditions last.

```sql
-- Query: WHERE status = 'active' AND created_at > '2024-01-01'
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
```

**Foreign keys must be indexed.** Without it, JOINs and CASCADE deletes do full table scans.

## Migration Rules

1. **Never modify a deployed migration.** Create a new one.
2. **Every migration must be reversible.** Write both `up` and `down`.
3. **Test on representative data.** 50ms on empty table can be 30 min on 10M rows.
4. **One logical change per migration.** Don't combine schema + data backfills.

### Dangerous Operations

| Operation | Risk | Safe alternative |
|---|---|---|
| `ADD COLUMN NOT NULL` | Locks table, rewrites all rows | Add nullable, backfill, then add constraint |
| `CREATE INDEX` | Locks table for writes | `CREATE INDEX CONCURRENTLY` |
| `DROP COLUMN` | Irreversible | Rename first, drop in later migration |
| Large backfill in migration | Long lock | Backfill in batches outside migration |

## Query Performance

Use `EXPLAIN ANALYZE` on every non-trivial query. Look for: `Seq Scan` (missing index), `Nested Loop` with large outer (N+1), `Sort` without index.

### N+1 Detection

```python
# WRONG: 1 query for users + N queries for orders
users = session.query(User).all()
for user in users:
    print(user.orders)  # each access fires a query

# RIGHT: eager load
users = session.query(User).options(joinedload(User.orders)).all()
```

Enable query logging in development. Same query pattern with different IDs = N+1.

## Connection Pooling

Always use a pool. `pool_size` < `max_connections / app_instances`. Postgres default max is 100.

| Setting | Typical | Note |
|---|---|---|
| `pool_size` | 5-20 | Connections kept open |
| `max_overflow` | 10 | Extra under load |
| `pool_recycle` | 1800s | Avoid stale connections |

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| No index on foreign keys | Slow JOINs, slow CASCADE | Index every FK column |
| N+1 queries | 100 parents = 101 queries | Eager loading |
| Modifying deployed migration | Schema drift across environments | Always create new migration |
| Untested large migration | 30-min table lock in production | Test on production-sized copy |
| No connection pool | Connection exhaustion | Always pool |
| Missing transactions | Partial writes on failure | Wrap multi-table writes |
