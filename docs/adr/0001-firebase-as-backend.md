# ADR 0001: Firebase をバックエンドとして採用する

## Status
Accepted

## Context
外部API連携の初挑戦。認証・リアルタイム同期・プッシュ通知・オフラインキャッシュがすべて必要。自前サーバーは学習コストが高すぎる。

## Decision
Firebase（Authentication・Firestore・Cloud Messaging）を採用する。

## Consequences
- 認証（Apple ID・Google・メール）、リアルタイム同期、オフラインキャッシュ、プッシュ通知をFirebase一つで賄える
- Googleへのベンダー依存が生じる
- 無料枠を超えた場合は課金が発生する
