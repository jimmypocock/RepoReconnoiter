# AI Prompts Library

This directory contains all AI prompt templates for the application. Prompts are managed using the `Prompter` class.

## Creating New Prompts

### System Prompts (for defining AI behavior)

```ruby
Prompter.create('my_ai_task_system', system: true)
```

Creates: `app/prompts/my_ai_task_system.erb` with:
- Role definition template
- Task description
- JSON output format
- Guidelines
- Examples

### Build/User Prompts (for dynamic content)

```ruby
Prompter.create('my_ai_task_build')
```

Creates: `app/prompts/my_ai_task_build.erb` with:
- ERB variable placeholders
- Helper method template
- Context building structure

## Using Prompts

### Rendering Prompts

```ruby
# System prompt (no variables)
system_prompt = Prompter.render('my_ai_task_system')

# Build prompt (with variables)
user_prompt = Prompter.render('my_ai_task_build',
  variable_name: some_value,
  another_variable: other_value
)

# In a service
response = client.chat.completions.create(
  messages: [
    { role: "system", content: Prompter.render('my_ai_task_system') },
    { role: "user", content: Prompter.render('my_ai_task_build', data: data) }
  ],
  model: "gpt-4o-mini"
)
```

### Sanitizing User Input

```ruby
# Always sanitize user-provided text before sending to AI
safe_query = Prompter.sanitize_user_input(params[:user_query])
```

## Prompt Template Structure

Each prompt has a documentation header:

```erb
<%#
PROMPT: template_name
DESCRIPTION: What this prompt does
VARIABLES: @var1, @var2 (or "none" for system prompts)
SECURITY: no_user_input | structured_data | user_input
OUTPUT: What the AI should return
MODEL: gpt-4o-mini | gpt-4o
USED_BY: ServiceName#method_name
-%>
```

### Security Levels

- **no_user_input**: No user-provided data (safest)
- **structured_data**: Only validated data from database/API
- **user_input**: Contains user-provided text (requires sanitization)

## Naming Conventions

- Use `snake_case` for template names
- System prompts: `{feature}_system.erb`
- Build prompts: `{feature}_build.erb`
- Must start with a letter
- No spaces or special characters

## Examples

### Current Prompts

1. **user_query_parser_system.erb**
   - System prompt for parsing user queries into GitHub searches
   - No variables, pure instruction
   - Returns: JSON with tech_stack, problem_domain, github_queries, query_strategy
   - Used by: UserQueryParser#parse

2. **repository_analyzer_system.erb**
   - System prompt for analyzing and categorizing repositories
   - Defines JSON output format for categories
   - Used by: RepositoryAnalyzer#analyze_repository

3. **repository_analyzer_build.erb**
   - Builds user prompt with repository data
   - Variables: @repository, @available_categories
   - Dynamic content based on repo metadata
   - Used by: RepositoryAnalyzer#analyze_repository

## Best Practices

1. **Keep system prompts focused** - One clear task per prompt
2. **Use clear examples** - Show input/output pairs
3. **Define JSON schemas** - Be explicit about output format
4. **Version control** - Commit prompt changes with clear messages
5. **Document variables** - Describe type and purpose in header
6. **Test prompts** - Verify output before deploying
7. **Sanitize inputs** - Always use `Prompter.sanitize_user_input()` for user text

## Future Gem Features

This prompt system is being developed for extraction into a standalone Ruby gem:

- [ ] Prompt versioning
- [ ] A/B testing support
- [ ] Cost tracking per prompt
- [ ] Prompt analytics
- [ ] Multi-language support
- [ ] Prompt validation/linting
- [ ] Integration with multiple AI providers
