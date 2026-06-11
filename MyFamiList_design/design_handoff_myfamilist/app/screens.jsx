// screens.jsx — Login, Lists overview, Members, Settings + chrome
const { useState: useStateS, useEffect: useEffectS, useRef: useRefS } = React;

// ── App header (clears status bar / island) ──────────────────
function AppHeader({ t, title, onBack, right, top }) {
  return (
    <div style={{ paddingTop: 54, paddingLeft: 20, paddingRight: 20, paddingBottom: 6, background: t.bg, position: 'relative', zIndex: 6 }}>
      {top}
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12, minHeight: 44 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, minWidth: 0 }}>
          {onBack && (
            <Press onClick={onBack} scale={0.8} style={{ marginLeft: -8, marginRight: 2, padding: 4 }}>
              <Icon name="chevL" size={28} color={t.primary} sw={2.4} />
            </Press>
          )}
          <div style={{ fontSize: 33, fontWeight: 700, color: t.text, letterSpacing: 0.2, lineHeight: 1.05, fontFeatureSettings: '"palt"' }}>{title}</div>
        </div>
        {right}
      </div>
    </div>
  );
}

function Toast({ msg, members, t, onDone }) {
  const [show, setShow] = useStateS(false);
  useEffectS(() => {
    requestAnimationFrame(() => setShow(true));
    const a = setTimeout(() => setShow(false), 3600);
    const b = setTimeout(onDone, 4000);
    return () => { clearTimeout(a); clearTimeout(b); };
  }, []);
  if (!msg) return null;
  return (
    <div style={{
      position: 'absolute', top: 58, left: 16, right: 16, zIndex: 120,
      transform: show ? 'translateY(0)' : 'translateY(-130%)', opacity: show ? 1 : 0,
      transition: 'transform .42s cubic-bezier(.2,.9,.3,1.1), opacity .3s',
      display: 'flex', alignItems: 'center', gap: 11,
      background: t.dark ? 'rgba(34,42,38,0.92)' : 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(16px) saturate(180%)', WebkitBackdropFilter: 'blur(16px) saturate(180%)',
      borderRadius: 16, padding: '11px 14px',
      boxShadow: '0 10px 30px rgba(0,0,0,0.18)', border: `0.5px solid ${t.hairline}`,
    }}>
      {msg.member && <Avatar m={members[msg.member]} size={30} />}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14.5, color: t.text, fontWeight: 500, lineHeight: 1.3 }}>{msg.text}</div>
      </div>
      <div style={{ width: 7, height: 7, borderRadius: 7, background: t.primary, flexShrink: 0 }} />
    </div>
  );
}

// ── Tab bar ──────────────────────────────────────────────────
function TabBar({ t, tab, onTab }) {
  const tabs = [
    { id: 'lists', label: 'リスト', icon: 'cart' },
    { id: 'members', label: 'メンバー', icon: 'people' },
    { id: 'settings', label: '設定', icon: 'gear' },
  ];
  return (
    <div style={{
      flexShrink: 0, paddingBottom: 26, paddingTop: 8,
      display: 'flex', justifyContent: 'space-around',
      background: t.dark ? 'rgba(20,26,23,0.82)' : 'rgba(255,255,255,0.82)',
      backdropFilter: 'blur(20px) saturate(180%)', WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: `0.5px solid ${t.hairline}`, position: 'relative', zIndex: 8,
    }}>
      {tabs.map(tb => {
        const on = tab === tb.id;
        return (
          <Press key={tb.id} onClick={() => onTab(tb.id)} scale={0.9} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, padding: '2px 18px',
          }}>
            <Icon name={tb.icon} size={26} color={on ? t.primary : t.textTer} sw={on ? 2.1 : 1.9} />
            <div style={{ fontSize: 10.5, fontWeight: on ? 600 : 500, color: on ? t.primary : t.textTer }}>{tb.label}</div>
          </Press>
        );
      })}
    </div>
  );
}

// ── Login ────────────────────────────────────────────────────
function LoginScreen({ t, onLogin }) {
  const btn = (icon, label, dark) => (
    <Press onClick={onLogin} scale={0.98} style={{
      height: 54, borderRadius: t.rBtn, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      background: dark ? '#000' : t.surface, color: dark ? '#fff' : t.text,
      border: dark ? 'none' : `1px solid ${t.sep}`, fontSize: 16.5, fontWeight: 600,
      boxShadow: dark ? 'none' : '0 1px 2px rgba(0,0,0,0.04)',
    }}>
      <Icon name={icon} size={21} color={dark ? '#fff' : (icon === 'google' ? undefined : t.text)} />
      {label}
    </Press>
  );
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: t.bg, position: 'relative' }}>
      <div style={{ position: 'absolute', top: -120, right: -90, width: 320, height: 320, borderRadius: 320, background: t.soft, opacity: t.dark ? 0.5 : 1 }} />
      <div style={{ position: 'absolute', top: 120, left: -110, width: 260, height: 260, borderRadius: 260, background: t.soft, opacity: t.dark ? 0.35 : 0.7 }} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', padding: '0 32px', position: 'relative', zIndex: 1 }}>
        <div style={{ width: 84, height: 84, borderRadius: 24, background: t.primary, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 16px 34px -10px ' + t.primary, marginBottom: 26 }}>
          <Icon name="cart" size={46} color="#fff" sw={1.9} />
        </div>
        <div style={{ fontSize: 32, fontWeight: 700, color: t.text, letterSpacing: 0.4 }}>MyFamiList</div>
        <div style={{ fontSize: 16, color: t.textSec, marginTop: 10, textAlign: 'center', lineHeight: 1.6, textWrap: 'balance' }}>
          家族やグループの買い物リストを、<br />みんなでリアルタイムに共有。
        </div>
      </div>
      <div style={{ padding: '0 24px 30px', position: 'relative', zIndex: 1, display: 'flex', flexDirection: 'column', gap: 11 }}>
        {btn('apple', 'Appleでサインイン', true)}
        {btn('google', 'Googleで続ける', false)}
        {btn('mail', 'メールアドレスで続ける', false)}
        <div style={{ fontSize: 11.5, color: t.textTer, textAlign: 'center', marginTop: 8, lineHeight: 1.5 }}>
          続行すると利用規約とプライバシーポリシーに同意したものとみなされます
        </div>
      </div>
    </div>
  );
}

// ── Lists overview ───────────────────────────────────────────
function ListProgress({ list, t, color }) {
  const total = list.items.length;
  const done = list.items.filter(i => i.checked).length;
  const pct = total ? done / total : 0;
  const r = 15, c = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: 38, height: 38, flexShrink: 0 }}>
      <svg width="38" height="38" viewBox="0 0 38 38" style={{ transform: 'rotate(-90deg)' }}>
        <circle cx="19" cy="19" r={r} fill="none" stroke={t.fieldBg} strokeWidth="3.5" />
        <circle cx="19" cy="19" r={r} fill="none" stroke={color} strokeWidth="3.5" strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={c * (1 - pct)} style={{ transition: 'stroke-dashoffset .5s' }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 700, color: t.text }}>
        {total - done}
      </div>
    </div>
  );
}

function ListsScreen({ t, group, members, plan, onOpenList, onSwitchGroup, onAddList }) {
  const remaining = plan === 'pro' ? '∞' : Math.max(0, 2 - group.lists.length);
  return (
    <React.Fragment>
      <AppHeader t={t} title="リスト"
        top={
          <Press onClick={onSwitchGroup} style={{ display: 'inline-flex', alignItems: 'center', gap: 7, marginBottom: 6, padding: '5px 12px 5px 8px', borderRadius: 999, background: t.surface, boxShadow: t.shadow }}>
            <div style={{ fontSize: 17 }}>{group.emoji}</div>
            <div style={{ fontSize: 15, fontWeight: 600, color: t.text }}>{group.name}</div>
            <Icon name="chevD" size={16} color={t.textSec} sw={2.3} />
          </Press>
        }
        right={
          <Press onClick={onSwitchGroup} style={{ paddingBottom: 4 }}>
            <AvatarStack ids={group.members} members={members} size={30} bg={t.bg} />
          </Press>
        }
      />
      <main style={{ flex: 1, overflowY: 'auto', padding: '6px 16px 24px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {group.lists.map(list => {
            const total = list.items.length, done = list.items.filter(i => i.checked).length;
            const cats = [...new Set(list.items.filter(i => !i.checked).map(i => i.cat))].slice(0, 5);
            return (
              <Card key={list.id} t={t} onClick={() => onOpenList(list.id)} style={{ padding: '15px 16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <ListProgress list={list} t={t} color={group.color} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 17.5, fontWeight: 600, color: t.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{list.name}</div>
                    <div style={{ fontSize: 13.5, color: t.textSec, marginTop: 2 }}>
                      {done === total ? '完了 🎉' : `残り ${total - done}品 ・ 全${total}品`}
                    </div>
                  </div>
                  <Icon name="chevR" size={19} color={t.textTer} sw={2.2} />
                </div>
                {cats.length > 0 && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 12, paddingTop: 12, borderTop: `0.5px solid ${t.hairline}` }}>
                    {cats.map(c => <CatDot key={c} cat={c} size={8} />)}
                    <div style={{ fontSize: 12.5, color: t.textTer, marginLeft: 2 }}>{cats.join('・')}</div>
                  </div>
                )}
              </Card>
            );
          })}
        </div>

        <Press onClick={onAddList} style={{
          marginTop: 12, height: 52, borderRadius: t.rCard, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
          border: `1.5px dashed ${t.textTer}`, color: t.textSec, fontSize: 15.5, fontWeight: 600,
        }}>
          <Icon name="plus" size={19} color={t.textSec} sw={2.2} /> リストを追加
        </Press>

        {plan !== 'pro' && (
          <div style={{ marginTop: 18, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, fontSize: 12.5, color: t.textTer }}>
            <span>無料プラン ・ リスト {group.lists.length}/2</span>
          </div>
        )}
      </main>
    </React.Fragment>
  );
}

// ── Members ──────────────────────────────────────────────────
function MembersScreen({ t, group, groups, members, plan, onInvite }) {
  const cap = plan === 'pro' ? null : 3;
  const allGroups = groups || [group];
  return (
    <React.Fragment>
      <AppHeader t={t} title="メンバー" />
      <main style={{ flex: 1, overflowY: 'auto', padding: '6px 16px 24px' }}>
        <Card t={t}>
          {group.members.map((id, i) => {
            const m = members[id];
            const memberGroups = allGroups.filter(g => g.members.includes(id));
            return (
              <div key={id} style={{ display: 'flex', alignItems: 'flex-start', gap: 13, padding: '13px 16px', borderTop: i ? `0.5px solid ${t.hairline}` : 'none' }}>
                <Avatar m={m} size={42} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 16.5, fontWeight: 600, color: t.text }}>{m.full}{m.you && <span style={{ color: t.textTer, fontWeight: 500 }}>（あなた）</span>}</div>
                  <div style={{ fontSize: 13, color: t.textSec, marginTop: 1 }}>{i === 0 ? 'オーナー' : 'メンバー'}</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 8 }}>
                    {memberGroups.map(g => {
                      const on = g.id === group.id;
                      return (
                        <div key={g.id} style={{
                          display: 'inline-flex', alignItems: 'center', gap: 4, padding: '3px 9px 3px 7px', borderRadius: 999,
                          fontSize: 12, fontWeight: on ? 600 : 500,
                          background: on ? t.soft : t.fieldBg, color: on ? t.softText : t.textSec,
                        }}>
                          <span style={{ fontSize: 12 }}>{g.emoji}</span>{g.name}
                        </div>
                      );
                    })}
                  </div>
                </div>
                {i === 0 && <Icon name="crown" size={19} color={t.softText} sw={1.9} style={{ marginTop: 2, flexShrink: 0 }} />}
              </div>
            );
          })}
        </Card>

        <div style={{ marginTop: 22 }}>
          <PrimaryButton t={t} icon="plus" onClick={onInvite}>メンバーを招待</PrimaryButton>
        </div>
        <div style={{ textAlign: 'center', fontSize: 13, color: t.textSec, marginTop: 12, lineHeight: 1.5 }}>
          招待リンクを送るだけで参加できます。<br />
          {cap ? `無料プランは ${group.members.length}/${cap} 人まで` : 'メンバー数は無制限です'}
        </div>
      </main>
    </React.Fragment>
  );
}

// ── Settings ─────────────────────────────────────────────────
function SettingsScreen({ t, plan, members, onUpgrade }) {
  const Row = ({ icon, label, detail, color, last, onClick }) => (
    <Press onClick={onClick} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '11px 16px', borderTop: last === 'first' ? 'none' : `0.5px solid ${t.hairline}` }}>
      <div style={{ width: 30, height: 30, borderRadius: 8, background: color, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <Icon name={icon} size={18} color="#fff" sw={2} />
      </div>
      <div style={{ flex: 1, fontSize: 16, color: t.text }}>{label}</div>
      {detail && <div style={{ fontSize: 14.5, color: t.textSec }}>{detail}</div>}
      <Icon name="chevR" size={17} color={t.textTer} sw={2.2} />
    </Press>
  );
  return (
    <React.Fragment>
      <AppHeader t={t} title="設定" />
      <main style={{ flex: 1, overflowY: 'auto', padding: '6px 16px 24px' }}>
        <Card t={t} style={{ padding: '14px 16px', marginBottom: 22, display: 'flex', alignItems: 'center', gap: 13 }}>
          <Avatar m={members.me} size={50} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 18, fontWeight: 600, color: t.text }}>{members.me.full}</div>
            <div style={{ fontSize: 13.5, color: t.textSec, marginTop: 1 }}>Apple ID でサインイン中</div>
          </div>
        </Card>

        {plan !== 'pro' && (
          <Press onClick={onUpgrade} style={{
            borderRadius: t.rCard, padding: '16px 18px', marginBottom: 22, color: '#fff',
            background: `linear-gradient(135deg, ${t.primary}, ${t.primaryPress})`,
            boxShadow: '0 12px 26px -10px ' + t.primary, display: 'flex', alignItems: 'center', gap: 14,
          }}>
            <Icon name="crown" size={28} color="#fff" sw={1.9} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16.5, fontWeight: 700 }}>MyFamiList Pro</div>
              <div style={{ fontSize: 13, opacity: 0.9, marginTop: 2 }}>グループ・リスト・メンバー無制限</div>
            </div>
            <Icon name="chevR" size={20} color="#fff" sw={2.3} />
          </Press>
        )}

        <SectionLabel t={t} style={{ paddingLeft: 16 }}>通知</SectionLabel>
        <Card t={t} style={{ marginBottom: 22 }}>
          <Row icon="bell" label="プッシュ通知" detail="オン" color="#D9695F" last="first" />
          <Row icon="clock" label="リマインダー" detail="土 10:00" color="#E0A03A" />
        </Card>

        <SectionLabel t={t} style={{ paddingLeft: 16 }}>その他</SectionLabel>
        <Card t={t}>
          <Row icon="sparkle" label="カテゴリの管理" color="#5690C9" last="first" />
          <Row icon="note" label="ヘルプとフィードバック" color="#7C8AA1" />
          <Row icon="door" label="サインアウト" color="#98A0A4" />
        </Card>
        <div style={{ textAlign: 'center', fontSize: 12, color: t.textTer, marginTop: 20 }}>MyFamiList v1.0.0</div>
      </main>
    </React.Fragment>
  );
}

Object.assign(window, { AppHeader, Toast, TabBar, LoginScreen, ListsScreen, MembersScreen, SettingsScreen });
