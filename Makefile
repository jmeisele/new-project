PROJECT=my_fancy_project
PYTHON_VERSION=3.9

SOURCE_OBJECTS=src tests

deploy:
	poetry build

format.black:
	poetry run black ${SOURCE_OBJECTS}
format.isort:
	poetry run isort --atomic ${SOURCE_OBJECTS}
format: format.isort format.black

lints.format.check:
	poetry run black --check ${SOURCE_OBJECTS}
	poetry run isort --check-only ${SOURCE_OBJECTS}
lints.flake8:
	poetry run flake8 --output-file=output.txt --ignore=DAR,E203,W503 ${SOURCE_OBJECTS}
lints.flake8.strict:
	poetry run flake8 ${SOURCE_OBJECTS}
lints.mypy:
	poetry run mypy ${SOURCE_OBJECTS}
lints.pylint:
	poetry run pylint --rcfile pyproject.toml  ${SOURCE_OBJECTS}
lints: lints.flake8
lints.strict: lints lints.pylint lints.flake8.strict lints.mypy

setup: setup.python setup.sysdep.poetry setup.project
setup.uninstall: setup.python
	poetry env remove ${PYTHON_VERSION} || true
setup.ci: setup.ci.poetry setup.project
setup.ci.poetry:
	pip install poetry
setup.project:
	@poetry env use $$(python -c "import sys; print(sys.executable)")
	@echo "Active interpreter path: $$(poetry env info --path)/bin/python"
	poetry install
setup.python.activation:
	@pyenv local ${PYTHON_VERSION} >/dev/null 2>&1 || true
	@asdf local python ${PYTHON_VERSION} >/dev/null 2>&1 || true

setup.python: setup.python.activation
	@echo "Active Python version: $$(python --version)"
	@echo "Base Interpreter path: $$(python -c 'import sys; print(sys.executable)')"
	@test "$$(python --version | cut -d' ' -f2)" = "${PYTHON_VERSION}" \
        || (echo "Please activate python ${PYTHON_VERSION}" && exit 1)
setup.sysdep.poetry:
	@command -v poetry \&> /dev/null \
        || (echo "Poetry not found. \n  Installation instructions: https://python-poetry.org/docs/" \
            && exit 1)

test:
	docker-compose up unit-tests
test.clean:
	docker-compose down
	-docker rmi $$(docker images -a | grep ${PROJECT} | tr -s ' ' | cut -d' ' -f3)
	-docker image prune -f
test.shell:
	docker-compose run unit-tests /bin/bash
test.shell.debug:
	docker-compose run --entrypoint /bin/bash unit-tests
test.unit: setup
	poetry run coverage run -m pytest \
		--ignore tests/integration \
		--cov=./ \
		--cov-report=xml:coverage.xml \
		--junitxml=results.xml \
		--cov-report term
test.integration:
	poetry run pytest tests/integration/test_integration.py
