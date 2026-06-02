// data.jsx — MyFamiList seed data + icon set

const MEMBERS = {
  me:   { id: 'me',   name: '太郎',   full: '山田 太郎',  color: '#16A368', you: true },
  hana: { id: 'hana', name: '花子',   full: '山田 花子',  color: '#D9695F' },
  saku: { id: 'saku', name: 'さくら', full: '山田 さくら', color: '#5690C9' },
  ken:  { id: 'ken',  name: '健一',   full: '佐藤 健一',  color: '#E0A03A' },
  mai:  { id: 'mai',  name: '麻衣',   full: '鈴木 麻衣',  color: '#B179B0' },
};

let _uid = 100;
const nid = () => 'i' + (++_uid);

function mkItem(name, qty, cat, opts = {}) {
  return {
    id: nid(), name, qty, cat,
    checked: opts.checked || false,
    memo: opts.memo || '',
    by: opts.by || 'me',
    at: opts.at || '今日',
  };
}

const GROUPS = [
  {
    id: 'g_yamada',
    name: '山田家',
    emoji: '🏠',
    color: '#16A368',
    members: ['me', 'hana', 'saku'],
    lists: [
      {
        id: 'l_super', name: '今週のスーパー', note: '土曜にまとめ買い',
        items: [
          mkItem('牛乳', '2本', '乳製品・卵', { by: 'hana', at: '8分前' }),
          mkItem('卵', '1パック', '乳製品・卵', { by: 'hana', at: '8分前' }),
          mkItem('トマト', '4個', '野菜・果物', { memo: '完熟のもの', by: 'me', at: '32分前' }),
          mkItem('鶏むね肉', '300g', '肉・魚', { by: 'saku', at: '1時間前' }),
          mkItem('玉ねぎ', '3個', '野菜・果物', { by: 'me', at: '昨日' }),
          mkItem('食パン', '1斤', 'パン・米', { checked: true, by: 'hana', at: '昨日' }),
          mkItem('ヨーグルト', '大1個', '乳製品・卵', { checked: true, by: 'me', at: '昨日' }),
          mkItem('麦茶パック', '', '飲料', { checked: true, by: 'saku', at: '昨日' }),
        ],
      },
      {
        id: 'l_drug', name: 'ドラッグストア', note: '',
        items: [
          mkItem('ティッシュ', '5箱', '日用品', { by: 'me', at: '2日前' }),
          mkItem('food wrap', 'ラップ', '日用品', { by: 'hana', at: '2日前' }),
          mkItem('歯みがき粉', '', '日用品', { checked: true, by: 'me', at: '3日前' }),
        ],
      },
    ],
  },
  {
    id: 'g_work',
    name: '職場の買い出し',
    emoji: '🏢',
    color: '#5690C9',
    members: ['ken', 'mai', 'me'],
    lists: [
      {
        id: 'l_office', name: '給湯室の備品', note: '',
        items: [
          mkItem('コーヒー豆', '1kg', '飲料', { by: 'ken', at: '1時間前' }),
          mkItem('紙コップ', '100個', '日用品', { by: 'mai', at: '3時間前' }),
          mkItem('砂糖スティック', '', '調味料', { checked: true, by: 'ken', at: '昨日' }),
        ],
      },
    ],
  },
];

// ── Icons (clean stroke, 24-grid) ──────────────────────────────
function Icon({ name, size = 24, color = 'currentColor', sw = 1.9, fill = false, style }) {
  const P = { fill: 'none', stroke: color, strokeWidth: sw, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const paths = {
    check: <polyline points="4,12.5 9.5,18 20,6" {...P} />,
    plus: <g {...P}><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></g>,
    chevR: <polyline points="9,5 16,12 9,19" {...P} />,
    chevL: <polyline points="15,5 8,12 15,19" {...P} />,
    chevD: <polyline points="5,9 12,16 19,9" {...P} />,
    x: <g {...P}><line x1="6" y1="6" x2="18" y2="18" /><line x1="18" y1="6" x2="6" y2="18" /></g>,
    share: <g {...P}><path d="M12 15V4" /><polyline points="8,8 12,4 16,8" /><path d="M6 12v6a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2v-6" /></g>,
    people: <g {...P}><circle cx="9" cy="8" r="3.2" /><path d="M3.5 19a5.5 5.5 0 0 1 11 0" /><path d="M16 5.2a3.2 3.2 0 0 1 0 6" /><path d="M17 14.2A5.5 5.5 0 0 1 20.5 19" /></g>,
    list: <g {...P}><line x1="9" y1="7" x2="20" y2="7" /><line x1="9" y1="12" x2="20" y2="12" /><line x1="9" y1="17" x2="20" y2="17" /><circle cx="4.5" cy="7" r="0.6" fill={color} /><circle cx="4.5" cy="12" r="0.6" fill={color} /><circle cx="4.5" cy="17" r="0.6" fill={color} /></g>,
    cart: <g {...P}><circle cx="9.5" cy="20" r="1.3" /><circle cx="17.5" cy="20" r="1.3" /><path d="M3 4h2.2l2.1 11.2a1.4 1.4 0 0 0 1.4 1.1h8.4a1.4 1.4 0 0 0 1.4-1.1L20.5 8H6" /></g>,
    gear: <g {...P}><circle cx="12" cy="12" r="3.2" /><path d="M12 2.5v2.6M12 18.9v2.6M21.5 12h-2.6M5.1 12H2.5M18.7 5.3l-1.8 1.8M7.1 16.9l-1.8 1.8M18.7 18.7l-1.8-1.8M7.1 7.1 5.3 5.3" /></g>,
    search: <g {...P}><circle cx="11" cy="11" r="6.5" /><line x1="20" y1="20" x2="16" y2="16" /></g>,
    trash: <g {...P}><polyline points="4,7 20,7" /><path d="M9 7V5.2A1.2 1.2 0 0 1 10.2 4h3.6A1.2 1.2 0 0 1 15 5.2V7" /><path d="M6 7l1 12.2A1.4 1.4 0 0 0 8.4 20.5h7.2A1.4 1.4 0 0 0 17 19.2L18 7" /></g>,
    dots: <g fill={color}><circle cx="5" cy="12" r="1.9" /><circle cx="12" cy="12" r="1.9" /><circle cx="19" cy="12" r="1.9" /></g>,
    crown: <g {...P}><path d="M3 7.5l4 4 5-7 5 7 4-4-1.6 11H4.6z" /><line x1="4.6" y1="18.5" x2="19.4" y2="18.5" /></g>,
    link: <g {...P}><path d="M9.5 14.5l5-5" /><path d="M8 12l-2 2a3.3 3.3 0 0 0 4.6 4.6l2-2" /><path d="M16 12l2-2a3.3 3.3 0 0 0-4.6-4.6l-2 2" /></g>,
    qr: <g {...P}><rect x="3.5" y="3.5" width="6" height="6" rx="1" /><rect x="14.5" y="3.5" width="6" height="6" rx="1" /><rect x="3.5" y="14.5" width="6" height="6" rx="1" /><path d="M14.5 14.5h3v3M20.5 14.5v6M17.5 20.5h-3" /></g>,
    copy: <g {...P}><rect x="8.5" y="8.5" width="11" height="11" rx="2.2" /><path d="M5.5 15.5h-.5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v.5" /></g>,
    edit: <g {...P}><path d="M4 20h4l10-10a2.1 2.1 0 0 0-3-3L5 17z" /><line x1="14.5" y1="6.5" x2="17.5" y2="9.5" /></g>,
    bell: <g {...P}><path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6" /><path d="M10 19a2 2 0 0 0 4 0" /></g>,
    clock: <g {...P}><circle cx="12" cy="12" r="8.5" /><polyline points="12,7 12,12 16,14" /></g>,
    minus: <line x1="5" y1="12" x2="19" y2="12" {...P} />,
    sparkle: <g {...P}><path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z" /></g>,
    door: <g {...P}><path d="M14 4H6v16h8" /><polyline points="11,8 16,12 11,16" /><line x1="16" y1="12" x2="8" y2="12" /></g>,
    note: <g {...P}><path d="M5 4h11l3 3v13H5z" /><polyline points="9,9 15,9" /><polyline points="9,13 15,13" /></g>,
    apple: <g fill={color} stroke="none"><path d="M16.5 12.6c0-2 1.6-2.9 1.7-3-1-1.4-2.4-1.6-2.9-1.6-1.2-.1-2.4.7-3 .7s-1.6-.7-2.6-.7c-1.3 0-2.6.8-3.2 2-1.4 2.4-.4 6 1 8 .6 1 1.4 2.1 2.4 2 1-.04 1.3-.6 2.5-.6s1.5.6 2.5.6 1.7-1 2.3-2c.7-1.1 1-2.2 1-2.2s-1.7-.6-1.7-3.2zM14.6 6.3c.5-.6.9-1.5.8-2.3-.8 0-1.7.5-2.2 1.1-.5.5-.9 1.4-.8 2.2.9.1 1.7-.4 2.2-1z" /></g>,
    google: <g><path d="M21 12.2c0-.7-.06-1.3-.2-1.9H12v3.7h5.1a4.3 4.3 0 0 1-1.9 2.8v2.3h3.1c1.8-1.7 2.7-4.1 2.7-6.9z" fill="#4285F4" /><path d="M12 21c2.4 0 4.5-.8 6-2.2l-3.1-2.3c-.8.6-1.9.9-2.9.9-2.3 0-4.2-1.5-4.9-3.6H3.9v2.3A9 9 0 0 0 12 21z" fill="#34A853" /><path d="M7.1 13.8a5.4 5.4 0 0 1 0-3.5V8H3.9a9 9 0 0 0 0 8.1z" fill="#FBBC05" /><path d="M12 6.6c1.3 0 2.5.45 3.4 1.3l2.6-2.6A9 9 0 0 0 3.9 8l3.2 2.5C7.8 8.2 9.7 6.6 12 6.6z" fill="#EA4335" /></g>,
    mail: <g {...P}><rect x="3" y="5" width="18" height="14" rx="2.4" /><polyline points="4,7 12,13 20,7" /></g>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={style} aria-hidden="true">
      {paths[name] || null}
    </svg>
  );
}

Object.assign(window, { MEMBERS, GROUPS, mkItem, nid, Icon });
