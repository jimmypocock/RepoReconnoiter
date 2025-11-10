# frozen_string_literal: true

# Canonical category definitions
# Generated: 2025-11-10 03:11:52
# Total categories: 102
# NOTE: Creates exact categories (no fuzzy matching) to avoid conflicts

puts "Seeding categories..."


# Technology (50 categories)
Category.find_or_create_by!(name: 'Async', category_type: 'technology') do |c|
  c.slug = 'async'
  c.description = 'Async programming language and tools'
end
Category.find_or_create_by!(name: 'Authentication', category_type: 'technology') do |c|
  c.slug = 'authentication'
  c.description = 'Authentication programming language and tools'
end
Category.find_or_create_by!(name: 'Aws', category_type: 'technology') do |c|
  c.slug = 'aws'
  c.description = 'Aws programming language and tools'
end
Category.find_or_create_by!(name: 'Aws Lambda', category_type: 'technology') do |c|
  c.slug = 'aws-lambda'
  c.description = 'Aws Lambda programming language and tools'
end
Category.find_or_create_by!(name: 'Blockchain Technology', category_type: 'technology') do |c|
  c.slug = 'blockchain-technology'
  c.description = 'Blockchain Technology programming language and tools'
end
Category.find_or_create_by!(name: 'Buckle Script', category_type: 'technology') do |c|
  c.slug = 'buckle-script'
  c.description = 'Buckle Script programming language and tools'
end
Category.find_or_create_by!(name: 'C#', category_type: 'technology') do |c|
  c.slug = 'c'
  c.description = 'C# programming language and tools'
end
Category.find_or_create_by!(name: 'Cdk', category_type: 'technology') do |c|
  c.slug = 'cdk'
  c.description = 'Cdk programming language and tools'
end
Category.find_or_create_by!(name: 'Deep Learning', category_type: 'technology') do |c|
  c.slug = 'deep-learning'
  c.description = 'Deep Learning programming language and tools'
end
Category.find_or_create_by!(name: 'Django', category_type: 'technology') do |c|
  c.slug = 'django'
  c.description = 'Django programming language and tools'
end
Category.find_or_create_by!(name: 'Docker', category_type: 'technology') do |c|
  c.slug = 'docker'
  c.description = 'Docker programming language and tools'
end
Category.find_or_create_by!(name: 'Elixir', category_type: 'technology') do |c|
  c.slug = 'elixir'
  c.description = 'Elixir programming language and tools'
end
Category.find_or_create_by!(name: 'Etl', category_type: 'technology') do |c|
  c.slug = 'etl'
  c.description = 'Etl programming language and tools'
end
Category.find_or_create_by!(name: 'Go', category_type: 'technology') do |c|
  c.slug = 'go'
  c.description = 'Go programming language and tools'
end
Category.find_or_create_by!(name: 'Html', category_type: 'technology') do |c|
  c.slug = 'html'
  c.description = 'Html programming language and tools'
end
Category.find_or_create_by!(name: 'Http', category_type: 'technology') do |c|
  c.slug = 'http'
  c.description = 'Http programming language and tools'
end
Category.find_or_create_by!(name: 'Java', category_type: 'technology') do |c|
  c.slug = 'java'
  c.description = 'Java programming language and tools'
end
Category.find_or_create_by!(name: 'JavaScript', category_type: 'technology') do |c|
  c.slug = 'javascript'
  c.description = 'JavaScript programming language and tools'
end
Category.find_or_create_by!(name: 'Jupyter Notebook', category_type: 'technology') do |c|
  c.slug = 'jupyter-notebook'
  c.description = 'Jupyter Notebook programming language and tools'
end
Category.find_or_create_by!(name: 'Kotlin', category_type: 'technology') do |c|
  c.slug = 'kotlin'
  c.description = 'Kotlin programming language and tools'
end
Category.find_or_create_by!(name: 'Kubernetes', category_type: 'technology') do |c|
  c.slug = 'kubernetes'
  c.description = 'Kubernetes programming language and tools'
end
Category.find_or_create_by!(name: 'Laravel', category_type: 'technology') do |c|
  c.slug = 'laravel'
  c.description = 'Laravel programming language and tools'
end
Category.find_or_create_by!(name: 'Node.js', category_type: 'technology') do |c|
  c.slug = 'node-js'
  c.description = 'Node.js programming language and tools'
end
Category.find_or_create_by!(name: 'O Caml', category_type: 'technology') do |c|
  c.slug = 'o-caml'
  c.description = 'O Caml programming language and tools'
end
Category.find_or_create_by!(name: 'Open Policy Agent', category_type: 'technology') do |c|
  c.slug = 'open-policy-agent'
  c.description = 'Open Policy Agent programming language and tools'
end
Category.find_or_create_by!(name: 'Optimization', category_type: 'technology') do |c|
  c.slug = 'optimization'
  c.description = 'Optimization programming language and tools'
end
Category.find_or_create_by!(name: 'Pdf Generation', category_type: 'technology') do |c|
  c.slug = 'pdf-generation'
  c.description = 'Pdf Generation programming language and tools'
end
Category.find_or_create_by!(name: 'PHP', category_type: 'technology') do |c|
  c.slug = 'php'
  c.description = 'PHP programming language and tools'
end
Category.find_or_create_by!(name: 'PostgreSQL', category_type: 'technology') do |c|
  c.slug = 'postgresql'
  c.description = 'PostgreSQL programming language and tools'
end
Category.find_or_create_by!(name: 'Prawn', category_type: 'technology') do |c|
  c.slug = 'prawn'
  c.description = 'Prawn programming language and tools'
end
Category.find_or_create_by!(name: 'Py Torch', category_type: 'technology') do |c|
  c.slug = 'py-torch'
  c.description = 'Py Torch programming language and tools'
end
Category.find_or_create_by!(name: 'Python', category_type: 'technology') do |c|
  c.slug = 'python'
  c.description = 'Python programming language and tools'
end
Category.find_or_create_by!(name: 'Rails', category_type: 'technology') do |c|
  c.slug = 'rails'
  c.description = 'Rails programming language and tools'
end
Category.find_or_create_by!(name: 'React', category_type: 'technology') do |c|
  c.slug = 'react'
  c.description = 'React programming language and tools'
end
Category.find_or_create_by!(name: 'Redis', category_type: 'technology') do |c|
  c.slug = 'redis'
  c.description = 'Redis programming language and tools'
end
Category.find_or_create_by!(name: 'Ruby', category_type: 'technology') do |c|
  c.slug = 'ruby'
  c.description = 'Ruby programming language and tools'
end
Category.find_or_create_by!(name: 'Rust', category_type: 'technology') do |c|
  c.slug = 'rust'
  c.description = 'Rust programming language and tools'
end
Category.find_or_create_by!(name: 'Scala', category_type: 'technology') do |c|
  c.slug = 'scala'
  c.description = 'Scala programming language and tools'
end
Category.find_or_create_by!(name: 'Scheduler', category_type: 'technology') do |c|
  c.slug = 'scheduler'
  c.description = 'Scheduler programming language and tools'
end
Category.find_or_create_by!(name: 'Shell', category_type: 'technology') do |c|
  c.slug = 'shell'
  c.description = 'Shell programming language and tools'
end
Category.find_or_create_by!(name: 'Sidekiq', category_type: 'technology') do |c|
  c.slug = 'sidekiq'
  c.description = 'Sidekiq programming language and tools'
end
Category.find_or_create_by!(name: 'Smarty', category_type: 'technology') do |c|
  c.slug = 'smarty'
  c.description = 'Smarty programming language and tools'
end
Category.find_or_create_by!(name: 'Spring', category_type: 'technology') do |c|
  c.slug = 'spring'
  c.description = 'Spring programming language and tools'
end
Category.find_or_create_by!(name: 'Swift', category_type: 'technology') do |c|
  c.slug = 'swift'
  c.description = 'Swift programming language and tools'
end
Category.find_or_create_by!(name: 'Testing', category_type: 'technology') do |c|
  c.slug = 'testing'
  c.description = 'Testing programming language and tools'
end
Category.find_or_create_by!(name: 'TypeScript', category_type: 'technology') do |c|
  c.slug = 'typescript'
  c.description = 'TypeScript programming language and tools'
end
Category.find_or_create_by!(name: 'Vue.js', category_type: 'technology') do |c|
  c.slug = 'vue-js'
  c.description = 'Vue.js programming language and tools'
end
Category.find_or_create_by!(name: 'Web Assembly', category_type: 'technology') do |c|
  c.slug = 'web-assembly'
  c.description = 'Web Assembly programming language and tools'
end
Category.find_or_create_by!(name: 'Web Sockets', category_type: 'technology') do |c|
  c.slug = 'web-sockets'
  c.description = 'Web Sockets programming language and tools'
end
Category.find_or_create_by!(name: 'Zig', category_type: 'technology') do |c|
  c.slug = 'zig'
  c.description = 'Zig programming language and tools'
end

# Problem Domain (38 categories)
Category.find_or_create_by!(name: 'API Client Generation', category_type: 'problem_domain') do |c|
  c.slug = 'api-client-generation'
  c.description = 'Tools and libraries for api client generation'
end
Category.find_or_create_by!(name: 'API Integration', category_type: 'problem_domain') do |c|
  c.slug = 'api-integration'
  c.description = 'Tools and libraries for api integration'
end
Category.find_or_create_by!(name: 'Artificial Intelligence', category_type: 'problem_domain') do |c|
  c.slug = 'artificial-intelligence'
  c.description = 'Tools and libraries for artificial intelligence'
end
Category.find_or_create_by!(name: 'Astronomy And Astrophysics', category_type: 'problem_domain') do |c|
  c.slug = 'astronomy-and-astrophysics'
  c.description = 'Tools and libraries for astronomy and astrophysics'
end
Category.find_or_create_by!(name: 'Authentication', category_type: 'problem_domain') do |c|
  c.slug = 'authentication'
  c.description = 'Tools and libraries for authentication'
end
Category.find_or_create_by!(name: 'Automation Tools', category_type: 'problem_domain') do |c|
  c.slug = 'automation-tools'
  c.description = 'Tools and libraries for automation tools'
end
Category.find_or_create_by!(name: 'Backend Applications', category_type: 'problem_domain') do |c|
  c.slug = 'backend-applications'
  c.description = 'Tools and libraries for backend applications'
end
Category.find_or_create_by!(name: 'Background Job Processing', category_type: 'problem_domain') do |c|
  c.slug = 'background-job-processing'
  c.description = 'Tools and libraries for background job processing'
end
Category.find_or_create_by!(name: 'Caching', category_type: 'problem_domain') do |c|
  c.slug = 'caching'
  c.description = 'Tools and libraries for caching'
end
Category.find_or_create_by!(name: 'Chart Generation', category_type: 'problem_domain') do |c|
  c.slug = 'chart-generation'
  c.description = 'Tools and libraries for chart generation'
end
Category.find_or_create_by!(name: 'Continuous Deployment', category_type: 'problem_domain') do |c|
  c.slug = 'continuous-deployment'
  c.description = 'Tools and libraries for continuous deployment'
end
Category.find_or_create_by!(name: 'Cron Job Management', category_type: 'problem_domain') do |c|
  c.slug = 'cron-job-management'
  c.description = 'Tools and libraries for cron job management'
end
Category.find_or_create_by!(name: 'Data Visualization', category_type: 'problem_domain') do |c|
  c.slug = 'data-visualization'
  c.description = 'Tools and libraries for data visualization'
end
Category.find_or_create_by!(name: 'Database Tools', category_type: 'problem_domain') do |c|
  c.slug = 'database-tools'
  c.description = 'Tools and libraries for database tools'
end
Category.find_or_create_by!(name: 'Dev Ops Tools', category_type: 'problem_domain') do |c|
  c.slug = 'dev-ops-tools'
  c.description = 'Tools and libraries for dev ops tools'
end
Category.find_or_create_by!(name: 'Email', category_type: 'problem_domain') do |c|
  c.slug = 'email'
  c.description = 'Tools and libraries for email'
end
Category.find_or_create_by!(name: 'File Processing', category_type: 'problem_domain') do |c|
  c.slug = 'file-processing'
  c.description = 'Tools and libraries for file processing'
end
Category.find_or_create_by!(name: 'HTML Manipulation', category_type: 'problem_domain') do |c|
  c.slug = 'html-manipulation'
  c.description = 'Tools and libraries for html manipulation'
end
Category.find_or_create_by!(name: 'HTTP Client', category_type: 'problem_domain') do |c|
  c.slug = 'http-client'
  c.description = 'Tools and libraries for http client'
end
Category.find_or_create_by!(name: 'Identity Management', category_type: 'problem_domain') do |c|
  c.slug = 'identity-management'
  c.description = 'Tools and libraries for identity management'
end
Category.find_or_create_by!(name: 'Inverse Problems', category_type: 'problem_domain') do |c|
  c.slug = 'inverse-problems'
  c.description = 'Tools and libraries for inverse problems'
end
Category.find_or_create_by!(name: 'Invoice Processing', category_type: 'problem_domain') do |c|
  c.slug = 'invoice-processing'
  c.description = 'Tools and libraries for invoice processing'
end
Category.find_or_create_by!(name: 'JSON Parsing', category_type: 'problem_domain') do |c|
  c.slug = 'json-parsing'
  c.description = 'Tools and libraries for json parsing'
end
Category.find_or_create_by!(name: 'Linear Operators', category_type: 'problem_domain') do |c|
  c.slug = 'linear-operators'
  c.description = 'Tools and libraries for linear operators'
end
Category.find_or_create_by!(name: 'Machine Learning', category_type: 'problem_domain') do |c|
  c.slug = 'machine-learning'
  c.description = 'Tools and libraries for machine learning'
end
Category.find_or_create_by!(name: 'Management Accounting', category_type: 'problem_domain') do |c|
  c.slug = 'management-accounting'
  c.description = 'Tools and libraries for management accounting'
end
Category.find_or_create_by!(name: 'Mathematics', category_type: 'problem_domain') do |c|
  c.slug = 'mathematics'
  c.description = 'Tools and libraries for mathematics'
end
Category.find_or_create_by!(name: 'Memory Allocation', category_type: 'problem_domain') do |c|
  c.slug = 'memory-allocation'
  c.description = 'Tools and libraries for memory allocation'
end
Category.find_or_create_by!(name: 'Monitoring', category_type: 'problem_domain') do |c|
  c.slug = 'monitoring'
  c.description = 'Tools and libraries for monitoring'
end
Category.find_or_create_by!(name: 'Multilinear Algebra', category_type: 'problem_domain') do |c|
  c.slug = 'multilinear-algebra'
  c.description = 'Tools and libraries for multilinear algebra'
end
Category.find_or_create_by!(name: 'Payment Processing', category_type: 'problem_domain') do |c|
  c.slug = 'payment-processing'
  c.description = 'Payment gateways, billing systems, subscription management'
end
Category.find_or_create_by!(name: 'Performance', category_type: 'problem_domain') do |c|
  c.slug = 'performance'
  c.description = 'Tools and libraries for performance'
end
Category.find_or_create_by!(name: 'Profiler Tools', category_type: 'problem_domain') do |c|
  c.slug = 'profiler-tools'
  c.description = 'Tools and libraries for profiler tools'
end
Category.find_or_create_by!(name: 'Real-Time Communication', category_type: 'problem_domain') do |c|
  c.slug = 'real-time-communication'
  c.description = 'Tools and libraries for real-time communication'
end
Category.find_or_create_by!(name: 'Search', category_type: 'problem_domain') do |c|
  c.slug = 'search'
  c.description = 'Tools and libraries for search'
end
Category.find_or_create_by!(name: 'Security', category_type: 'problem_domain') do |c|
  c.slug = 'security'
  c.description = 'Tools and libraries for security'
end
Category.find_or_create_by!(name: 'Serverless Applications', category_type: 'problem_domain') do |c|
  c.slug = 'serverless-applications'
  c.description = 'Tools and libraries for serverless applications'
end
Category.find_or_create_by!(name: 'Slab Allocator', category_type: 'problem_domain') do |c|
  c.slug = 'slab-allocator'
  c.description = 'Tools and libraries for slab allocator'
end

# Architecture Pattern (14 categories)
Category.find_or_create_by!(name: 'API-First Design', category_type: 'architecture_pattern') do |c|
  c.slug = 'api-first-design'
  c.description = 'API-First Design architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'CLI Tools', category_type: 'architecture_pattern') do |c|
  c.slug = 'cli-tools'
  c.description = 'CLI Tools architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Data Processing', category_type: 'architecture_pattern') do |c|
  c.slug = 'data-processing'
  c.description = 'Data Processing architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Developer Tools', category_type: 'architecture_pattern') do |c|
  c.slug = 'developer-tools'
  c.description = 'Developer Tools architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Event-Driven Architecture', category_type: 'architecture_pattern') do |c|
  c.slug = 'event-driven-architecture'
  c.description = 'Event-Driven Architecture architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'File Processing Framework', category_type: 'architecture_pattern') do |c|
  c.slug = 'file-processing-framework'
  c.description = 'File Processing Framework architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Frontend Frameworks', category_type: 'architecture_pattern') do |c|
  c.slug = 'frontend-frameworks'
  c.description = 'Frontend Frameworks architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Microservices Architecture', category_type: 'architecture_pattern') do |c|
  c.slug = 'microservices-architecture'
  c.description = 'Microservices Architecture architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Microservices Tooling', category_type: 'architecture_pattern') do |c|
  c.slug = 'microservices-tooling'
  c.description = 'Microservices Tooling architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Monolith Utilities', category_type: 'architecture_pattern') do |c|
  c.slug = 'monolith-utilities'
  c.description = 'Monolith Utilities architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Multithreaded Architecture', category_type: 'architecture_pattern') do |c|
  c.slug = 'multithreaded-architecture'
  c.description = 'Multithreaded Architecture architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Scientific Computing', category_type: 'architecture_pattern') do |c|
  c.slug = 'scientific-computing'
  c.description = 'Scientific Computing architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'Serverless Architecture', category_type: 'architecture_pattern') do |c|
  c.slug = 'serverless-architecture'
  c.description = 'Serverless Architecture architectural pattern and related tools'
end
Category.find_or_create_by!(name: 'State Management', category_type: 'architecture_pattern') do |c|
  c.slug = 'state-management'
  c.description = 'State Management architectural pattern and related tools'
end

puts "✅ Categories seeded successfully!"
