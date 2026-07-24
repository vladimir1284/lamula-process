Extracted from NOAA ROC's `libL2_decoder.zip` (`cpc102/tsk023`), keeping only
what has reference value for our parser and dropping the ROC-internal
build/QA machinery (all `.mak`/`Makefile`s, the three
`validate_ldm_files_*.script` shell scripts, `metadump.c`,
`validate_ldm_file.c`) — none of that runs outside NOAA's own ORPG SDK
environment and none of it documents wire-format structure.

Kept:

- `README.txt` — original README, describes the ROC SWE LAN validation
  scripts (context only, we don't run them).
- `libl2.c` — the actual decoder logic and inline struct documentation.
  Depends on external ORPG SDK headers not included here, so it does not
  compile standalone — kept purely as a byte-layout / logic reference.
- `parse_ldm_file.c` — demonstrates driving `libl2.c` against a real LDM
  file end to end; useful if we ever need to resolve the unexplained
  type-0 padding run noted in `docs/formatos.md`.
- `testlibl2.c` — small API usage demo.
- `libL2.3.man` — man page for the library's public API.
