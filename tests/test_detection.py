import io
import json
from pathlib import Path
import sys
import unittest
from urllib.parse import parse_qs, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from detection import detect_short
from translate import translate


def response(text, source, confidence):
    return io.BytesIO(json.dumps([[[text, 'original']], None, source, None, None, None, confidence]).encode())


class DetectionTests(unittest.TestCase):
    def test_local_candidate_ignores_case_and_punctuation(self):
        for text in ['Bonjour', 'bonjour', 'BONJOUR!', ' Bonjour ']:
            self.assertEqual(detect_short(text), 'fr', text)

    def test_ambiguous_and_unsupported_inputs_abstain(self):
        for text in ['Merci', 'Salut', 'Hi', '123', '???', '', 'long text ' * 10]:
            self.assertIsNone(detect_short(text), text)

    def test_uncertain_bonjour_retries_with_french_and_original_text(self):
        sources = []
        def opener(request, timeout):
            query = parse_qs(urlsplit(request.full_url).query)
            sources.append(query['sl'][0])
            self.assertEqual(query['q'], ['Bonjour'])
            self.assertEqual(query['tl'], ['en'])
            return response('Bonjour', 'en', 0.7584857) if len(sources) == 1 else response('Hello', 'fr', 1)
        result = translate({'text':'Bonjour', 'source':'auto', 'target':'en'}, opener)
        self.assertEqual(sources, ['auto', 'fr'])
        self.assertEqual((result['text'], result['detected']), ('Hello', 'fr'))

    def test_confident_english_is_not_overridden_by_local_guess(self):
        calls = []
        def opener(request, timeout):
            calls.append(request)
            return response('Hello', 'en', 1)
        result = translate({'text':'Hello', 'source':'auto', 'target':'en'}, opener)
        self.assertEqual(result['detected'], 'en')
        self.assertEqual(len(calls), 1)

    def test_explicit_source_never_overridden(self):
        calls = []
        def opener(request, timeout):
            calls.append(request)
            return response('Bonjour', 'en', 0.7)
        translate({'text':'Bonjour', 'source':'en', 'target':'en'}, opener)
        self.assertEqual(len(calls), 1)

    def test_ambiguous_noop_prompts_for_language(self):
        result = translate({'text':'Merci'}, lambda request, timeout: response('Merci', 'en', 0.695))
        self.assertFalse(result['ok'])
        self.assertIn('Choose a source language', result['error'])

    def test_successful_translation_does_not_retry(self):
        calls = []
        def opener(request, timeout):
            calls.append(request)
            return response('Hello', 'es', 0.7)
        result = translate({'text':'Hola'}, opener)
        self.assertTrue(result['ok'])
        self.assertEqual(len(calls), 1)
