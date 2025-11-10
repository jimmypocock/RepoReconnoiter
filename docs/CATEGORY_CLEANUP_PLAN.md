# Category Cleanup Plan

**Status**: Updated - Ready for Implementation
**Goal**: Align local and production categories with consistent naming and no overly broad categories

## Summary Statistics

- **Local Categories**: 117 total
- **Production Categories**: 100 total
- **In Both**: ~60
- **Local Only**: ~57
- **Production Only**: ~40

## Key Issues to Fix

1. **Compound Categories** (10+): Categories with "&" should be split into separate categories
2. **Lowercase/Hyphenated** (27): Inconsistent capitalization
3. **Duplicates**: "Rails" vs "Ruby on Rails", etc.
4. **Maturity Categories**: Should be repo attributes, not categories
5. **Production-Only**: Categories that need to be added to seeds

---

## Action Plan by Category

### Legend

- ✅ **KEEP**: Good as-is
- 🔧 **FIX**: Rename/recapitalize
- ➗ **SPLIT**: Break into multiple categories
- 🗑️ **REMOVE**: Delete or merge into another
- ➕ **SEED**: Add to seeds (for both local and production)

---

## TECHNOLOGY Categories

| Category | Local | Prod | Type | Action | Plan |
|----------|-------|------|------|--------|------|
| async | ✓ | | technology | 🔧 | Rename to "Async" |
| Authentication | ✓ | | technology | 🗑️ | **DELETE** Ensure associated models are set properly. |
| aws | ✓ | | technology | 🔧 | Rename to "AWS" |
| aws-lambda | ✓ | | technology | 🔧 | Rename to "AWS Lambda" |
| Blockchain Technology | ✓ | | technology | ✅ | Keep |
| BuckleScript | ✓ | | technology | ✅ | Keep |
| C# | ✓ | ✓ | technology | ✅ | Keep |
| cdk | ✓ | | technology | 🔧 | Rename to "CDK" |
| deep-learning | ✓ | | technology | 🔧 | Rename to "Deep Learning" |
| Django | ✓ | ✓ | technology | ✅ | Keep |
| Docker | ✓ | | technology | ✅ | Keep |
| Dockerfile | ✓ | | technology | 🗑️ | **MERGE** into "Docker" |
| Elixir | ✓ | | technology | ✅ | Keep |
| etl | ✓ | | technology | 🔧 | Rename to "ETL" (also exists in prod) |
| ETL | | ✓ | technology | ➕ | Already fixed in production |
| Go | ✓ | ✓ | technology | ✅ | Keep |
| HTML | ✓ | | technology | ✅ | Keep |
| htmx | | ✓ | technology | ➕ | Add to seeds. Rename to HTMX |
| http | ✓ | | technology | 🔧 | Rename to "HTTP" |
| Java | ✓ | ✓ | technology | ✅ | Keep |
| JavaScript | ✓ | ✓ | technology | ✅ | Keep |
| Jupyter Notebook | ✓ | ✓ | technology | ✅ | Rename to Jupyter |
| Kotlin | ✓ | ✓ | technology | ✅ | Keep |
| Kubernetes | ✓ | ✓ | technology | ✅ | Keep |
| Laravel | ✓ | ✓ | technology | ✅ | Keep |
| microservices | ✓ | | technology | 🗑️ | **DELETE** Ensure associated models are set properly. |
| Node.js | ✓ | ✓ | technology | ✅ | Keep |
| OCaml | ✓ | | technology | ✅ | Keep |
| Open Policy Agent | ✓ | | technology | ✅ | Keep |
| OpenShift | | ✓ | technology | ➕ | Add to seeds |
| optimization | ✓ | | technology | 🔧 | Rename to "Optimization" |
| pdf-generation | ✓ | | technology | 🔧 | Rename to "PDF Generation" |
| PHP | ✓ | ✓ | technology | ✅ | Keep |
| PostgreSQL | ✓ | | technology | ✅ | Keep |
| prawn | ✓ | | technology | 🔧 | Rename to "Prawn" |
| Python | ✓ | ✓ | technology | ✅ | Keep |
| pytorch | ✓ | | technology | 🔧 | Rename to "PyTorch" |
| Rails | ✓ | ✓ | technology | ✅ | Keep |
| React | ✓ | ✓ | technology | ✅ | Keep |
| redis | ✓ | | technology | 🔧 | Rename to "Redis" |
| Redux | | ✓ | technology | ➕ | Add to seeds |
| Ruby | ✓ | ✓ | technology | ✅ | Keep |
| Ruby on Rails | ✓ | | technology | 🗑️ | **MERGE** into "Rails" |
| RubyGems | | ✓ | technology | ➕ | Add to seeds |
| Rust | ✓ | ✓ | technology | ✅ | Keep |
| Scala | ✓ | | technology | ✅ | Keep |
| Scheduler | ✓ | | technology | ✅ | Keep |
| Shell | ✓ | ✓ | technology | ✅ | Keep |
| sidekiq | ✓ | | technology | 🔧 | Rename to "Sidekiq" |
| Smarty | ✓ | | technology | ✅ | Keep |
| Spring | ✓ | ✓ | technology | ✅ | Keep |
| SVG | | ✓ | technology | ➕ | Add to seeds |
| Swift | ✓ | ✓ | technology | ✅ | Keep |
| templ | | ✓ | technology | ➕ | Rename to "Templ" |
| Testing | ✓ | | technology | 🗑️ | **DELETE** Ensure associated models are set properly. |
| tui | | ✓ | technology | ➕ | Add to seeds. Rename to "TUI" |
| TypeScript | ✓ | ✓ | technology | ✅ | Keep |
| Vue.js | ✓ | ✓ | technology | ✅ | Keep |
| wasm | ✓ | | technology | 🔧 | Rename to "WebAssembly" |
| Web | | ✓ | technology | 🗑️ | **DELETE** - too vague |
| websockets | ✓ | | technology | 🔧 | Rename to "WebSockets" |
| zig | ✓ | | technology | 🔧 | Rename to "Zig" |

---

## PROBLEM_DOMAIN Categories

| Category | Local | Prod | Type | Action | Plan |
|----------|-------|------|------|--------|------|
| AI Assistants | | ✓ | problem_domain | ➕ | Add to seeds |
| AI Knowledge Base | | ✓ | problem_domain | ➕ | Add to seeds |
| AI Memory Management | | ✓ | problem_domain | ➕ | Add to seeds |
| API Client Generation | ✓ | ✓ | problem_domain | ✅ | Keep |
| API Integration | ✓ | | problem_domain | ✅ | Keep |
| Artificial Intelligence | ✓ | | problem_domain | ✅ | Keep |
| Asynchronous Programming | | ✓ | problem_domain | ➕ | Add to seeds |
| Astronomy and Astrophysics | ✓ | | problem_domain | ✅ | Keep |
| Authentication | ✓ | | problem_domain | ✅ | Keep |
| Authentication & Identity | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Authentication" + "Identity Management" |
| Automation Tools | ✓ | | problem_domain | ✅ | Keep |
| Backend Applications | ✓ | ✓ | problem_domain | ✅ | Keep |
| Background Job Processing | ✓ | ✓ | problem_domain | ✅ | Keep |
| Cache | ✓ | | problem_domain | 🗑️ | **MERGE** into "Caching" (created from split) |
| Caching & Performance | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Caching" + "Performance" |
| Chart Generation | ✓ | | problem_domain | ✅ | Keep |
| Chatbot Framework | | ✓ | problem_domain | ➕ | Add to seeds |
| Context Awareness | | ✓ | problem_domain | ➕ | Add to seeds |
| Continuous Deployment | ✓ | | problem_domain | ✅ | Keep |
| Cron Job Management | ✓ | | problem_domain | ✅ | Keep |
| Data Sync & Replication | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Data Sync" + "Data Replication" |
| Data Visualization | ✓ | | problem_domain | ✅ | Keep |
| Database Tools | ✓ | ✓ | problem_domain | ✅ | Keep |
| DevOps Tools | ✓ | | problem_domain | ✅ | Keep |
| Email & Notifications | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Email" + "Notifications" |
| File Processing | ✓ | ✓ | problem_domain | ✅ | Keep |
| HTML Manipulation | ✓ | | problem_domain | ✅ | Keep |
| HTTP Client | ✓ | | problem_domain | ✅ | Keep |
| HTTP Session Management | | ✓ | problem_domain | ➕ | Add to seeds |
| Icon Generation | | ✓ | problem_domain | ➕ | Add to seeds |
| icon-font-generation | | ✓ | problem_domain | 🔧 | Rename to "Icon Font Generation" |
| Icons | | ✓ | problem_domain | ✅ | Keep - useful general category |
| Identity and Access Management | | ✓ | problem_domain | ➕ | Add to seeds (or merge with "Identity Management" from split) |
| inverse-problems | ✓ | | problem_domain | 🔧 | Rename to "Inverse Problems" |
| invoice-processing | ✓ | | problem_domain | 🔧 | Rename to "Invoice Processing" |
| JSON Parsing | ✓ | | problem_domain | ✅ | Keep |
| knowledge-graph-management | | ✓ | problem_domain | 🔧 | Rename to "Knowledge Graph Management" |
| linear-operators | ✓ | | problem_domain | 🔧 | Rename to "Linear Operators" |
| Machine Learning | ✓ | | problem_domain | ✅ | Keep |
| Management Accounting | | ✓ | problem_domain | ➕ | Already fixed in production |
| management-accounting | ✓ | | problem_domain | 🔧 | Rename to "Management Accounting" |
| Mathematics | ✓ | | problem_domain | ✅ | Keep |
| Memory Management | ✓ | | problem_domain | ✅ | Keep |
| memory-allocation | ✓ | | problem_domain | 🔧 | Rename to "Memory Allocation" |
| Model Context Protocol | | ✓ | problem_domain | ➕ | Add to seeds |
| Monitoring & Observability | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Monitoring" + "Observability" |
| Multi-Agent System | | ✓ | problem_domain | ➕ | Add to seeds |
| multilinear-algebra | ✓ | | problem_domain | 🔧 | Rename to "Multilinear Algebra" |
| ORM Framework | | ✓ | problem_domain | ➕ | Add to seeds |
| Payment Processing | ✓ | ✓ | problem_domain | ✅ | Keep |
| PDF File Processing | ✓ | | problem_domain | ✅ | Keep |
| profiler-tools | ✓ | | problem_domain | 🔧 | Rename to "Profiler Tools" |
| Rate Limiting & Throttling | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Rate Limiting" + "Throttling" |
| Real-time Communication | ✓ | ✓ | problem_domain | 🔧 | Fix capitalization to "Real-Time Communication" |
| Registry Service | | ✓ | problem_domain | ➕ | Add to seeds |
| Retrieval-Augmented Generation | | ✓ | problem_domain | ➕ | Add to seeds |
| Reverse Proxy | | ✓ | problem_domain | ➕ | Add to seeds |
| Search & Indexing | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Search" + "Indexing" |
| Security & Encryption | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Security" + "Encryption" |
| Serverless Applications | ✓ | | problem_domain | ✅ | Keep |
| session-management | | ✓ | problem_domain | 🔧 | Rename to "Session Management" |
| Shell History Management | | ✓ | problem_domain | ➕ | Add to seeds |
| Shell Scripting | | ✓ | problem_domain | ➕ | Add to seeds |
| slab-allocator | ✓ | | problem_domain | 🔧 | Rename to "Slab Allocator" |
| SVG Icon Generation | | ✓ | problem_domain | ➕ | Add to seeds |
| Testing & Mocking | ✓ | ✓ | problem_domain | ➗ | **SPLIT** into "Testing" + "Mocking" |
| Tree Structure Management | | ✓ | problem_domain | ➕ | Add to seeds |
| Vector Search | | ✓ | problem_domain | ➕ | Add to seeds |
| Zero Trust Security | | ✓ | problem_domain | ➕ | Add to seeds |

---

## ARCHITECTURE_PATTERN Categories

| Category | Local | Prod | Type | Action | Plan |
|----------|-------|------|------|--------|------|
| API-First Design | ✓ | ✓ | architecture_pattern | ✅ | Keep |
| CLI & Developer Tools | ✓ | ✓ | architecture_pattern | ➗ | **SPLIT** into "CLI Tools" + "Developer Tools" |
| command-line-tools | ✓ | | architecture_pattern | 🗑️ | **DELETE** - merge into "CLI Tools" from split |
| Data Processing Framework | | ✓ | architecture_pattern | ➕ | Add to seeds |
| data-processing-framework | ✓ | | architecture_pattern | 🔧 | Rename to "Data Processing" |
| Event-Driven Architecture | ✓ | ✓ | architecture_pattern | ✅ | Keep |
| File Processing Framework | ✓ | | architecture_pattern | 🗑️ | **MERGE** into "Data Processing" |
| Frontend Frameworks | ✓ | ✓ | architecture_pattern | ✅ | Keep - useful general category |
| High-Performance Web Framework | | ✓ | architecture_pattern | ➕ | Add to seeds - keep for edge cases |
| HTTP Routing Framework | | ✓ | architecture_pattern | ➕ | Add to seeds - keep for edge cases |
| layered-architecture | | ✓ | architecture_pattern | 🔧 | Rename to "Layered Architecture" |
| Material Design Integration | | ✓ | architecture_pattern | ➕ | Add to seeds |
| Microservices Architecture | ✓ | | architecture_pattern | ✅ | Keep |
| Microservices Tooling | ✓ | ✓ | architecture_pattern | ✅ | Keep |
| Monolith Utilities | ✓ | ✓ | architecture_pattern | ✅ | Keep - useful edge case |
| Multithreaded Architecture | ✓ | | architecture_pattern | ✅ | Keep |
| onion-architecture | | ✓ | architecture_pattern | 🔧 | Rename to "Onion Architecture" |
| Rails Wrapper | | ✓ | architecture_pattern | ➕ | Add to seeds - keep for edge cases |
| Ruby on Rails Wrapper | | ✓ | architecture_pattern | ➕ | Add to seeds - keep for edge cases |
| Scientific Computing | ✓ | | architecture_pattern | ✅ | Keep |
| Serverless Architecture | ✓ | | architecture_pattern | ✅ | Keep |
| Serverless-Friendly | ✓ | ✓ | architecture_pattern | 🗑️ | **MERGE** into "Serverless Architecture" |
| State Management | ✓ | ✓ | architecture_pattern | ✅ | Keep |
| Web Development | ✓ | | architecture_pattern | 🗑️ | **DELETE** - too vague |

---

## MATURITY Categories

**⚠️ DECISION: Maturity should be REPO ATTRIBUTES, not categories**

These should be removed as categories and migrated to Repository model attributes:
- `last_commit_at` (from GitHub API)
- `archived` (boolean from GitHub API)
- `archived_at` (if available from GitHub API)

This allows better filtering and doesn't pollute the category system with time-based metadata.

| Category | Local | Prod | Type | Action | Plan |
|----------|-------|------|------|--------|------|
| Abandoned | ✓ | ✓ | maturity | 🗑️ | **REMOVE** - migrate to repo.archived attribute |
| Active Development | ✓ | ✓ | maturity | 🗑️ | **REMOVE** - derive from repo.last_commit_at |
| Enterprise Grade | ✓ | ✓ | maturity | 🗑️ | **REMOVE** - migrate to repo attribute or badge |
| Experimental | ✓ | ✓ | maturity | 🗑️ | **REMOVE** - derive from repo.last_commit_at + stars |
| Production Ready | ✓ | ✓ | maturity | 🗑️ | **REMOVE** - derive from repo stars/activity |

---

## Summary of Actions

### SPLIT (10 categories → 20 categories)

1. "Caching & Performance" → "Caching" + "Performance"
2. "Testing & Mocking" → "Testing" + "Mocking"
3. "CLI & Developer Tools" → "CLI Tools" + "Developer Tools"
4. "Authentication & Identity" → "Authentication" (exists) + "Identity Management"
5. "Data Sync & Replication" → "Data Sync" + "Data Replication"
6. "Rate Limiting & Throttling" → "Rate Limiting" + "Throttling"
7. "Monitoring & Observability" → "Monitoring" + "Observability"
8. "Security & Encryption" → "Security" + "Encryption"
9. "Email & Notifications" → "Email" + "Notifications"
10. "Search & Indexing" → "Search" + "Indexing"

### FIX CAPITALIZATION (27 categories)

All lowercase/hyphenated categories → Proper Case

### MERGE/REMOVE (10+ categories)

- "Ruby on Rails" → "Rails"
- "Dockerfile" → "Docker"
- "Serverless-Friendly" → "Serverless Architecture"
- "Cache" → "Caching" (from split)
- Misclassified categories (Authentication/Testing as technology)
- "Web" - too vague, delete
- "Web Development" - too vague, delete
- "File Processing Framework" → "Data Processing"
- **ALL Maturity categories** - migrate to repo attributes

### ADD TO SEEDS (~40 categories)

All production-only categories should be added to seeds for both local and production sync

### DECISIONS FINALIZED ✅

- ✅ "Icons" - Keep (useful general category)
- ✅ "Frontend Frameworks" - Keep (useful general category)
- ✅ "Rails Wrapper", "Ruby on Rails Wrapper" - Keep (useful edge cases)
- ✅ "Monolith Utilities" - Keep (useful edge case)
- ✅ "High-Performance Web Framework", "HTTP Routing Framework" - Keep (useful edge cases)
- ✅ Maturity → Repo attributes (last_commit_at, archived, etc.)

---

## Next Steps

1. ✅ **Review document** - All decisions finalized
2. **Update cleanup rake task** - Implement the approved plan (splits, renames, merges, deletions)
3. **Run cleanup on local** - Execute cleanup task and verify results
4. **Dump seeds** - Create `db/seeds/categories.rb` with clean category list
5. **Test cleanup** - Run 50-scenario test again to verify improvements
6. **Deploy to production** - Run seeds in production to sync environments
7. **Future: Remove maturity category_type** - Migrate to repo attributes in separate PR

---

**Last Updated**: 2025-01-09 (Updated after user review)
**Status**: ✅ Ready for Implementation
