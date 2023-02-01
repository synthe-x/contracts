# Synths (Synthetic assets)

## States

1. Enabled

- `synths[_synth]` is `true`

- `_synthsList` includes `_synth`

- Can mint/burn this synth

- Will contribute to global pool debt

2. Disabled

- `synths[_synth]` is `false`

- `_synthsList` includes `_synth`

- Cannot be minted and swapped(to)

- Can swap to another synth or burn this synth to repay debt

- Will still contribute to global pool debt

Process:
Could be disabled by governance or l2Admin. Could be re-enabled through governance.

3. Removed

- `synths[_synth]` is `false`

- `_synthsList` does not include `_synth`

- Will not contribute to global and user pool debt
