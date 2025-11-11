class SearchSynonymExpander
  #--------------------------------------
  # CONFIGURATION
  #--------------------------------------

  # Map common search terms to their synonyms/variations
  # Key = base term, Value = array of synonyms (including base term)
  SYNONYMS = {
    # Authentication variations
    "auth" => [ "auth", "authentication", "authorize", "authorization" ],
    "authentication" => [ "auth", "authentication", "authorize", "authorization" ],

    # Job processing variations
    "job" => [ "job", "jobs", "queue", "queues", "worker", "workers" ],
    "jobs" => [ "job", "jobs", "queue", "queues", "worker", "workers" ],
    "queue" => [ "job", "jobs", "queue", "queues", "worker", "workers" ],
    "worker" => [ "job", "jobs", "queue", "queues", "worker", "workers" ],

    # Backend/API variations
    "api" => [ "api", "rest", "restful", "endpoint", "endpoints" ],
    "backend" => [ "backend", "back-end", "server", "server-side" ],

    # Frontend variations
    "frontend" => [ "frontend", "front-end", "client", "client-side", "ui", "interface" ],
    "ui" => [ "ui", "interface", "frontend", "front-end" ],

    # Database variations
    "db" => [ "db", "database", "databases", "persistence", "storage" ],
    "database" => [ "db", "database", "databases", "persistence", "storage" ],
    "orm" => [ "orm", "object-relational", "active record", "activerecord" ],

    # Testing variations
    "test" => [ "test", "tests", "testing", "spec", "specs" ],
    "testing" => [ "test", "tests", "testing", "spec", "specs" ],

    # State management variations
    "state" => [ "state", "states", "state management", "store", "redux" ],

    # Common language aliases
    "js" => [ "js", "javascript", "node", "nodejs", "node.js" ],
    "javascript" => [ "js", "javascript", "node", "nodejs", "node.js" ],
    "node" => [ "js", "javascript", "node", "nodejs", "node.js" ],
    "ts" => [ "ts", "typescript" ],
    "typescript" => [ "ts", "typescript" ],
    "py" => [ "py", "python" ],
    "python" => [ "py", "python" ],
    "rb" => [ "rb", "ruby" ],
    "ruby" => [ "rb", "ruby" ]
  }.freeze

  #--------------------------------------
  # CLASS METHODS
  #--------------------------------------

  class << self
    # Expand a search term to include synonyms
    # Returns array of terms to search for
    # @param term [String] The search term
    # @return [Array<String>] Array of terms including synonyms
    def expand(term)
      normalized = term.to_s.downcase.strip
      return [ normalized ] if normalized.blank?

      # Check if we have synonyms for this term
      synonyms = SYNONYMS[normalized]
      return [ normalized ] unless synonyms

      # Return unique set of synonyms
      synonyms.uniq
    end

    # Expand multiple terms and flatten
    # @param terms [Array<String>] Array of search terms
    # @return [Array<String>] Flattened array of all terms and their synonyms
    def expand_all(terms)
      terms.flat_map { |term| expand(term) }.uniq
    end

    # Check if a term has known synonyms
    # @param term [String] The search term
    # @return [Boolean] True if synonyms exist
    def has_synonyms?(term)
      SYNONYMS.key?(term.to_s.downcase.strip)
    end
  end
end
