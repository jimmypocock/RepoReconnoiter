module RepositoriesHelper
  def category_badge_class(category_type)
    case category_type
    when "problem_domain"
      "bg-blue-100 text-blue-800"
    when "architecture_pattern"
      "bg-purple-100 text-purple-800"
    when "maturity"
      "bg-green-100 text-green-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
