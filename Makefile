.PHONY: bootstrap dev-api macos test lint db-generate db-migrate db-studio

bootstrap:
	./scripts/bootstrap.sh

dev-api:
	pnpm dev:api

macos:
	cd apps/macos && xcodegen generate && open NotchFlow.xcodeproj

test:
	./scripts/test.sh

lint:
	./scripts/lint.sh

db-generate:
	pnpm db:generate

db-migrate:
	./scripts/migrate.sh

db-studio:
	pnpm db:studio
