// sheets.jsx — bottom sheets: group picker, item editor, invite, paywall
const { useState: useStateSh, useEffect: useEffectSh } = React;

// ── Group picker ─────────────────────────────────────────────
function GroupPickerSheet({ open, onClose, t, groups, members, currentId, plan, onPick, onAddGroup }) {
  return (
    <BottomSheet open={open} onClose={onClose} t={t} maxH="80%">
      <div style={{ fontSize: 21, fontWeight: 700, color: t.text, padding: '4px 4px 14px' }}>グループ</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {groups.map(g => {
          const on = g.id === currentId;
          return (
            <Press key={g.id} onClick={() => { onPick(g.id); onClose(); }} style={{
              display: 'flex', alignItems: 'center', gap: 13, padding: '13px 15px', borderRadius: t.rCard,
              background: on ? t.soft : t.fieldBg,
              border: on ? `1.5px solid ${t.primary}` : '1.5px solid transparent',
            }}>
              <div style={{ width: 44, height: 44, borderRadius: 13, background: t.surface, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, boxShadow: t.shadow }}>{g.emoji}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 16.5, fontWeight: 600, color: t.text }}>{g.name}</div>
                <div style={{ fontSize: 13, color: t.textSec, marginTop: 1 }}>{g.lists.length}個のリスト ・ {g.members.length}人</div>
              </div>
              <AvatarStack ids={g.members} members={members} size={26} bg={on ? t.soft : t.fieldBg} />
              {on && <div style={{ marginLeft: 4 }}><Icon name="check" size={20} color={t.primary} sw={2.6} /></div>}
            </Press>
          );
        })}
      </div>
      <Press onClick={() => { onClose(); onAddGroup(); }} style={{
        marginTop: 12, height: 52, borderRadius: t.rCard, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        border: `1.5px dashed ${t.textTer}`, color: t.textSec, fontSize: 15.5, fontWeight: 600,
      }}>
        <Icon name="plus" size={19} color={t.textSec} sw={2.2} /> 新しいグループ
        {plan !== 'pro' && <Icon name="crown" size={16} color={t.softText} sw={1.9} style={{ marginLeft: 2 }} />}
      </Press>
    </BottomSheet>
  );
}

// ── Item editor ──────────────────────────────────────────────
function EditItemSheet({ open, onClose, t, item, members, color, onSave, onDelete }) {
  const [draft, setDraft] = useStateSh(item);
  useEffectSh(() => { if (item) setDraft({ ...item }); }, [item && item.id, open]);
  if (!draft) return null;
  const set = (k, v) => setDraft(d => ({ ...d, [k]: v }));
  const field = { width: '100%', border: 'none', outline: 'none', background: 'transparent', fontSize: 17, color: t.text, fontFamily: 'inherit' };

  return (
    <BottomSheet open={open} onClose={onClose} t={t} maxH="90%">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 0 16px' }}>
        <Press onClick={onClose} style={{ fontSize: 16, color: t.textSec, fontWeight: 500 }}>キャンセル</Press>
        <div style={{ fontSize: 17, fontWeight: 700, color: t.text }}>商品を編集</div>
        <Press onClick={() => { onSave(draft); onClose(); }} style={{ fontSize: 16, color: t.primary, fontWeight: 700 }}>保存</Press>
      </div>

      <div style={{ background: t.fieldBg, borderRadius: t.rField, padding: '14px 16px', marginBottom: 10 }}>
        <input value={draft.name} onChange={e => set('name', e.target.value)} placeholder="商品名" style={{ ...field, fontWeight: 600 }} />
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 12, background: t.fieldBg, borderRadius: t.rField, padding: '8px 8px 8px 16px', marginBottom: 18 }}>
        <div style={{ fontSize: 15, color: t.textSec, fontWeight: 500 }}>数量</div>
        <input value={draft.qty} onChange={e => set('qty', e.target.value)} placeholder="例: 2本 / 300g" style={{ ...field, textAlign: 'right', fontSize: 16 }} />
      </div>

      <SectionLabel t={t}>カテゴリ</SectionLabel>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 20 }}>
        {CATEGORY_LIST.map(c => {
          const on = c === draft.cat;
          return (
            <Press key={c} onClick={() => set('cat', c)} scale={0.94} style={{
              display: 'flex', alignItems: 'center', gap: 6, padding: '8px 13px', borderRadius: 999,
              fontSize: 14, fontWeight: on ? 600 : 500,
              background: on ? CATEGORIES[c] : t.fieldBg, color: on ? '#fff' : t.textSec,
            }}>
              {!on && <CatDot cat={c} size={8} />}{c}
            </Press>
          );
        })}
      </div>

      <SectionLabel t={t}>メモ</SectionLabel>
      <div style={{ background: t.fieldBg, borderRadius: t.rField, padding: '13px 16px', marginBottom: 22 }}>
        <textarea value={draft.memo} onChange={e => set('memo', e.target.value)} placeholder="ブランド指定や注意点など" rows={2}
          style={{ ...field, resize: 'none', lineHeight: 1.5 }} />
      </div>

      <Press onClick={() => { onDelete(draft.id); onClose(); }} style={{
        height: 50, borderRadius: t.rBtn, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        background: t.dark ? 'rgba(217,105,95,0.16)' : '#FBEAE8', color: '#D9695F', fontSize: 16, fontWeight: 600,
      }}>
        <Icon name="trash" size={19} color="#D9695F" sw={2} /> 削除
      </Press>
    </BottomSheet>
  );
}

// ── Invite ───────────────────────────────────────────────────
function InviteSheet({ open, onClose, t, group, members, plan, onUpgrade }) {
  const [copied, setCopied] = useStateSh(false);
  useEffectSh(() => { if (!open) setCopied(false); }, [open]);
  const code = 'FAMI-' + group.id.slice(-4).toUpperCase() + '-7K2';
  const atCap = plan !== 'pro' && group.members.length >= 3;

  return (
    <BottomSheet open={open} onClose={onClose} t={t} maxH="86%">
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '6px 0 4px' }}>
        <div style={{ width: 60, height: 60, borderRadius: 18, background: t.soft, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 14 }}>
          <Icon name="people" size={32} color={t.primary} sw={1.9} />
        </div>
        <div style={{ fontSize: 21, fontWeight: 700, color: t.text }}>「{group.name}」に招待</div>
        <div style={{ fontSize: 14, color: t.textSec, marginTop: 6, textAlign: 'center', lineHeight: 1.5 }}>
          リンクを送るだけ。アプリ未インストールの方は<br />App Store に自動で案内されます。
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', margin: '22px 0' }}>
        <div style={{ width: 150, height: 150, background: '#fff', borderRadius: t.rCard, padding: 14, boxShadow: t.shadow, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="qr" size={118} color="#16201B" sw={1.4} />
        </div>
        <div style={{ marginTop: 14, fontSize: 18, fontWeight: 700, letterSpacing: 2, color: t.text, fontFamily: 'ui-monospace, monospace' }}>{code}</div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 10, background: t.fieldBg, borderRadius: t.rField, padding: '12px 14px', marginBottom: 12 }}>
        <Icon name="link" size={19} color={t.textSec} sw={2} />
        <div style={{ flex: 1, fontSize: 14, color: t.textSec, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontFamily: 'ui-monospace, monospace' }}>myfami.app/j/{code.toLowerCase()}</div>
        <Press onClick={() => setCopied(true)} scale={0.9} style={{ display: 'flex', alignItems: 'center', gap: 4, color: t.primary, fontSize: 14, fontWeight: 600 }}>
          <Icon name={copied ? 'check' : 'copy'} size={17} color={t.primary} sw={2.1} />{copied ? 'コピー済' : 'コピー'}
        </Press>
      </div>

      {atCap ? (
        <React.Fragment>
          <div style={{ textAlign: 'center', fontSize: 13, color: t.textSec, margin: '4px 0 12px' }}>無料プランは3人まで。さらに招待するには Pro が必要です。</div>
          <PrimaryButton t={t} icon="crown" onClick={() => { onClose(); onUpgrade(); }}>Pro にアップグレード</PrimaryButton>
        </React.Fragment>
      ) : (
        <PrimaryButton t={t} icon="share" onClick={onClose}>リンクを共有</PrimaryButton>
      )}
    </BottomSheet>
  );
}

// ── Paywall ──────────────────────────────────────────────────
function PaywallSheet({ open, onClose, t, onPurchase }) {
  const feats = [
    ['people', 'グループ無制限', '家族・職場・サークル…用途ごとに'],
    ['list', 'リスト＆メンバー無制限', '何人でも、いくつでも共有'],
    ['bell', '通知とリマインダー', '買い忘れをしっかり防ぐ'],
    ['clock', '履歴と統計', 'よく買う物をすぐ呼び出し'],
  ];
  return (
    <BottomSheet open={open} onClose={onClose} t={t} maxH="92%">
      <Press onClick={onClose} style={{ position: 'absolute', top: 14, right: 18, zIndex: 2, width: 30, height: 30, borderRadius: 30, background: t.fieldBg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icon name="x" size={17} color={t.textSec} sw={2.3} />
      </Press>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '14px 0 6px' }}>
        <div style={{ width: 70, height: 70, borderRadius: 20, background: `linear-gradient(135deg, ${t.primary}, ${t.primaryPress})`, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16, boxShadow: '0 14px 30px -10px ' + t.primary }}>
          <Icon name="crown" size={38} color="#fff" sw={1.8} />
        </div>
        <div style={{ fontSize: 25, fontWeight: 800, color: t.text, letterSpacing: 0.3 }}>MyFamiList Pro</div>
        <div style={{ fontSize: 14.5, color: t.textSec, marginTop: 6 }}>一度の購入で、ずっと無制限。</div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4, margin: '22px 0' }}>
        {feats.map(([ic, title, sub]) => (
          <div key={title} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '11px 6px' }}>
            <div style={{ width: 40, height: 40, borderRadius: 11, background: t.soft, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon name={ic} size={21} color={t.primary} sw={2} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15.5, fontWeight: 600, color: t.text }}>{title}</div>
              <div style={{ fontSize: 13, color: t.textSec, marginTop: 1 }}>{sub}</div>
            </div>
            <Icon name="check" size={20} color={t.primary} sw={2.6} />
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 8, marginBottom: 16 }}>
        <div style={{ fontSize: 32, fontWeight: 800, color: t.text }}>¥1,200</div>
        <div style={{ fontSize: 14.5, color: t.textSec }}>買い切り ・ 追加課金なし</div>
      </div>

      <PrimaryButton t={t} onClick={onPurchase}>購入して無制限にする</PrimaryButton>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 20, marginTop: 14 }}>
        <span style={{ fontSize: 13, color: t.textSec }}>購入を復元</span>
        <span style={{ fontSize: 13, color: t.textSec }}>利用規約</span>
      </div>
    </BottomSheet>
  );
}

Object.assign(window, { GroupPickerSheet, EditItemSheet, InviteSheet, PaywallSheet });
