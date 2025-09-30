.PHONY: help install test run docker-up docker-down clean

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	bundle install

test: ## Run tests
	bundle exec rspec

lint: ## Run RuboCop linter
	bundle exec rubocop

lint-fix: ## Run RuboCop linter with auto-fix
	bundle exec rubocop -A

lint-check: ## Check RuboCop without fixing
	bundle exec rubocop --format simple

lint-security: ## Run RuboCop security checks
	bundle exec rubocop --only Security --format simple

lint-all: lint lint-security ## Run all linting checks
	@echo "✅ All linting checks completed"

check: lint-all test ## Run all checks (lint + test)
	@echo "✅ All checks passed"

ci-local: ## Run CI checks locally
	@echo "🔍 Running local CI checks..."
	@echo "1. Running RuboCop linting..."
	@make lint-check
	@echo "2. Running RuboCop security checks..."
	@make lint-security
	@echo "3. Running tests..."
	@make test
	@echo "✅ All CI checks passed locally!"

run: ## Run the application locally
	ruby app.rb

docker-up: ## Start with Docker Compose
	docker-compose up -d

docker-down: ## Stop Docker Compose
	docker-compose down

docker-logs: ## Show Docker logs
	docker-compose logs -f

migrate: ## Run database migrations
	ruby db/migrate.rb

generate-env: ## Generate secure environment files
	ruby scripts/generate_env.rb

create-env: ## Create .env from .env.example template
	@if [ ! -f .env.example ]; then \
		echo "❌ .env.example not found. Run 'make generate-env' first"; \
		exit 1; \
	fi
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env from .env.example template"; \
		echo "⚠️  Please update .env with your actual values"; \
	else \
		echo "⚠️  .env file already exists, skipping..."; \
	fi

setup-env: generate-env ## Generate environment files and show setup instructions
	@echo ""
	@echo "🔧 Environment setup completed!"
	@echo "📁 Generated files: .env, .env.production, .env.example"
	@echo ""
	@echo "Next steps:"
	@echo "1. Review and customize .env file if needed"
	@echo "2. Run 'make install' to install dependencies"
	@echo "3. Run 'make migrate' to setup database"
	@echo "4. Run 'make run' to start the application"
	@echo ""
	@echo "⚠️  Security reminder:"
	@echo "- Never commit .env files to version control"
	@echo "- Use different credentials for production"
	@echo "- .env.example is safe to commit (template for developers)"

test-api: ## Test API endpoints
	ruby test_api.rb

test-validation: ## Test parameter validation
	ruby test_validation.rb

clean: ## Clean up temporary files
	rm -rf tmp/
	rm -rf log/*.log

setup: install migrate ## Initial setup
	@echo "Setup completed! Run 'make run' to start the application."
