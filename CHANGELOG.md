## [0.1.8]
- Implements Abort method

## [0.1.7]
- Fix a bug that made `FrameReceiver` read old reader events, making the lib stop working in some scenarios.

## [0.1.6]
- Make the notifications stream subscribable many times (broadcast stream);

## [0.1.5]
- Bug fixes
- Make TLV raw data visible
- Locking mechanism to avoid race conditions
- Command `removeCard`
- Command `finishChip`

## [0.1.4] - Go on Chip
Implement command `goOnChip`

## [0.1.3] - Get Card
Implements commands `getCard` and `resumeGetCard`

## [0.1.2] - Features
- Blocking Command infrastructure
- Command `getKey`
- Command `open`
- Command `close`

## [0.1.1] - General improvements
- Pinpad now requires an `Stream<int>` instead of `Stream<ReaderEvent>`
- Documentation fixes

## [0.1.0] - Initial implementation

## Release Notes
- Basic communication
  - Retries
- Command `display`
- Command `getInfo00` _(for general information)_ 
- Command `tableLoadInit`
- Command `tableLoadRec`
- Command `tableLoadEnd`
- Command `getTimestamp`