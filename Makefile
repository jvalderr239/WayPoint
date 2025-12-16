.ONESHELL:
# Define the name of the virtual environment directory
VENV := .venv
BIN := ${VENV}/bin
PYTHON := ${BIN}/python3.10 -m
DIST := ${VENV}/dist
PIP := ${BIN}/pip install --upgrade
PROJECT := ${VENV}/../

.DEFAULT_GOAL := help

# Source files for static analysis tools
python_src = src scripts/*.py tests/*.py
coverage_src = src
DATA_CONVERTER := src/waypoint/data_prep/kitti_converter.py
KITTI_CONFIG := config/kitti_voxel.yaml

# --- UTILITIES ---

define PRINT_HELP_SCRIPT
import re, sys

for line in sys.stdin:
  match = re.match('^([a-zA-Z_-]+):.*?##(.*)$$', line)
  if match:
    target, help = match.groups()
    print("%20s %s", (target, help))
endef

export PRINT_HELP_SCRIPT

help:
	${PYTHON} -c "$$PRINT_HELP_SCRIPT" < "$(MAKEFILE_LIST)"

# --- CORE VENV AND INSTALLATION ---
$(VENV)/bin/activate: requirements.txt setup.py
	test -d $(VENV) || python3.10 -m venv $(VENV)
	${PIP} pip black isort mypy pytest coverage pylint torch torchvision tqdm
	${PIP} -r requirements.txt
	@echo "\n--- CRITICAL: SPCONV INSTALLATION ---"
	@echo "The 'spconv' library (for Sparse CNNs) must be installed separately based on your CUDA version."
	@echo "Consult the README for instructions."

venv: $(VENV)/bin/activate ## Create and update the project virtual environment.

install: venv ## Install the project in editable mode, including the 'src' package.
	${PIP} -e .

setup-dev: venv ## Install project and development dependencies (using the [dev] extra).
	${PIP} -e .[dev]

# --- ML WORKFLOW TARGETS ---

data: install ## Prepare the KITTI Dataset (Convert .bin and process labels).
	@echo "Starting KITTI Data Preparation..."
	# This script will read raw Velodyne data, calibration files, and labels
	# and output a processed format ready for the PyTorch DataLoader.
	${PYTHON} ${DATA_CONVERTER} --input_dir data/kitti/raw --output_dir data/kitti/processed
	@echo "Data preparation complete. Check 'data/kitti/processed/'"

train: install ## Start the VoxelGuard model training process for KITTI.
	@echo "Starting WayPoint training..."
	${PYTHON} scripts/train.py --cfg_file ${KITTI_CONFIG}

# --- STATIC ANALYSIS AND FORMATTING ---

check: venv check-format check-types lint ## Run all static analysis checks.

check-format: ## Check code formatting using black and isort.
	${PYTHON} black --check ${python_src}
	${PYTHON} isort --check-only ${python_src}

check-types: ## Check code types using mypy.
	${PYTHON} mypy ${python_src}

format: venv ## Apply code formatting using black and isort.
	${PYTHON} black ${python_src}
	${PYTHON} isort ${python_src}

lint: venv ## Run code linting using pylint.
	${PYTHON} pylint ${python_src} -f parseable -r n

# --- BUILD AND TEST ---

build: venv ## Build the distribution wheel.
	${PIP} wheel
	${PYTHON} setup.py bdist_wheel -d ${DIST}

test: install ## Run tests and generate coverage report.
	${PYTHON} coverage run --branch --source ${coverage_src} -m pytest tests/
	${PYTHON} coverage report

coverage: test ## Generate HTML coverage report.
	${PYTHON} coverage html

# --- CLEANUP ---

clean: clean-build clean-pyc clean-check clean-test ## Remove all generated files.

clean-build: ## Remove environment and build artifacts.
	rm -rf ${VENV}/
	rm -rf ${DIST}/
	rm -rf build/
	rm -rf out/
	rm -rf .eggs/
	find . -name '*.egg-info' -exec rm -rf {} +
	find . -name '*.egg' -exec rm -rf {} +

clean-pyc: ## Remove python artifacts (__pycache__, .pyc files).
	find . -name '*.pyc' -exec rm -rf {} +
	find . -name '*.pyo' -exec rm -rf {} +
	find . -name '*~' -exec rm -rf {} +
	find . -name '__pycache__' -exec rm -rf {} +

clean-check: ## Remove static analysis cache files.
	find . -name '.mypy_cache' -exec rm -rf {} +

clean-test: ## Remove test and coverage artifacts.
	find . -name '.pytest_cache' -exec rm -rf {} +
	rm -f coverage
	rm -f .coverage
	rm -rf htmlcov/

.PHONY: all clean check dev build test help