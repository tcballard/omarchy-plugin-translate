# Bundled language model

`eld-l60.json.gz` is a deterministic gzip/JSON conversion of `ngrams_data`
from `eld/resources/ngrams/ngramsL60.py` in
[nitotm/efficient-language-detector-py](https://github.com/nitotm/efficient-language-detector-py/tree/455280c2e4b3e2102f18191015ad8c48e4b7ec12),
revision `455280c2e4b3e2102f18191015ad8c48e4b7ec12`, version 1.0.8.

Copyright 2023 Nito T.M., Apache-2.0. See `licenses/eld-Apache-2.0.txt`.
The upstream project describes this Python implementation as no longer maintained.
We pin and bundle the data and adapted scoring code; there is no runtime updater.

Only `languages` and `ngrams` are retained. Byte keys become lowercase hex;
integer language keys become JSON string keys. Frequencies are unchanged.
Serialization uses `json.dumps(data, separators=(',', ':')).encode()` and
`gzip.compress(raw, mtime=0)`. The original Python assignment is parsed using
`ast.literal_eval`, not executed. No external package is needed at runtime.

`detection.py` adapts the Apache-licensed ngram extraction and scoring algorithm
with stdlib Unicode tokenization and conservative score separation. It is only
used for short, unchanged, low-confidence provider responses in automatic mode.
It is not a guarantee of accurate language detection. Ambiguous results prompt
the user to choose a language. Manual source choices are never overridden.
