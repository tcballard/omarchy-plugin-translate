import importlib.util
import io
import json
from pathlib import Path
import unittest
from urllib.parse import parse_qs, urlsplit

spec = importlib.util.spec_from_file_location('translate', Path(__file__).resolve().parents[1] / 'translate.py')
t = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t)

class TranslationTests(unittest.TestCase):
    def test_segments(self):
        body = json.dumps([[['Hello.','Bonjour.'],[' How are you?',' Comment allez-vous ?']],None,'fr']).encode()
        self.assertEqual(t.parse_response(body), {'ok':True,'text':'Hello. How are you?','detected':'fr'})

    def test_bad_responses(self):
        for data in (b'{}', b'null', b'[]', b'<html>Error</html>', b'[[[]]]', b'x'*(t.MAX_RESPONSE+1)):
            with self.subTest(data=data[:30]), self.assertRaises(ValueError):
                t.parse_response(data)

    def test_input_boundary(self):
        for data in (None, [], {}, {'text':'x'*5001}, {'text':'hello','target':'auto'}, {'text':'x','source':'en&bad=1'}):
            with self.subTest(data=str(data)[:30]), self.assertRaises(ValueError):
                t.validate(data)

    def test_text_is_url_data(self):
        text='Bonjour 世界 & " $(touch /tmp/no)\n<script>'
        def opener(request, timeout):
            self.assertEqual(parse_qs(urlsplit(request.full_url).query)['q'], [text])
            self.assertEqual(urlsplit(request.full_url).hostname, 'translate.googleapis.com')
            return io.BytesIO(b'[[["Hello","Bonjour"]],null,"fr"]')
        self.assertEqual(t.translate({'text':text},opener)['text'],'Hello')

if __name__ == '__main__':
    unittest.main()
