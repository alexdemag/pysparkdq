build:
	python setup.py sdist bdist_wheel

test:
	pip3 install -r requirements_test.txt
	pytest -v