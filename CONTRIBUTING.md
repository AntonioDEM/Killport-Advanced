# Contributing to Killport-Advanced

Thank you for your interest in contributing to Killport-Advanced! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/AntonioDem/killport-advanced.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear messages
7. Push to your fork
8. Submit a Pull Request

## Development Setup

### Prerequisites
- Node.js (for extension development)
- Python 3.x
- Conda or Miniconda
- Bash/Zsh shell

### Installation
```bash
# Install dependencies
bash install_killport.sh

# Source the functions
source killport_zshrc_function.sh
```

## Code Standards

### Shell Scripts
- Use meaningful variable names
- Add comments for complex logic
- Follow shellcheck recommendations
- Use proper error handling with `set -e`

### Python
- Follow PEP 8 style guide
- Add type hints where applicable
- Include docstrings for functions and classes

### Documentation
- Update README.md if adding new features
- Add comments for non-obvious code
- Include examples in documentation

## Testing

Before submitting a pull request:
1. Test all shell scripts
2. Run benchmark tests if applicable
3. Verify conda environment integration works
4. Test on different platforms if possible

## Commit Messages

Use clear and descriptive commit messages:
```
feat: Add new visualization feature
fix: Correct port killing logic
docs: Update installation instructions
refactor: Improve benchmark script performance
```

## Pull Request Process

1. Update documentation with details of changes
2. Update the README.md if needed
3. The PR will be merged once reviewed and approved
4. Ensure all tests pass

## Reporting Issues

When reporting issues, please include:
- OS and version
- Shell type (bash/zsh)
- Conda version
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs or error messages

## Feature Requests

We welcome feature requests! Please:
- Check existing issues first
- Clearly describe the feature
- Explain the use case
- Provide examples if possible

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Maintain professionalism

## Questions?

Feel free to open an issue with the `question` label if you need help or clarification.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
