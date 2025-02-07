.PHONY: sorbet
sorbet:
	bundle exec srb tc

.PHONY: build
build:
	gem build boba.gemspec

.PHONY: clean
clean:
	rm -fr boba-*.gem

.PHONY: docs
docs:
	bundle exec rake generate_dsl_documentation

.PHONY: gem-rbis
gem-rbis:
	bin/tapioca gems --no-doc --no-loc

# release
#   make clean && make docs && make build
# 	gem push boba-[version].gem
#		gh release create [version]
