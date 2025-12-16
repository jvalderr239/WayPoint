from setuptools import setup, find_packages

# Read the contents of your README file
from os import path
this_directory = path.abspath(path.dirname(__file__))
with open(path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

# Read the contents of the requirements file for core dependencies
def read_requirements(filename):
    with open(filename, 'r') as file:
        return [line.strip() for line in file if line.strip() and not line.startswith('#')]

setup(
    name='waypoint-3d-perception',
    version='0.1.0',
    long_description=long_description,
    long_description_content_type='text/markdown',
    
    # ----------------------------------------------------
    # 1. CORE PROJECT METADATA
    # ----------------------------------------------------
    author='Jose Valderrama',
    author_email='jvalderr239@gmail.com',
    description='Voxel-based 3D object detection for robust pedestrian/cyclist perception on Waymo Open Dataset (WOD).',
    license='MIT', 
    long_description=long_description,
    long_description_content_type="text/markdown",
    project_urls={
        "Source": "https://github.com/jvalderr239/WayPoint",
        "Bug Tracker": "https://github.com/jvalderr239/WayPoint/issues",
    },
    packages=find_packages(where='src'),
    
    # ----------------------------------------------------
    # 3. DEPENDENCIES
    # ----------------------------------------------------
    install_requires=read_requirements('requirements.txt'),
    
    # ----------------------------------------------------
    # 4. DEVELOPMENT/STATIC ANALYSIS EXTRAS
    # ----------------------------------------------------
    # Used for 'pip install -e .[dev]' (as used in the setup-dev Makefile target)
    extras_require={
        'dev': [
            'black',
            'isort',
            'mypy',
            'pylint',
            'pytest',
            'coverage',
            "matplotlib", 
            "pandas", 
            "jupyter",
            "ipykernel",
            "torchsummary",
            "ipywidgets",
            "widgetsnbextension",
            "pandas-profiling"
        ],
    },

    # ----------------------------------------------------
    # 5. CLASSIFIERS
    # ----------------------------------------------------
    classifiers=[
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.10',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
        'Topic :: Scientific/Engineering :: Image Recognition',
        'Intended Audience :: Developers',
        'Intended Audience :: Science/Research'
    ],
    # Minimal python version
    python_requires='>=3.10',
)