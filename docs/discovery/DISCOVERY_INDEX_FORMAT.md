# Discovery Index Structure - REQUIRED FORMAT

## Problem Found

The current `index.json` URL points to a **single study file** instead of an **index/catalog file**.

Current wrong file at:

```
https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/discovery/index.json
```

Contains: Single study `logos_creation_001` with full content (9134 bytes)

## Required File Structure

You need to create a **proper index.json** file with this structure:

### File: `discovery/index.json`

```json
{
  "studies": [
    {
      "id": "morning_star_001",
      "version": "1.2",
      "emoji": "🌟",
      "files": {
        "es": "morning_star_es_001.json",
        "en": "morning_star_en_001.json"
      },
      "titles": {
        "es": "Estrella de la Mañana",
        "en": "The Herald of Light"
      },
      "subtitles": {
        "es": "El testimonio más poderoso sobre la identidad de Jesús",
        "en": "The eternal connection between creation, prophecy, and your heart"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 6
      }
    },
    {
      "id": "logos_creation_001",
      "version": "1.0",
      "emoji": "📖",
      "files": {
        "es": "logos_creation_es_001.json",
        "en": "logos_creation_en_001.json"
      },
      "titles": {
        "es": "En el Principio era el Verbo",
        "en": "In the Beginning was the Word"
      },
      "subtitles": {
        "es": "Cuando Juan declara que Jesús es el Logos eterno que creó todas las cosas",
        "en": "When John declares that Jesus is the eternal Logos who created all things"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 6
      }
    },
    {
      "id": "lamb_of_god_001",
      "version": "1.0",
      "emoji": "🐑",
      "files": {
        "es": "lamb_of_god_es_001.json",
        "en": "lamb_of_god_en_001.json"
      },
      "titles": {
        "es": "El Cordero de Dios",
        "en": "The Lamb of God"
      },
      "subtitles": {
        "es": "La culminación de 1,500 años de sistema sacrificial en una sola declaración",
        "en": "The culmination of 1,500 years of sacrificial system in a single declaration"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 5
      }
    },
    {
      "id": "natanael_fig_tree_001",
      "version": "1.0",
      "emoji": "🌳",
      "files": {
        "es": "natanael_fig_tree_es_001.json",
        "en": "natanael_fig_tree_en_001.json"
      },
      "titles": {
        "es": "Debajo de la Higuera",
        "en": "Under the Fig Tree"
      },
      "subtitles": {
        "es": "El encuentro donde Jesús revela que conoce tus secretos más profundos",
        "en": "The encounter where Jesus reveals He knows your deepest secrets"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 5
      }
    },
    {
      "id": "cana_wedding_001",
      "version": "1.1",
      "emoji": "🍷",
      "files": {
        "es": "cana_wedding_es_001.json",
        "en": "cana_wedding_en_001.json"
      },
      "titles": {
        "es": "Las Bodas de Caná",
        "en": "The Wedding at Cana"
      },
      "subtitles": {
        "es": "Cuando Jesús convierte lo ordinario en extraordinario",
        "en": "When Jesus turns the ordinary into extraordinary"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 5
      }
    },
    {
      "id": "born_again_001",
      "version": "1.0",
      "emoji": "🍃",
      "files": {
        "es": "born_again_es_001.json",
        "en": "born_again_en_001.json"
      },
      "titles": {
        "es": "Es Necesario Nacer de Nuevo",
        "en": "You Must Be Born Again"
      },
      "subtitles": {
        "es": "El misterio del nuevo nacimiento espiritual revelado",
        "en": "The mystery of spiritual rebirth revealed"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 6
      }
    },
    {
      "id": "temple_cleansing_001",
      "version": "1.0",
      "emoji": "🔥",
      "files": {
        "es": "temple_cleansing_es_001.json",
        "en": "temple_cleansing_en_001.json"
      },
      "titles": {
        "es": "La Purificación del Templo",
        "en": "The Cleansing of the Temple"
      },
      "subtitles": {
        "es": "Cuando Jesús declara que Él es el Templo verdadero",
        "en": "When Jesus declares that He is the true Temple"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 6
      }
    }
  ]
}
```

## File Structure in GitHub Repository

```
Devocionales-json/
└── discovery/
    ├── index.json              ← CATALOG (metadata only, ~2KB)
    ├── es/
    │   ├── morning_star_es_001.json
    │   ├── logos_creation_es_001.json
    │   ├── lamb_of_god_es_001.json
    │   ├── natanael_fig_tree_es_001.json
    │   ├── cana_wedding_es_001.json
    │   ├── born_again_es_001.json
    │   └── temple_cleansing_es_001.json
    └── en/
        ├── morning_star_en_001.json
        ├── logos_creation_en_001.json
        ├── lamb_of_god_en_001.json
        ├── natanael_fig_tree_en_001.json
        ├── cana_wedding_en_001.json
        ├── born_again_en_001.json
        └── temple_cleansing_en_001.json
```

## How It Works

### Step 1: Load Discovery List Page

1. Fetch `index.json` (small file with metadata)
2. Parse `studies` array
3. Display cards with: emoji, title, subtitle, reading minutes
4. Show all 7 studies in carousel

### Step 2: User Taps a Card

1. Fetch full study file: `discovery/es/born_again_es_001.json`
2. Load complete content with cards, questions, etc.
3. Display detailed study page

## Action Required

**Replace the current `index.json` file** in your GitHub repository with the structure above.

The file at:

```
https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/discovery/index.json
```

Should contain the metadata catalog (as shown above), NOT a full study.

Once you update the file, the app will immediately work! ✅
