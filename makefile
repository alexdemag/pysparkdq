build:
	python setup.py sdist bdist_wheel

publish:
	python3 -m twine upload --skip-existing dist/*

.PHONY: all test clean
test:
	pip3 install -r requirements_test.txt
	pytest -v