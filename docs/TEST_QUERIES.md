# Test Queries for Data Loading

This document contains curated search queries for testing and populating the RepoReconnoiter database with diverse comparisons across different domains, languages, and complexity levels.

## Purpose

These queries are designed to:

- Test the multi-query GitHub search strategy
- Validate AI categorization across different domains
- Populate the database with real-world comparison examples
- Demonstrate the breadth of the platform's capabilities

## Usage

Run queries individually using the Rails task:

```bash
bin/rails comparisons:create QUERY="your query here"
```

Or run all queries in sequence:

```bash
# Copy and paste this entire block into your terminal
bin/rails comparisons:create QUERY="Go state management library for web applications"
bin/rails comparisons:create QUERY="Elixir background job processing with retry logic"
bin/rails comparisons:create QUERY="Rust async HTTP client for REST APIs"
bin/rails comparisons:create QUERY="Zig memory allocator for embedded systems"
bin/rails comparisons:create QUERY="OCaml JSON parsing library"
bin/rails comparisons:create QUERY="Python data validation library with type hints"
bin/rails comparisons:create QUERY="JavaScript date manipulation library without moment.js"
bin/rails comparisons:create QUERY="Ruby PDF generation library for invoices"
bin/rails comparisons:create QUERY="TypeScript form validation for React"
bin/rails comparisons:create QUERY="PHP rate limiting middleware for APIs"
bin/rails comparisons:create QUERY="Python library for training transformer models"
bin/rails comparisons:create QUERY="Rust tensor computation library for machine learning"
bin/rails comparisons:create QUERY="Python astrophysics simulation toolkit"
bin/rails comparisons:create QUERY="Julia library for numerical computation in physics"
bin/rails comparisons:create QUERY="Python computer vision library for object detection"
bin/rails comparisons:create QUERY="Rust game engine for 2D platformers"
bin/rails comparisons:create QUERY="C++ physics engine for realistic simulations"
bin/rails comparisons:create QUERY="JavaScript WebGL library for 3D graphics"
bin/rails comparisons:create QUERY="Python procedural generation library for game worlds"
bin/rails comparisons:create QUERY="Go headless browser for automated testing"
bin/rails comparisons:create QUERY="React Server Components framework for Next.js alternatives"
bin/rails comparisons:create QUERY="Vue 3 component library with Tailwind CSS"
bin/rails comparisons:create QUERY="Swift networking layer for iOS apps"
bin/rails comparisons:create QUERY="Kotlin coroutines library for Android background tasks"
bin/rails comparisons:create QUERY="Svelte state management without Redux"
bin/rails comparisons:create QUERY="Python ETL library for data pipelines"
bin/rails comparisons:create QUERY="Go Kubernetes operator framework"
bin/rails comparisons:create QUERY="Rust CLI argument parser with auto-completion"
bin/rails comparisons:create QUERY="Python time series database for IoT data"
bin/rails comparisons:create QUERY="JavaScript WebSocket library for real-time chat"
```

## Query Categories

### Basic/Infrastructure (Obscure Languages)

1. "Go state management library for web applications"
2. "Elixir background job processing with retry logic"
3. "Rust async HTTP client for REST APIs"
4. "Zig memory allocator for embedded systems"
5. "OCaml JSON parsing library"

### Mid-Level (Popular Languages, Common Problems)

6. "Python data validation library with type hints"
7. "JavaScript date manipulation library without moment.js"
8. "Ruby PDF generation library for invoices"
9. "TypeScript form validation for React"
10. "PHP rate limiting middleware for APIs"

### Exciting/Scientific (AI, Data Science, Physics)

11. "Python library for training transformer models"
12. "Rust tensor computation library for machine learning"
13. "Python astrophysics simulation toolkit"
14. "Julia library for numerical computation in physics"
15. "Python computer vision library for object detection"

### Game Dev & Graphics

16. "Rust game engine for 2D platformers"
17. "C++ physics engine for realistic simulations"
18. "JavaScript WebGL library for 3D graphics"
19. "Python procedural generation library for game worlds"
20. "Go headless browser for automated testing"

### Web/Mobile Development

21. "React Server Components framework for Next.js alternatives"
22. "Vue 3 component library with Tailwind CSS"
23. "Swift networking layer for iOS apps"
24. "Kotlin coroutines library for Android background tasks"
25. "Svelte state management without Redux"

### Data/DevOps/Infrastructure

26. "Python ETL library for data pipelines"
27. "Go Kubernetes operator framework"
28. "Rust CLI argument parser with auto-completion"
29. "Python time series database for IoT data"
30. "JavaScript WebSocket library for real-time chat"

## Expected Coverage

These queries should test:

- **Languages**: Go, Elixir, Rust, Zig, OCaml, Python, JavaScript, Ruby, TypeScript, PHP, Julia, C++, Swift, Kotlin, Svelte
- **Domains**: Web frameworks, background jobs, HTTP clients, memory management, parsing, validation, dates, PDFs, forms, rate limiting, ML/AI, astrophysics, physics, computer vision, game engines, graphics, mobile, state management, ETL, Kubernetes, CLI tools, time series, WebSockets
- **Complexity**: From simple utility libraries to complex frameworks
- **Popularity**: Mix of mainstream and niche technologies

## Notes

- Each query costs approximately $0.05 in OpenAI API costs
- Total cost for all 30 queries: ~$1.50
- Queries are designed to return 5-15 repositories each
- Multi-query strategy will be tested on several of these
- Expect some queries to have cached results if run multiple times
