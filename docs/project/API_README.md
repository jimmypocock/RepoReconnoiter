# RepoReconnoiter API Documentation

This directory contains the API documentation for RepoReconnoiter, using the OpenAPI 3.0 specification.

## Files

- **`openapi.yml`** - The main API specification (source of truth)
- **`API_README.md`** - This file (how to maintain the docs)

## Quick Links

- [View API Docs (Swagger UI)](https://editor.swagger.io/) - Paste `openapi.yml` content
- [OpenAPI 3.0 Specification](https://spec.openapis.org/oas/v3.0.3)

## Viewing the Documentation

### Option 1: Swagger Editor (Recommended)
1. Copy the contents of `docs/openapi.yml`
2. Go to [https://editor.swagger.io/](https://editor.swagger.io/)
3. Paste the YAML (File → Import File or just paste)
4. You'll see a nice interactive UI with "Try it out" buttons

### Option 2: VS Code Extension
Install the "OpenAPI (Swagger) Editor" extension and open `openapi.yml`

### Option 3: Local Swagger UI (Future)
We can add `rswag` gem later to serve docs at `/api-docs`

## Maintaining the Documentation

### The Golden Rule: **Update docs BEFORE or IMMEDIATELY AFTER building endpoints**

This is NOT optional documentation - this is your API contract that frontend developers (and future you) depend on.

### Workflow for Adding a New Endpoint

1. **Design the endpoint in openapi.yml FIRST**
   ```yaml
   paths:
     /new-endpoint:
       get:
         summary: What it does
         parameters: [...]
         responses: [...]
   ```

2. **Build the Rails endpoint** (controller, serializer, tests)

3. **Test the endpoint** with curl or Postman

4. **Verify the docs match reality**
   - Response structure matches schema?
   - Error cases documented?
   - Examples accurate?

5. **Commit both code AND docs together**

### Example: Adding GET /api/v1/comparisons/:id

Here's what you'd add to `openapi.yml`:

```yaml
paths:
  /comparisons/{id}:
    get:
      summary: Get comparison by ID
      operationId: getComparison
      tags:
        - Comparisons
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
          description: Comparison ID
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    $ref: '#/components/schemas/Comparison'
        '404':
          description: Comparison not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
```

## OpenAPI Structure Explained

The `openapi.yml` file has these main sections:

### 1. **Info** - Metadata about your API
```yaml
info:
  title: RepoReconnoiter API
  version: 1.0.0
  description: What your API does
```

### 2. **Servers** - Where the API is hosted
```yaml
servers:
  - url: https://reporeconnoiter.com/api/v1  # Production
  - url: http://localhost:3000/api/v1        # Development
```

### 3. **Paths** - Your endpoints (THE MEAT)
```yaml
paths:
  /comparisons:              # Endpoint path
    get:                     # HTTP method
      summary: Short description
      parameters: [...]      # Query params, path params
      responses:             # What you return
        '200':
          description: Success
          content:
            application/json:
              schema: {...}
```

### 4. **Components/Schemas** - Reusable data structures
```yaml
components:
  schemas:
    Comparison:            # Define once, reference everywhere
      type: object
      properties:
        id:
          type: integer
        user_query:
          type: string
```

## Frontend Integration

### Generating TypeScript Types

Your Next.js frontend can generate TypeScript types directly from this spec:

```bash
# In your Next.js project
npx openapi-typescript docs/openapi.yml -o src/api/types.ts
```

This creates:
```typescript
// src/api/types.ts (auto-generated)
export interface Comparison {
  id: number;
  user_query: string;
  technologies: string | null;
  // ... matches your OpenAPI schema exactly
}

export interface PaginationMeta {
  pagination: {
    page: number;
    per_page: number;
    // ...
  }
}
```

### Using in React Components

```typescript
import { Comparison } from '@/api/types';

function ComparisonCard({ comparison }: { comparison: Comparison }) {
  // TypeScript knows exactly what fields exist!
  return <div>{comparison.user_query}</div>;
}
```

## Testing Against the Spec

### Manual Testing

```bash
# Test the endpoint
curl http://localhost:3000/api/v1/comparisons?page=1&per_page=5

# Verify response matches schema in openapi.yml
```

### Automated Contract Testing (Active)

We use the `committee` gem to automatically validate responses against the OpenAPI spec in tests:

```ruby
# In API integration tests
test "GET /api/v1/comparisons returns success" do
  get api_v1_comparisons_path, as: :json

  assert_response :success
  assert_schema_conform  # Validates response against openapi.yml
end
```

**How it works:**
- Committee gem loads `docs/openapi.yml` during tests
- `assert_schema_conform` validates HTTP response against the spec
- Tests FAIL if response doesn't match documented schema
- Prevents drift between documentation and implementation

**Configuration:** See `test/test_helper.rb` for Committee setup

## Version Control

**IMPORTANT:** Always commit `openapi.yml` changes with related code changes:

```bash
git add app/controllers/api/v1/comparisons_controller.rb
git add docs/openapi.yml
git commit -m "Add GET /api/v1/comparisons endpoint with pagination"
```

## Breaking Changes

When making breaking changes to the API:

1. **Increment version** in openapi.yml (`version: 2.0.0`)
2. **Create new namespace** (`namespace :v2`)
3. **Document migration path** in `API_CHANGELOG.md` (create this file)
4. **Keep v1 running** until frontend migrates

## Questions?

- OpenAPI syntax: https://learn.openapis.org/
- Best practices: https://github.com/OAI/OpenAPI-Specification/blob/main/examples/v3.0/
- Our pattern: Look at existing endpoints in `openapi.yml`
