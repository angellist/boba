.PHONY: sorbet
sorbet:
	bundle exec srb tc

.PHONY: build
build:
	gem build boba.gemspec
