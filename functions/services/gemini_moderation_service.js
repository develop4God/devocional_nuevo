// functions/services/gemini_moderation_service.js
// Gemini-based content moderation for the Prayer Wall.
// Evaluates prayer text in its original language — never translates first.

"use strict";

const {IModerationService} = require("./i_moderation_service");

class GeminiModerationService extends IModerationService {
  /**
   * @param {Object} opts
   * @param {Function} opts.fetchFn  - Fetch function (injectable for testing).
   * @param {string}   opts.apiKey   - Gemini API key.
   * @param {string}   [opts.model]  - Gemini model ID (default: gemini-2.0-flash).
   */
  constructor({fetchFn, apiKey, model = "gemini-2.0-flash"}) {
    super();
    this._fetch = fetchFn;
    this._apiKey = apiKey;
    this._model = model;
  }

  async moderate(text, language) {
    const prompt = this._buildPrompt(text, language);

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${this._model}:generateContent?key=${this._apiKey}`;

    const response = await this._fetch(url, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        contents: [{parts: [{text: prompt}]}],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 256,
        },
      }),
    });

    if (!response.ok) {
      const status = response.status;
      if (status === 429) throw new Error("RATE_LIMIT");
      throw new Error(`Gemini moderation failed with status ${status}`);
    }

    const json = await response.json();
    const rawOutput = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    return this._parseResponse(rawOutput);
  }

  _buildPrompt(text, language) {
    return `You are moderating a Christian prayer app used globally by people of faith.
The prayer is written in: ${language}

CRITICAL: Evaluate in the ORIGINAL language. Do not translate first.
Faith communities openly discuss: illness, addiction, grief, family struggles,
financial hardship, spiritual doubt. These are ALWAYS appropriate.

Prayer request:
"${text}"

Respond ONLY in JSON — no preamble, no markdown:
{
  "approved": true/false,
  "confidence": 0.0-1.0,
  "flag": "none|spam|hate|sexual|self_harm",
  "reason": "brief internal reason if not approved",
  "is_pastoral": true/false
}

Rules:
- approved=true: genuine prayer requests about any life struggle
- flag="self_harm": user seems in crisis → set is_pastoral=true, approved=false
- flag="hate": targets a group with hatred → approved=false
- flag="spam": promotional, nonsense, or test content → approved=false
- flag="sexual": explicit sexual content → approved=false
- When in doubt, APPROVE — err on the side of grace`;
  }

  _parseResponse(rawOutput) {
    try {
      // Strip markdown code fences if present
      const cleaned = rawOutput.replace(/```json?\n?/gi, "").replace(/```/g, "").trim();
      const parsed = JSON.parse(cleaned);
      return {
        approved: Boolean(parsed.approved),
        confidence: Number(parsed.confidence ?? 0.5),
        flag: parsed.flag ?? "none",
        reason: parsed.reason ?? "",
        isPastoral: Boolean(parsed.is_pastoral),
      };
    } catch (e) {
      // EC-012: Gemini returns malformed JSON → route to needs_review
      return {
        approved: false,
        confidence: 0.0,
        flag: "none",
        reason: `Parse error: ${e.message}`,
        isPastoral: false,
      };
    }
  }
}

module.exports = {GeminiModerationService};
