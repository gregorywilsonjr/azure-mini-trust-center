# Contributing to Azure Mini Trust Center

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Environment details (Azure region, OS, etc.)
- Screenshots if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please create an issue with:
- Clear description of the enhancement
- Use case and benefits
- Proposed implementation approach (if you have one)

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation as needed
4. **Test your changes**
   - Deploy to a test Azure environment
   - Verify all functionality works
5. **Commit with clear messages**
   ```bash
   git commit -m "Add feature: description of what you added"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**
   - Describe what changes you made and why
   - Reference any related issues
   - Include screenshots if UI changes

## Code Style Guidelines

### Bicep
- Use descriptive resource names
- Add comments for complex configurations
- Follow Azure naming conventions
- Use parameters for configurable values

### JavaScript/HTML
- Use consistent indentation (2 spaces)
- Add comments for non-obvious logic
- Keep functions small and focused
- Use meaningful variable names

### PowerShell
- Use approved verbs (Get-, Set-, New-, etc.)
- Add comment-based help
- Handle errors gracefully
- Use consistent parameter naming

### Python
- Follow PEP 8 style guide
- Use type hints where appropriate
- Add docstrings to functions
- Handle exceptions properly

## Documentation

- Update README.md if adding features
- Add inline comments for complex code
- Update deployment guides if changing infrastructure
- Include examples in documentation

## Testing

Before submitting a PR:
- [ ] Deploy to a test Azure environment
- [ ] Verify all dashboard cards display correctly
- [ ] Test Logic App runs successfully
- [ ] Check Function App health endpoint
- [ ] Validate RBAC permissions work
- [ ] Test with both mock and real data

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion in GitHub Discussions
- Reach out to maintainers

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the issue, not the person
- Help others learn and grow

Thank you for contributing! 🎉
