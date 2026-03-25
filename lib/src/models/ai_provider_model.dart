/// AI провайдеры
enum AIProvider {
  openai,
  gemini,
  openRouter,
  huggingFace,
  claude,
}

/// Модели для каждого провайдера
class AIModels {
  static const Map<AIProvider, List<String>> models = {
    AIProvider.openai: [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
      'gpt-4',
      'gpt-3.5-turbo',
    ],
    AIProvider.gemini: [
      'gemini-2.0-flash-exp',
      'gemini-1.5-pro',
      'gemini-1.5-flash',
      'gemini-pro',
    ],
    AIProvider.openRouter: [
      'openai/gpt-4o',
      'openai/gpt-4-turbo',
      'anthropic/claude-3.5-sonnet',
      'anthropic/claude-3-opus',
      'google/gemini-pro',
      'meta-llama/llama-3.1-70b-instruct',
    ],
    AIProvider.huggingFace: [
      'meta-llama/Meta-Llama-3.1-8B-Instruct',
      'mistralai/Mistral-7B-Instruct-v0.2',
      'google/gemma-7b-it',
    ],
    AIProvider.claude: [
      'claude-3-5-sonnet-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ],
  };

  static String getDefaultModel(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'gpt-3.5-turbo';
      case AIProvider.gemini:
        return 'gemini-1.5-flash';
      case AIProvider.openRouter:
        return 'openai/gpt-4o';
      case AIProvider.huggingFace:
        return 'meta-llama/Meta-Llama-3.1-8B-Instruct';
      case AIProvider.claude:
        return 'claude-3-5-sonnet-20241022';
    }
  }

  static String getProviderName(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.gemini:
        return 'Google Gemini';
      case AIProvider.openRouter:
        return 'OpenRouter';
      case AIProvider.huggingFace:
        return 'Hugging Face';
      case AIProvider.claude:
        return 'Anthropic Claude';
    }
  }

  static String getProviderDescription(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'GPT-4, GPT-3.5 и другие модели OpenAI';
      case AIProvider.gemini:
        return 'Модели Google Gemini';
      case AIProvider.openRouter:
        return 'Универсальный роутер для разных моделей';
      case AIProvider.huggingFace:
        return 'Открытые модели от Hugging Face';
      case AIProvider.claude:
        return 'Модели Anthropic Claude';
    }
  }
}

