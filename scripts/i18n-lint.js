const fs = require('fs');
const path = require('path');
const LANGS = ['es', 'en', 'fr', 'pt', 'ja'];
const baseLang = 'en';
const base = JSON.parse(fs.readFileSync(path.join('i18n', `${baseLang}.json`), 'utf-8'));

let error = false;

function compareKeys(ref, target, lang, pathStr = '') {
  for (const key in ref) {
    if (!(key in target)) {
      console.error(`Missing key in ${lang}: ${pathStr}${key}`);
      error = true;
    }
    if (typeof ref[key] === 'object' && ref[key] !== null) {
      compareKeys(ref[key], target[key] || {}, lang, `${pathStr}${key}.`);
    }
  }
  for (const key in target) {
    if (!(key in ref)) {
      console.error(`Extra key in ${lang}: ${pathStr}${key}`);
      error = true;
    }
  }
}

LANGS.forEach(lang => {
  if (lang === baseLang) return;
  const target = JSON.parse(fs.readFileSync(path.join('i18n', `${lang}.json`), 'utf-8'));
  compareKeys(base, target, lang);
});

if (error) {
  process.exit(1);
} else {
  console.log('✅ All i18n files are homologated!');
}
