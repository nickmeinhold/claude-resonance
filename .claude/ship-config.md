# Ship config — claude-resonance

## CI Settings
ci: dart   # pure Dart package (NOT flutter, despite pubspec.yaml); needs build_runner

## Test Settings
test-command: dart test
coverage-threshold: none   # dart test has no built-in threshold gate

## Deploy
deploy-workflow: none      # library/experiment repo — no deploy pipeline
verification-mode: skip-no-runtime   # no live surface; State 2 is terminal
