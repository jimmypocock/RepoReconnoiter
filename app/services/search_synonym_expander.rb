class SearchSynonymExpander
  #--------------------------------------
  # CONSTANTS
  #--------------------------------------

  # Load synonyms from YAML configuration
  # Map common search terms to their synonyms/variations
  # Key = base term, Value = array of synonyms (including base term)
  SYNONYMS = YAML.load_file(
    Rails.root.join("config/dictionaries/search_synonyms.yml")
  ).fetch("synonyms").freeze

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
