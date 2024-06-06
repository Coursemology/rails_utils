$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_utils/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_utils"
  s.version     = RailsUtils::VERSION
  s.authors     = ["Bivan Alzacky Harmanto"]
  s.email       = ["bivan.alzacky@gmail.com"]
  s.homepage    = "https://github.com/Coursemology/rails_utils"
  s.summary     = "Rails helpers based on opinionated project practices."
  s.description = "Rails helpers based on opinionated project practices. Currently useful for structuring CSS and JS."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = ">= 3.0"

  s.add_dependency "rails", ">= 6"

  s.add_development_dependency "minitest" , ">= 4.7.5"
  s.add_development_dependency "sprockets-rails", '~>3.0'
  s.add_development_dependency "sprockets", '~>3.0'
  s.add_development_dependency "appraisal", "~> 2.1"
  s.add_development_dependency "mocha"

  s.license = 'MIT'
end
