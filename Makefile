default:
	@flutter analyzer

.PHONY: clean
clean:
	@flutter clean

.PHONY: sort-imports
sort-imports:
	@flutter pub run import_sorter:main
