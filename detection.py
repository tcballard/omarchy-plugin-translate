"""Conservative short-text fallback using ELD's L60 character model.

Scoring/ngram extraction adapted from Efficient Language Detector 1.0.8,
Copyright 2023 Nito T.M., Apache-2.0. See licenses/eld-Apache-2.0.txt.
Changes: stdlib Unicode tokenization, fixed JSON model, no mutable subsets,
short-input bound, and conservative abstention instead of always guessing.
"""
from functools import lru_cache
import gzip
import json
from pathlib import Path


@lru_cache(maxsize=1)
def model():
    with gzip.open(Path(__file__).resolve().parent / 'data/eld-l60.json.gz', 'rb') as stream:
        raw = stream.read(8_000_001)
    if len(raw) > 8_000_000:
        raise ValueError('Language model is too large.')
    data = json.loads(raw)
    return data['languages'], {bytes.fromhex(k): v for k, v in data['ngrams'].items()}


def detect_short(text):
    """Return a clear local candidate or None; never handle full documents."""
    if not isinstance(text, str) or not 3 <= len(text.strip()) <= 40:
        return None
    normalized = ' '.join(''.join(c if c.isalpha() or c in "'’`" else ' ' for c in text).split()).lower()
    grams = {}
    count = 0
    for word in normalized.encode('utf-8').split():
        length = min(len(word), 70)
        has_prefix = False
        for offset in range(0, length - 4, 3):
            gram = (b' ' if offset == 0 else b'') + word[offset:offset + 4]
            grams[gram] = grams.get(gram, 0) + 1
            count += 1
            has_prefix = True
        gram = (b'' if has_prefix else b' ') + word[length - 4 if length != 3 else 0:] + b' '
        grams[gram] = grams.get(gram, 0) + 1
        count += 1
    if not count:
        return None
    languages, ngrams = model()
    scores = {}
    for gram, occurrences in grams.items():
        matches = ngrams.get(gram, {})
        relevance = 27 if len(matches) == 1 else (16 - len(matches)) / 2 + 1 if len(matches) < 16 else 1
        frequency = occurrences / count * 13200
        for language, global_frequency in matches.items():
            score = min(frequency, global_frequency) / max(frequency, global_frequency) * relevance + 2
            scores[language] = scores.get(language, 0) + score
    ranked = sorted(((score / (len(grams) * 3.2), language) for language, score in scores.items()), reverse=True)
    if not ranked:
        return None
    best, language = ranked[0]
    runner_up = ranked[1][0] if len(ranked) > 1 else 0
    # ELD is not generally reliable on isolated words. Only permit a strong
    # separation, and only call this after Google's own uncertain no-op.
    if best < 0.5 or best - runner_up < 0.2:
        return None
    code = languages[language]
    return 'zh-CN' if code == 'zh' else code
