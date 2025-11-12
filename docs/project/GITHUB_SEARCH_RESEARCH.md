# GitHub Search API Research

**Goal**: Understand GitHub repository search patterns to inform our QueryParserService AI prompt.

**Date Started**: 2025-10-31

---

## Available Search Qualifiers

Based on [GitHub Search Syntax Documentation](https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories):

### Repository Metadata

- `language:LANGUAGE` - Filter by programming language
- `stars:N` or `stars:>N` or `stars:N..M` - Filter by star count
- `forks:N` or `forks:>N` - Filter by fork count
- `size:N` - Filter by repository size in KB
- `created:YYYY-MM-DD` or `created:>YYYY-MM-DD` - Filter by creation date
- `pushed:YYYY-MM-DD` or `pushed:>YYYY-MM-DD` - Filter by last push date
- `topic:TOPIC` - Filter by topic tags
- `topics:N` - Filter by number of topics
- `license:LICENSE` - Filter by license type
- `is:public` or `is:private` - Filter by visibility
- `archived:true` or `archived:false` - Filter archived repos
- `user:USERNAME` or `org:ORGNAME` - Filter by owner

### Content Qualifiers

- `in:name` - Search in repository name only
- `in:description` - Search in description only
- `in:readme` - Search in README content
- `in:name,description` - Search in multiple fields (default if not specified)

### Keywords

- Plain text keywords search across name, description, and README by default
- Use quotes for exact phrases: `"exact phrase"`

---

## Testing Methodology

For each test:

1. Run query via `bin/rails 'github:search[query]'`
2. Document total results count
3. Document top 5 results (are they relevant?)
4. Document what worked / what didn't
5. Note patterns for AI parser

---

## Test Results

### Test 1: Basic Language + Stars Filter ✅

**Query**: `background processing language:ruby stars:>100`

**Results**: 14 total repositories

**Top 5**:

1. sidekiq/sidekiq (⭐ 13,439) - Perfect match!
2. lardawge/carrierwave_backgrounder (⭐ 734)
3. jondot/sneakers (⭐ 2,251)
4. resque/resque (⭐ 9,472) - Perfect match!
5. bkeepers/qu (⭐ 507)

**Findings**:

- ✅ Simple keyword "background processing" works great
- ✅ `language:ruby` properly filters to Ruby-only repos
- ✅ `stars:>100` filters out small/experimental repos
- ✅ GitHub's relevance ranking is excellent - Sidekiq #1, Resque #4
- 📝 Note: "processing" is broader than "job" - captures more results

**Pattern for AI**: Use broad, generic problem terms + language filter + star threshold

---

### Test 2: JavaScript/TypeScript State Management ✅

**Query**: `state management language:typescript stars:>10000`

**Results**: 8 total repositories

**Top 5**:
1. mobxjs/mobx (⭐ 28,077)
2. reduxjs/redux (⭐ 61,365) 🎯
3. pmndrs/jotai (⭐ 20,676)
4. pmndrs/zustand (⭐ 55,447) 🎯
5. statelyai/xstate (⭐ 28,863)

**Also includes**: react-hook-form (44k), TanStack Query (47k)

**Findings**:
- ✅ **CRITICAL**: Modern frontend libraries are TypeScript, not JavaScript!
- ✅ Removing "react" keyword got us Redux (framework-agnostic lib)
- ✅ High star threshold (10k+) perfect for very popular ecosystems
- ✅ All major state management libs in results (Redux, Zustand, MobX, Jotai, XState)

**Pattern for AI**: For frontend state management → use `language:typescript`, NOT framework name, high stars (10k+)

---

## Golden Queries (Target: 15+)

**Standard Pattern**: All queries use `stars:>100` for consistency

1. ✅ **Rails Background Jobs**: `background processing language:ruby stars:>100`
   - Returns: Sidekiq, Resque, Sneakers, GoodJob
   - Why it works: "processing" broader than "jobs", language filter for Ruby

2. ✅ **JavaScript/TypeScript State Management**: `state management language:typescript stars:>100`
   - Returns: Redux, Zustand, MobX, Jotai, XState, TanStack Query
   - Why it works: TypeScript not JavaScript, no framework name

3. ✅ **Django Authentication**: `django authentication language:python stars:>100`
   - Returns: django-allauth, djangorestframework-simplejwt, djoser, django-two-factor-auth
   - Why it works: Including "django" filters out noise, gets framework-specific auth libs

4. ✅ **Node.js Server Frameworks**: `nodejs server framework stars:>100`
   - Returns: Express, NestJS, Socket.io, Actionhero
   - Why it works: "server" keyword filters blogs/tutorials, gets backend frameworks

5. ✅ **TypeScript ORMs**: `orm database language:typescript stars:>100`
   - Returns: TypeORM (35k), Prisma (44k), MikroORM (8k)
   - Why it works: "orm database" captures all ORM libraries

6. ✅ **Python ORMs (Multi-query)**:
   - Query A: `orm language:python stars:>100` → Peewee (11k), Tortoise-ORM (5k)
   - Query B: `sqlalchemy python stars:>100` → SQLAlchemy (11k), Flask-SQLAlchemy (4k)
   - Why multi-query: SQLAlchemy markets as "toolkit" not "ORM"

7. ✅ **JavaScript/TypeScript Testing (Multi-query)**:
   - Query A: `testing framework language:javascript stars:>1000` → Mocha (22k), Jasmine (15k), Chai (8k)
   - Query B: `jest testing javascript stars:>1000` → Jest (45k), Enzyme (19k)
   - Query C: `testing framework language:typescript stars:>100` → Vitest (15k), Playwright (78k)
   - Why multi-query: Jest is TypeScript, classic frameworks are JavaScript

8. ✅ **Container Orchestration (Multi-query)**:
   - Query A: `docker container orchestration stars:>1000` → Docker Compose (36k), Rancher (24k)
   - Query B: `kubernetes language:go stars:>10000` → Kubernetes (118k), Helm (28k), k3s (31k)
   - Why multi-query: Docker ecosystem vs Kubernetes ecosystem

9. ✅ **GraphQL Servers**: `graphql server language:typescript stars:>100`
   - Returns: Apollo Server (13k), GraphQL Yoga (8k), express-graphql (6k)
   - Why it works: "graphql server" captures server implementations

10. ✅ **HTTP Clients (Multi-query)**:
    - Query A: `axios http client stars:>1000` → Axios (108k, JavaScript)
    - Query B: `http client language:typescript stars:>1000` → ky (15k), Yaak (14k)
    - Why multi-query: Axios is JavaScript, modern clients are TypeScript

11. ✅ **Message Queues**: `message queue language:go stars:>1000`
    - Returns: NSQ (25k), Machinery (7k), rmq (1.6k)
    - Why it works: Go is popular for infrastructure tools

12. ✅ **React UI Components**: `react components library language:typescript stars:>1000`
    - Returns: Material-UI (96k), Mantine (29k), HeroUI (27k), Recharts (26k)
    - Why it works: "react components library" very specific

13. ✅ **Python Web Frameworks (Multi-query)**:
    - Query A: `python web framework stars:>5000` → Django (85k), Flask (70k), Scrapy (58k)
    - Query B: `fastapi python stars:>5000` → FastAPI (91k)
    - Why multi-query: FastAPI needs specific search

14. ✅ **TypeScript Validation (Multi-query)**:
    - Query A: `zod validation typescript stars:>1000` → Zod (40k)
    - Query B: `validation library language:typescript stars:>1000` → Valibot (8k)
    - Why multi-query: Zod so popular it needs own query

15. ✅ **Node.js Logging**: `logger nodejs language:javascript stars:>1000`
    - Returns: Pino (16k), Signale (9k), Morgan (8k)
    - Why it works: "logger nodejs" specific enough

16. ✅ **Date/Time Libraries**: `date time library language:typescript stars:>1000`
    - Returns: date-fns (36k), timeago.js (5k)
    - Why it works: "date time library" clear intent

---

## Qualifiers Deep Dive

### `language:` Qualifier

**Tests to run**:

- [ ] Does `language:ruby` work for Rails?
- [ ] Does `language:javascript` capture both frontend and backend?
- [ ] Does `language:typescript` work independently?
- [ ] What about framework-specific searches (React, Vue)?

**Findings**:

- [To be documented]

---

### `stars:` Qualifier

**Tests to run**:

- [ ] What's a good minimum for quality repos? (100, 500, 1000?)
- [ ] Does it vary by ecosystem? (React vs Ruby)
- [ ] Test `stars:>100` vs `stars:>500` vs `stars:>1000`

**Findings**:

- [To be documented]

---

### `in:` Qualifier (name, description, readme)

**Tests to run**:

- [ ] Does `in:name` improve precision but reduce recall?
- [ ] Is `in:description` better than default?
- [ ] Does `in:readme` slow down searches?
- [ ] What's the default behavior if not specified?

**Findings**:

- [To be documented]

---

### `topic:` Qualifier

**Tests to run**:

- [ ] How well-tagged are repos? Is this reliable?
- [ ] Does `topic:background-jobs` work better than keyword search?
- [ ] Can we combine topic + language?

**Findings**:

- [To be documented]

---

### `pushed:` and `created:` Date Qualifiers

**Tests to run**:

- [ ] Does `pushed:>2024-01-01` filter abandoned repos?
- [ ] What's a good "active project" threshold?
- [ ] Should we prefer `pushed` over `created`?

**Findings**:

- [To be documented]

---

### `archived:false` Qualifier

**Tests to run**:

- [ ] How many archived repos appear without this filter?
- [ ] Should this be default in all queries?

**Findings**:

- [To be documented]

---

## Common Use Cases to Test

### Backend Frameworks

- [ ] Rails background jobs
- [ ] Python authentication
- [ ] Node.js API frameworks
- [ ] Django REST frameworks

### Frontend Frameworks

- [ ] React state management
- [ ] Vue.js routing
- [ ] Angular forms
- [ ] Svelte components

### Infrastructure

- [ ] Docker orchestration
- [ ] Kubernetes tools
- [ ] CI/CD pipelines
- [ ] Monitoring/observability

### Data & ML

- [ ] Python data visualization
- [ ] Machine learning frameworks
- [ ] Database ORMs
- [ ] ETL tools

---

## Critical Findings

### ⚠️ Star Threshold Problem

**Issue**: Star counts vary WILDLY across ecosystems, making programmatic threshold selection difficult.

**Evidence**:
- Ruby ecosystem: `stars:>100` works (Sidekiq has 13k)
- TypeScript frontend: `stars:>10000` needed (Redux 61k, Zustand 55k)
- Python/Django: `stars:>1000` works (django-allauth 10k)
- Node.js: `stars:>15000` works but misses Fastify (34k)

**Problem**: How does AI know to use 100 for Ruby but 10,000 for TypeScript?

**Potential Solutions**:
1. ❓ Use other qualifiers more: `pushed:`, `archived:false`, `topics:`
2. ❓ Make AI ecosystem-aware (JavaScript = high stars, Ruby = lower stars)
3. ❓ Use relative thresholds based on search result distribution
4. ❓ Don't filter by stars at all - trust GitHub's relevance ranking
5. ❓ Use different thresholds for different problem domains

**Action**: Test queries WITHOUT stars filter to see if relevance ranking alone works

### ✅ TESTED: Stars Filter May Not Be Needed!

**Test Results** (WITHOUT star filters):

1. `background processing language:ruby` - ✅ **Perfect!**
   - Sidekiq #1, Resque #4, Sneakers #3 - same top results as with `stars:>100`

2. `state management language:typescript` - ✅ **Perfect!**
   - Redux #2, Zustand #4, MobX #1, Jotai #3 - same as with `stars:>10000`

3. `nodejs web framework` - ⚠️ **Some noise but major ones present**
   - Express #1, Fastify #5 - Found Fastify without star filter!
   - Has some low-star noise (gluon 3k, asset-rack 324 stars)

**Conclusion**: GitHub's relevance ranking is VERY good. Stars filter helps reduce noise for broad searches, but may not be strictly necessary. Consider making it optional or using lower thresholds universally (e.g., `stars:>100` for all queries just to filter obvious junk)

### ✅ VERIFIED: Use `stars:>100` Universally!

**Tested all 4 golden queries with `stars:>100`:**

1. `background processing language:ruby stars:>100` - ✅ Perfect (Sidekiq, Resque, Sneakers)
2. `state management language:typescript stars:>100` - ✅ Perfect (Redux, Zustand, MobX, Jotai)
3. `django authentication language:python stars:>100` - ✅ Perfect (django-allauth, simplejwt, djoser)
4. `nodejs server framework stars:>100` - ✅ Great (Express, NestJS, Socket.io + some noise)

**Decision**: Use `stars:>100` for ALL queries. Simpler, more predictable, and works across all ecosystems.

### 🎯 Multi-Query Strategy: Layers of Intelligence

**Key Insight**: Some searches need MULTIPLE queries to get comprehensive results, then combine/deduplicate.

**Why?**
- Different libraries use different terminology (SQLAlchemy = "database toolkit", not "ORM")
- Ecosystems split across languages (Express = JS, NestJS = TS)
- Established vs emerging tools have different naming patterns

**Example - Python Database Access**:
```
Query 1: "orm language:python stars:>100"
  → Gets: Peewee (11k), Tortoise-ORM (5k), GINO (2k)

Query 2: "sqlalchemy python stars:>100"
  → Gets: SQLAlchemy (11k), Flask-SQLAlchemy (4k), Alembic (3k)

Combined Result: All major Python database libraries
```

**Example - Node.js Frameworks**:
```
Query 1: "nodejs server framework language:javascript stars:>100"
  → Gets: Express (68k), Fastify (34k)

Query 2: "nodejs server framework language:typescript stars:>100"
  → Gets: NestJS (73k), AdonisJS (18k)

Combined Result: Both JS and TS frameworks
```

**Implementation**: Run 2-3 targeted queries, merge results, deduplicate by repo name, re-rank by relevance.

---

## Patterns That Work

### ✅ Good Patterns

1. Broad problem keywords ("processing" not "background job processing")
2. Language filter instead of framework name for backend (Rails → `language:ruby`)
3. Star threshold filters noise (but inconsistent across ecosystems - see above)
4. Modern frontend = TypeScript not JavaScript
5. Framework name works for framework-specific features (django, nestjs)

### ❌ Bad Patterns

1. Using `language:javascript` for modern frontend libraries (they're TypeScript)
2. Too specific keywords reduce recall
3. Including framework name for backend libs (Rails, Django) - use language instead

---

## Summary of Key Findings

### ✅ Completed: 16 Golden Queries Documented

**Major Discoveries:**

1. **Use `stars:>100` universally** - Works across all ecosystems, simpler than varying thresholds
2. **Multi-query strategy is essential** - Many use cases need 2-3 queries to get comprehensive results
3. **Modern frontend = TypeScript** - React libraries, ORMs, validation all TypeScript now
4. **Language filters critical** - `language:ruby`, `language:typescript`, `language:python` essential
5. **Broad keywords work best** - "processing" not "background job processing"
6. **Framework name matters for specificity** - Include "django", "nestjs", "react" for framework-specific libs

**Query Patterns:**
- Backend libs: Use language filter, NOT framework name (Rails → `language:ruby`)
- Frontend libs: Use TypeScript, MAY include framework name (React components)
- Multi-query: Needed when ecosystem splits (JS vs TS, Docker vs K8s)
- Stars: `stars:>100` universal baseline, occasionally `stars:>1000` or `stars:>5000` for very popular ecosystems

**For AI Prompt:**
- Generate 1-3 queries per user request
- Always use `stars:>100` as baseline
- Consider JS vs TS split for frontend
- Know when to use framework names (Django yes, Rails no)
- Understand multi-query scenarios

---

## Next Steps

1. ✅ Complete 15+ common use cases
2. ✅ Document patterns for AI parser prompt
3. Update QueryParserService prompt with findings
4. Create validation tests for query parser
5. Build multi-query execution logic

---

## Notes & Observations

- GitHub's default relevance ranking is quite good
- Simpler queries often work better than complex ones
- Different libraries use different terminology (need broad keywords)
- Multi-query approach solves many edge cases elegantly
