.PHONY: sorbet
sorbet:
	bundle exec srb tc

.PHONY: build
build:
	gem build boba.gemspec

.PHONY: clean
clean:
	rm -r boba-*.gem

.PHONY: release
release: clean build
	gem push boba-*.gem
