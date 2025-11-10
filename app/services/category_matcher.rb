# CategoryMatcher - Finds or creates categories with fuzzy matching and normalization
#
# Three-layer matching strategy:
#   Layer 1: Exact alias mapping (instant, free)
#   Layer 2: Fuzzy trigram matching via pg_trgm (instant, free)
#   Layer 3: Semantic embeddings via OpenAI (2ms, ~$0.000002 per comparison)
#
# Usage:
#   matcher = CategoryMatcher.new
#   category = matcher.find_or_create(name: "background jobs", category_type: "problem_domain")
#   # Returns existing "Background Job Processing" if similar enough
#   # Creates new "Background Jobs" if no match found
class CategoryMatcher
  # Similarity thresholds
  TRIGRAM_THRESHOLD = 0.55  # pg_trgm SIMILARITY threshold (character-level - lowered to catch common typos)
  EMBEDDING_THRESHOLD = 0.75  # Cosine similarity threshold (semantic - lowered to catch "Auth" = 0.792)

  #--------------------------------------
  # PUBLIC INSTANCE METHODS
  #--------------------------------------

  # Find existing category by fuzzy matching, or create new one if no match
  # Uses three-layer matching: aliases → trigrams → embeddings
  # Returns: Category record (existing or newly created)
  def find_or_create(name:, category_type:)
    # Layer 1: Normalize name (handles aliases like "Ruby on Rails" → "Rails")
    normalized_name = normalize_name(name, category_type)

    # Layer 2 & 3: Try to find similar existing category (trigram + embedding)
    existing = find_similar(normalized_name, category_type)
    return existing if existing

    # Create new category with embedding if no match found
    category = Category.create!(
      name: normalized_name,
      category_type: category_type,
      slug: normalized_name.parameterize,
      description: default_description(normalized_name, category_type)
    )

    # Generate embedding for new category
    category.update!(embedding: generate_embedding(normalized_name))

    category
  end

  # Find similar category using two-layer approach:
  #   Layer 2: Trigram similarity (pg_trgm)
  #   Layer 3: Semantic embeddings (OpenAI)
  # Returns: Category or nil
  def find_similar(name, category_type)
    # Layer 2: Try trigram similarity first (instant, free)
    trigram_match = Category
      .where(category_type: category_type)
      .select(
        "categories.*",
        ActiveRecord::Base.sanitize_sql_array([ "SIMILARITY(name, ?) AS similarity_score", name ])
      )
      .where("SIMILARITY(name, ?) > ?", name, TRIGRAM_THRESHOLD)
      .order("similarity_score DESC")
      .first

    return trigram_match if trigram_match

    # Layer 3: Try embedding similarity (2ms, ~$0.000002)
    find_by_embedding(name, category_type)
  end

  # Normalize category name based on type
  # Returns: String
  def normalize_name(name, category_type)
    return name if name.blank?

    case category_type
    when "technology"
      normalize_technology_name(name)
    when "problem_domain"
      normalize_problem_domain_name(name)
    when "architecture_pattern"
      titleize_preserving_hyphens(name)
    else
      titleize_preserving_hyphens(name)
    end
  end

  private

  #--------------------------------------
  # PRIVATE METHODS
  #--------------------------------------

  def default_description(name, category_type)
    case category_type
    when "technology"
      "#{name} programming language and tools"
    when "problem_domain"
      "Tools and libraries for #{name.downcase}"
    when "architecture_pattern"
      "#{name} architectural pattern and related tools"
    when "maturity"
      "#{name} projects"
    else
      "Auto-generated category"
    end
  end

  # Normalize problem domain names (handle common abbreviations)
  def normalize_problem_domain_name(name)
    normalized = name.strip.downcase

    # Common abbreviations in problem domains
    abbreviation_map = {
      "auth" => "Authentication",
      "ml" => "Machine Learning",
      "ai" => "Artificial Intelligence",
      "ci/cd" => "CI/CD",
      "cicd" => "CI/CD",
      "cache" => "Caching",
      "payment process" => "Payment Processing",
      "payment processing" => "Payment Processing"
    }

    abbreviation_map[normalized] || titleize_preserving_hyphens(name)
  end

  # Titleize while preserving hyphens and common acronyms
  # (e.g., "event-driven" → "Event-Driven", "API integration" → "API Integration")
  # (e.g., "cli tools" → "CLI Tools", "real-time" → "Real-Time")
  def titleize_preserving_hyphens(name)
    # Common acronyms that should stay uppercase
    acronyms = %w[API REST GraphQL SQL HTTP HTTPS URL URI JSON XML HTML CSS JS AI ML CI CD GPU CPU SaaS CLI]

    name.strip.split("-").map do |part|
      words = part.split(" ").map do |word|
        # Check if word is a known acronym (case-insensitive check)
        acronym = acronyms.find { |acr| acr.downcase == word.downcase }
        acronym || word.titleize
      end
      words.join(" ")
    end.join("-")
  end

  # Normalize technology names (handle common aliases and formats)
  def normalize_technology_name(name)
    normalized = name.strip.downcase

    # Technology name mappings (common aliases)
    tech_map = {
      "ruby on rails" => "Rails",
      "ror" => "Rails",
      "rails" => "Rails",
      "ruby" => "Ruby",
      "javascript" => "JavaScript",
      "js" => "JavaScript",
      "typescript" => "TypeScript",
      "ts" => "TypeScript",
      "node.js" => "Node.js",
      "nodejs" => "Node.js",
      "node" => "Node.js",
      "python" => "Python",
      "py" => "Python",
      "golang" => "Go",
      "go" => "Go",
      "java" => "Java",
      "rust" => "Rust",
      "c++" => "C++",
      "cpp" => "C++",
      "c#" => "C#",
      "csharp" => "C#",
      "php" => "PHP",
      "react" => "React",
      "reactjs" => "React",
      "vue" => "Vue.js",
      "vuejs" => "Vue.js",
      "vue.js" => "Vue.js",
      "angular" => "Angular",
      "angularjs" => "Angular",
      "django" => "Django",
      "flask" => "Flask",
      "spring" => "Spring",
      "laravel" => "Laravel",
      "elixir" => "Elixir",
      "kotlin" => "Kotlin",
      "swift" => "Swift",
      "postgresql" => "PostgreSQL",
      "postgres" => "PostgreSQL",
      "pg" => "PostgreSQL",
      "mysql" => "MySQL",
      "mongodb" => "MongoDB",
      "mongo" => "MongoDB",
      "redis" => "Redis",
      "elasticsearch" => "Elasticsearch",
      "docker" => "Docker",
      "kubernetes" => "Kubernetes",
      "k8s" => "Kubernetes"
    }

    tech_map[normalized] || name.strip.titleize
  end

  #--------------------------------------
  # EMBEDDING METHODS (LAYER 3)
  #--------------------------------------

  # Calculate cosine similarity between two embedding vectors
  # Returns: Float (0.0 - 1.0)
  def cosine_similarity(vec1, vec2)
    return 0.0 if vec1.nil? || vec2.nil?

    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(vec1.sum { |x| x**2 })
    magnitude2 = Math.sqrt(vec2.sum { |x| x**2 })

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    dot_product / (magnitude1 * magnitude2)
  end

  # Find category by semantic embedding similarity
  # Returns: Category or nil
  def find_by_embedding(name, category_type)
    # Generate embedding for search term
    search_embedding = generate_embedding(name)
    return nil if search_embedding.nil?

    # Find all categories of this type with embeddings
    candidates = Category
      .where(category_type: category_type)
      .where.not(embedding: nil)

    # Calculate similarity scores
    best_match = nil
    best_score = 0.0

    candidates.each do |candidate|
      score = cosine_similarity(search_embedding, candidate.embedding)
      if score > best_score && score >= EMBEDDING_THRESHOLD
        best_score = score
        best_match = candidate
      end
    end

    Rails.logger.info "🔍 Embedding similarity: '#{name}' → '#{best_match&.name}' (#{best_score.round(2)})" if best_match

    best_match
  end

  # Generate OpenAI embedding for a category name
  # Returns: Array<Float> or nil
  def generate_embedding(name)
    return nil if name.blank?

    client = OpenAI::Client.new(
      api_key: Rails.application.credentials.openai&.api_key
    )

    response = client.embeddings.create(
      model: "text-embedding-3-small",
      input: name
    )

    response[:data][0][:embedding]
  rescue => e
    Rails.logger.error "Failed to generate embedding: #{e.message}"
    nil
  end
end
