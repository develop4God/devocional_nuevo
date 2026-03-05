// functions/services/gemini_pii_masking_service.js
// Gemini-based PII masking service.
// Masks names, phone numbers, emails, addresses, and ID numbers
// while preserving spiritual content and emotional language.

"use strict";

const {IPiiMaskingService} = require("./i_pii_masking_service");

const SUPPORTED_LANGUAGES = ["en", "es", "pt", "fr", "hi", "ja", "zh"];

class GeminiPiiMaskingService extends IPiiMaskingService {
  /**
   * @param {Object} opts
   * @param {Function} opts.fetchFn   - Fetch function (injectable for testing).
   * @param {string}   opts.apiKey    - Gemini API key.
   * @param {string}   [opts.model]   - Gemini model ID (default: gemini-2.0-flash).
   */
  constructor({fetchFn, apiKey, model = "gemini-2.0-flash"}) {
    super();
    this._fetch = fetchFn;
    this._apiKey = apiKey;
    this._model = model;
  }

  async mask(text, language) {
    if (!text || text.trim() === "") {
      return {maskedText: text, wasModified: false};
    }

    const lang = SUPPORTED_LANGUAGES.includes(language) ? language : "en";
    const prompt = this._buildPrompt(text, lang);

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this._model}:generateContent?key=${this._apiKey}`;

    const response = await this._fetch(url, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        contents: [{parts: [{text: prompt}]}],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 1024,
        },
      }),
    });

    if (!response.ok) {
      const status = response.status;
      if (status === 429) throw new Error("RATE_LIMIT");
      throw new Error(`Gemini PII masking failed with status ${status}`);
    }

    const json = await response.json();
    const rawOutput = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    return this._parseResponse(rawOutput, text);
  }

  _buildPrompt(text, language) {
    return `You are a privacy protection assistant for a Christian prayer app used globally.
The prayer is written in: ${language}

TASK: Remove personally identifiable information (PII) from the following prayer text.

Replace with these placeholders:
- Person names → [name]
- Phone numbers → [phone]
- Email addresses → [email]
- Physical addresses (street, city, ZIP) → [address]
- ID numbers (passport, SSN, national ID) → [id]

PRESERVE exactly as-is:
- Spiritual content, Bible verses, religious expressions
- Emotional and descriptive language
- Cultural phrases and idioms
- Relationship references (my mother, my son, my pastor) — only mask if a real name is given

Prayer text:
"${text}"

Respond with ONLY the masked text. No preamble, no quotes, no explanation.
If no PII is found, return the original text unchanged.`;
  }

  _parseResponse(rawOutput, originalText) {
    const maskedText = rawOutput.trim();
    if (!maskedText) {
      return {maskedText: originalText, wasModified: false};
    }
    const wasModified = maskedText !== originalText;
    return {maskedText, wasModified};
  }
}

module.exports = {GeminiPiiMaskingService};
