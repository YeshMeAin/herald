require_relative "lib/herald/version"

Gem::Specification.new do |spec|
  spec.name          = "herald-agent"
  spec.version       = Herald::VERSION
  spec.authors       = ["Yonatan Hadas"]
  spec.email         = ["yonatnh@gmail.com"]

  spec.summary       = "Natural language agent for Rails apps via Telegram"
  spec.description   = "Herald adds an LLM-powered agent to any Rails app, accessible through Telegram. " \
                        "Annotate your models and services, and interact with your app using plain English."
  spec.homepage      = "https://github.com/YonatanH1008/herald"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib}/**/*", "LICENSE.txt", "README.md"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "faraday", ">= 2.0"
  spec.add_dependency "aws-sdk-bedrockruntime", "~> 1.0"
end
