// listdetail.jsx — the core list screen: items, check-off, quick add
const { useState: useStateD, useRef: useRefD, useEffect: useEffectD } = React;

function ItemRow({ item, members, t, color, onToggle, onOpen, first }) {
  const checked = item.checked;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 13,
      padding: `${t.padY}px 16px`, minHeight: t.rowH,
      borderTop: first ? 'none' : `0.5px solid ${t.hairline}`,
      transition: 'opacity .2s',
    }}>
      <Checkbox checked={checked} color={color} onClick={onToggle} t={t} size={26} />
      <Press onClick={onOpen} style={{ flex: 1, minWidth: 0, display: 'flex', alignItems: 'center', gap: 11 }}>
        <CatDot cat={item.cat} size={10} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: t.fs, fontWeight: 500, color: checked ? t.textTer : t.text,
            textDecoration: checked ? 'line-through' : 'none',
            textDecorationColor: t.textTer,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>
            {item.name}
            {item.qty && <span style={{ color: checked ? t.textTer : t.textSec, fontWeight: 500, marginLeft: 8, fontSize: t.fs - 2 }}>{item.qty}</span>}
          </div>
          {(item.memo || (!checked && item.at && item.by !== 'me')) && (
            <div style={{ fontSize: 12.5, color: t.textTer, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {item.memo ? `📝 ${item.memo}` : `${members[item.by].name}さんが追加 ・ ${item.at}`}
            </div>
          )}
        </div>
        {!checked && item.by !== 'me' && <Avatar m={members[item.by]} size={22} ring={t.surface} />}
      </Press>
    </div>
  );
}

function Composer({ t, color, onAdd }) {
  const [open, setOpen] = useStateD(false);
  const [name, setName] = useStateD('');
  const [cat, setCat] = useStateD('野菜・果物');
  const inputRef = useRefD(null);

  const submit = () => {
    const n = name.trim();
    if (!n) return;
    onAdd({ name: n, cat });
    setName('');
    requestAnimationFrame(() => inputRef.current && inputRef.current.focus());
  };

  return (
    <div style={{
      flexShrink: 0, background: t.dark ? 'rgba(20,26,23,0.86)' : 'rgba(255,255,255,0.86)',
      backdropFilter: 'blur(20px) saturate(180%)', WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: `0.5px solid ${t.hairline}`, paddingBottom: 26, paddingTop: 10, position: 'relative', zIndex: 8,
    }}>
      {open && (
        <div style={{ display: 'flex', gap: 7, overflowX: 'auto', padding: '0 16px 10px', WebkitOverflowScrolling: 'touch' }}>
          {CATEGORY_LIST.map(c => {
            const on = c === cat;
            return (
              <Press key={c} onClick={() => setCat(c)} scale={0.94} style={{
                flexShrink: 0, display: 'flex', alignItems: 'center', gap: 6, padding: '7px 12px',
                borderRadius: 999, fontSize: 13.5, fontWeight: on ? 600 : 500,
                background: on ? CATEGORIES[c] : t.fieldBg, color: on ? '#fff' : t.textSec,
              }}>
                {!on && <CatDot cat={c} size={8} />}{c}
              </Press>
            );
          })}
        </div>
      )}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '0 16px' }}>
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', gap: 9, height: 44, padding: '0 14px',
          background: t.fieldBg, borderRadius: t.rField,
        }}>
          <Icon name="plus" size={20} color={color} sw={2.3} />
          <input
            ref={inputRef} value={name}
            onChange={e => setName(e.target.value)}
            onFocus={() => setOpen(true)}
            onKeyDown={e => { if (e.key === 'Enter') submit(); }}
            placeholder="商品を追加…"
            style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontSize: 16, color: t.text, fontFamily: 'inherit', minWidth: 0,
            }}
          />
        </div>
        {open && (name.trim() ? (
          <Press onClick={submit} scale={0.92} style={{
            height: 44, padding: '0 18px', borderRadius: t.rField, background: color, color: '#fff',
            display: 'flex', alignItems: 'center', fontSize: 16, fontWeight: 600,
          }}>追加</Press>
        ) : (
          <Press onClick={() => { setOpen(false); }} scale={0.92} style={{
            height: 44, padding: '0 14px', display: 'flex', alignItems: 'center', fontSize: 16, color: t.textSec, fontWeight: 500,
          }}>閉じる</Press>
        ))}
      </div>
    </div>
  );
}

function ListDetailScreen({ t, group, list, members, onBack, onAdd, onToggle, onOpenItem, onMenu }) {
  const [showDone, setShowDone] = useStateD(true);
  const active = list.items.filter(i => !i.checked);
  const done = list.items.filter(i => i.checked);

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: t.bg }}>
      <AppHeader t={t} title={list.name} onBack={onBack}
        sub={`${group.emoji} ${group.name} ・ ${active.length}品 未購入`}
        right={
          <Press onClick={onMenu} scale={0.85} style={{ paddingBottom: 4 }}>
            <div style={{ width: 36, height: 36, borderRadius: 36, background: t.surface, boxShadow: t.shadow, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="dots" size={20} color={t.textSec} />
            </div>
          </Press>
        }
      />

      <main style={{ flex: 1, overflowY: 'auto', padding: '14px 16px 16px' }}>
        {active.length > 0 ? (
          <Card t={t}>
            {active.map((item, i) => (
              <ItemRow key={item.id} item={item} members={members} t={t} color={group.color} first={i === 0}
                onToggle={() => onToggle(item.id)} onOpen={() => onOpenItem(item.id)} />
            ))}
          </Card>
        ) : (
          <div style={{ textAlign: 'center', padding: '48px 20px', color: t.textTer }}>
            <div style={{ fontSize: 40, marginBottom: 8 }}>🛒</div>
            <div style={{ fontSize: 15, fontWeight: 500 }}>未購入の商品はありません</div>
            <div style={{ fontSize: 13.5, marginTop: 4 }}>下のバーから追加できます</div>
          </div>
        )}

        {done.length > 0 && (
          <div style={{ marginTop: 20 }}>
            <Press onClick={() => setShowDone(s => !s)} style={{ display: 'flex', alignItems: 'center', gap: 7, padding: '4px 6px 10px' }}>
              <div style={{ transform: showDone ? 'rotate(90deg)' : 'rotate(0deg)', transition: 'transform .2s' }}>
                <Icon name="chevR" size={15} color={t.textSec} sw={2.4} />
              </div>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: t.textSec }}>カゴに入れた ({done.length})</div>
            </Press>
            {showDone && (
              <Card t={t} style={{ opacity: 0.78 }}>
                {done.map((item, i) => (
                  <ItemRow key={item.id} item={item} members={members} t={t} color={group.color} first={i === 0}
                    onToggle={() => onToggle(item.id)} onOpen={() => onOpenItem(item.id)} />
                ))}
              </Card>
            )}
          </div>
        )}
      </main>

      <Composer t={t} color={group.color} onAdd={onAdd} />
    </div>
  );
}

Object.assign(window, { ListDetailScreen, ItemRow, Composer });
