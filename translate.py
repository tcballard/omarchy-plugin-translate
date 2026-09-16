#!/usr/bin/env python3
"""One bounded translation or explicit clipboard read; JSON in/out, no UI."""
import json
import re
import signal
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

MAX_TEXT = 5000
MAX_BYTES = 20000
MAX_RESPONSE = 131072
ENDPOINT = 'https://translate.googleapis.com/translate_a/single'


def validate(data):
    if not isinstance(data, dict):
        raise ValueError('Invalid translation request.')
    text = data.get('text', '')
    source, target = data.get('source', 'auto'), data.get('target', 'en')
    if not isinstance(text, str) or not text.strip() or len(text) > MAX_TEXT:
        raise ValueError('Enter between 1 and 5,000 characters.')
    for code in (source, target):
        if not isinstance(code, str) or not re.fullmatch(r'[a-zA-Z-]{2,12}', code):
            raise ValueError('Choose a valid language.')
    if target == 'auto':
        raise ValueError('Choose a target language.')
    return text, source, target


def parse_response(body):
    if len(body) > MAX_RESPONSE:
        raise ValueError('The translation response was too large.')
    try:
        data = json.loads(body)
        pieces = data[0]
        if not isinstance(pieces, list):
            raise ValueError()
        result = ''.join(p[0] for p in pieces if isinstance(p, list) and p and isinstance(p[0], str))
        if not result or len(result) > MAX_BYTES:
            raise ValueError()
        detected = data[2] if len(data) > 2 and isinstance(data[2], str) and re.fullmatch(r'[a-zA-Z-]{2,12}', data[2]) else ''
        response = {'ok': True, 'text': result, 'detected': detected}
        if len(data) > 6 and type(data[6]) in (int, float) and 0 <= data[6] <= 1:
            response['confidence'] = data[6]
        return response
    except (ValueError, TypeError, IndexError, KeyError):
        raise ValueError('Google returned an unexpected response. Try again later.') from None


def translate(data, opener=urllib.request.urlopen):
    text, source, target = validate(data)
    result = request_translation(text, source, target, opener)
    if (source == 'auto' and result['detected'] == target
            and result['text'].strip().casefold() == text.strip().casefold()
            and result.get('confidence', 1) < 0.9):
        from detection import detect_short
        candidate = detect_short(text)
        if candidate and candidate != target:
            # One retry, to the same service, preserving the user's exact text.
            # The existing process-wide deadline also covers this request.
            result = request_translation(text, candidate, target, opener)
            result['detected'] = candidate
        elif candidate is None:
            return {'ok': False, 'error': 'Language detection is uncertain for this text. Choose a source language and translate again.'}
    return result


def request_translation(text, source, target, opener):
    query = urllib.parse.urlencode({'client': 'dict-chrome-ex', 'sl': source, 'tl': target, 'dt': 't', 'q': text})
    request = urllib.request.Request(ENDPOINT + '?' + query, headers={'User-Agent': 'BarTranslate-Omarchy/0.1', 'Accept': 'application/json'})
    with opener(request, timeout=12) as response:
        return parse_response(response.read(MAX_RESPONSE + 1))


def clipboard():
    with subprocess.Popen(['/usr/bin/wl-paste', '--no-newline', '--type', 'text'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as proc:
        try:
            raw = proc.stdout.read(MAX_BYTES + 1)
            if len(raw) > MAX_BYTES:
                raise ValueError('Clipboard text is too long. Use up to 5,000 characters.')
            if proc.wait(timeout=2) != 0:
                raise ValueError('The clipboard has no text.')
            text = raw.decode('utf-8')
            if not text.strip():
                raise ValueError('The clipboard has no text.')
            if len(text) > MAX_TEXT:
                raise ValueError('Clipboard text is too long. Use up to 5,000 characters.')
            return {'ok': True, 'text': text}
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()


def expired(*_):
    raise TimeoutError()


def main():
    signal.signal(signal.SIGALRM, expired)
    signal.alarm(16)
    try:
        if sys.argv[1:] == ['--clipboard']:
            result = clipboard()
        else:
            raw = sys.stdin.buffer.readline(65537)
            if len(raw) > 65536:
                raise ValueError('The request is too large.')
            result = translate(json.loads(raw))
    except urllib.error.HTTPError as error:
        message = 'Google is rate limiting requests. Please try again later.' if error.code == 429 else 'The translation service is unavailable. Try again later.'
        result = {'ok': False, 'error': message}
    except (urllib.error.URLError, TimeoutError, OSError, subprocess.TimeoutExpired):
        result = {'ok': False, 'error': 'Could not connect or read the clipboard. Check your connection and try again.'}
    except (ValueError, UnicodeError) as error:
        result = {'ok': False, 'error': str(error)[:160] if not isinstance(error, json.JSONDecodeError) else 'Invalid translation data.'}
    finally:
        signal.alarm(0)
    print(json.dumps(result, ensure_ascii=False))


if __name__ == '__main__':
    main()
