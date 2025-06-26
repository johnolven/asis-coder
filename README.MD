# 🤖 Asis-coder

**Your AI Development Assistant** - A modular CLI that connects your code with ChatGPT, Claude, and Gemini for enhanced development workflow.

[![npm version](https://badge.fury.io/js/@johnolven%2Fasis-coder.svg)](https://badge.fury.io/js/@johnolven%2Fasis-coder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🧠 **Multi-LLM Support**: ChatGPT, Claude, and Gemini integration
- 📁 **Smart Project Detection**: Automatically detects your project type and context
- 💬 **Interactive Mode**: Real-time streaming conversations with AI
- 🔧 **Modular Architecture**: Clean, maintainable codebase with specialized modules
- 🌐 **Cross-Platform**: Works on macOS, Linux, and Windows
- ⚡ **Context Generation**: Automatically includes relevant project files
- 🎯 **30+ AI Models**: Support for latest models from all providers

## ⚡ Quick Installation

### 🚀 With NPX (Recommended):
```bash
npx @johnolven/asis-coder setup
```

### 📦 Global Installation with NPM:
```bash
npm install -g @johnolven/asis-coder
coder setup
```

## 🖥️ Platform Compatibility

### ✅ **macOS and Linux**
Full automatic installation. The `coder` command will be available globally.

### ⚠️ **Windows**
Requires one of these environments:
- **Git Bash** (included with Git for Windows) - ⭐ Recommended
- **WSL** (Windows Subsystem for Linux)
- **PowerShell** with bash available

**On Windows use:**
```bash
npx @johnolven/asis-coder setup    # Initial configuration
npx @johnolven/asis-coder -i       # Interactive mode
npx @johnolven/asis-coder "question"  # Direct query
```

## 🚀 Quick Start

1. **Initial Setup**:
   ```bash
   coder setup  # Configure your API keys
   ```

2. **Generate Project Context**:
   ```bash
   coder -context  # Analyze your project
   ```

3. **Ask Questions**:
   ```bash
   coder "explain this project structure"
   coder "how can I optimize this code?"
   ```

4. **Interactive Mode**:
   ```bash
   coder -i  # Start interactive session
   ```

## 🧠 Supported AI Models

### ChatGPT (OpenAI) - 14 Models
- GPT-4o, GPT-4o-mini
- GPT-4 Turbo, GPT-4
- GPT-3.5 Turbo variants
- And more...

### Claude (Anthropic) - 8 Models
- Claude 3.5 Sonnet
- Claude 3 Opus, Sonnet, Haiku
- Claude 2.1, 2.0
- Claude Instant variants

### Gemini (Google) - 8 Models
- Gemini 1.5 Pro, Flash
- Gemini 1.0 Pro variants
- Gemini Pro Vision
- And more...

## 📋 Available Commands

```bash
# Configuration
coder setup                    # Initial setup wizard
coder -token                   # Update API tokens
coder -model                   # Change AI model
coder -llm                     # Switch LLM provider

# Project Analysis
coder -context                 # Generate project context
coder -project                 # Detect project type

# Interaction
coder "your question"          # Direct query
coder -i                       # Interactive mode
coder -history                 # View conversation history

# Utilities
coder -test                    # Test API configuration
coder -clean                   # Clear conversation history
coder -help                    # Show help
```

## 🌟 Usage Examples

### Basic Query
```bash
coder "What's the best way to optimize this React component?"
```

### Project Analysis
```bash
coder -context
coder "Analyze the architecture of this project and suggest improvements"
```

### Interactive Development Session
```bash
coder -i
# Start a conversation about your code
# Get real-time suggestions and explanations
```

### Switch Between Models
```bash
coder -model  # Choose from 30+ available models
coder -llm    # Switch between ChatGPT, Claude, Gemini
```

## 🏗️ Architecture

Asis-coder features a modular architecture with specialized components:

- **`lib/config.sh`**: System configuration and environment setup
- **`lib/api_validation.sh`**: API key validation and testing
- **`lib/llm_models.sh`**: LLM provider and model management
- **`lib/project_manager.sh`**: Project detection and context generation
- **`lib/ui_interface.sh`**: User interface and guided configuration
- **`lib/llm_communication.sh`**: AI communication and streaming

## 📁 Project Detection

Automatically detects and optimizes for:

- **Web**: React, Vue, Angular, HTML/CSS/JS
- **Backend**: Node.js, Python, PHP, Ruby
- **Mobile**: React Native, Flutter
- **Desktop**: Electron, .NET
- **Data**: Jupyter, R, MATLAB
- **DevOps**: Docker, Kubernetes, CI/CD
- **And many more...**

## 🔧 Configuration

### API Keys Setup
The setup wizard will guide you through configuring:

1. **OpenAI API Key** (for ChatGPT)
2. **Anthropic API Key** (for Claude)  
3. **Google AI API Key** (for Gemini)

### Environment Variables
You can also set environment variables:
```bash
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export GOOGLE_AI_API_KEY="your-key"
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [npm Package](https://www.npmjs.com/package/@johnolven/asis-coder)
- [GitHub Repository](https://github.com/johnolven/asis-coder)
- [Issues & Support](https://github.com/johnolven/asis-coder/issues)

## 🙏 Acknowledgments

Built with ❤️ for developers who want to enhance their coding workflow with AI assistance.

---

**Made with 🤖 AI assistance** - Asis-coder is itself built using AI-powered development!
