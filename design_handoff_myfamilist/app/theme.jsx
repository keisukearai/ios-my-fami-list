// theme.jsx — MyFamiList design tokens
// Three green visual directions × light/dark, plus radius + density scales.
// getTokens({theme, dark, radius, density}) → flat token object `t`.

const THEMES = {
  fresh: {
    label: 'フレッシュ',
    swatch: ['#16A368', '#EAF7F0', '#F0F5F2'],
    primary: '#16A368', primaryPress: '#138A58', onPrimary: '#FFFFFF',
    soft: '#E4F4EC', softText: '#0E7A4D',
    bgLight: '#EFF4F1', bgDark: '#0D1310',
  },
  sage: {
    label: 'セージ',
    swatch: ['#5E8C6A', '#ECF0E8', '#F4F3EC'],
    primary: '#5E8C6A', primaryPress: '#4E7759', onPrimary: '#FFFFFF',
    soft: '#E8EEE4', softText: '#4A6B53',
    bgLight: '#F3F2EB', bgDark: '#11140F',
  },
  forest: {
    label: 'フォレスト',
    swatch: ['#0B7A4F', '#DCF0E6', '#ECF2EF'],
    primary: '#0B7A4F', primaryPress: '#096440', onPrimary: '#FFFFFF',
    soft: '#DBEEE4', softText: '#075C3B',
    bgLight: '#ECF2EF', bgDark: '#0A120E',
  },
};

const RADIUS = { 控えめ: 0.55, 標準: 1, 大きめ: 1.5 };
const DENSITY = {
  ゆったり: { rowH: 60, padY: 16, gap: 14, secGap: 30, fs: 17 },
  標準:     { rowH: 52, padY: 12, gap: 11, secGap: 24, fs: 16.5 },
  コンパクト: { rowH: 46, padY: 9,  gap: 8,  secGap: 18, fs: 16 },
};

function getTokens({ theme = 'fresh', dark = false, radius = '標準', density = '標準' }) {
  const th = THEMES[theme] || THEMES.fresh;
  const rs = RADIUS[radius] ?? 1;
  const d = DENSITY[density] || DENSITY['標準'];

  const neutral = dark
    ? {
        bg: th.bgDark,
        surface: '#191F1C',
        surface2: '#222a26',
        text: '#F1F5F3',
        textSec: 'rgba(231,243,238,0.62)',
        textTer: 'rgba(231,243,238,0.34)',
        sep: 'rgba(231,243,238,0.12)',
        hairline: 'rgba(231,243,238,0.10)',
        fieldBg: '#232b27',
        shadow: '0 1px 2px rgba(0,0,0,0.4), 0 8px 24px rgba(0,0,0,0.34)',
        islandText: '#fff',
      }
    : {
        bg: th.bgLight,
        surface: '#FFFFFF',
        surface2: '#FAFBFA',
        text: '#16201B',
        textSec: 'rgba(40,54,46,0.60)',
        textTer: 'rgba(40,54,46,0.34)',
        sep: 'rgba(40,54,46,0.10)',
        hairline: 'rgba(40,54,46,0.08)',
        fieldBg: 'rgba(40,54,46,0.05)',
        shadow: '0 1px 2px rgba(20,40,30,0.05), 0 8px 26px rgba(20,40,30,0.07)',
        islandText: '#000',
      };

  return {
    ...neutral,
    dark,
    primary: th.primary,
    primaryPress: th.primaryPress,
    onPrimary: th.onPrimary,
    soft: dark ? 'rgba(22,163,104,0.20)' : th.soft,
    softText: dark ? '#7FD8AB' : th.softText,
    themeLabel: th.label,
    // radii
    rCard: Math.round(20 * rs),
    rBtn: Math.round(14 * rs),
    rChip: Math.round(10 * rs),
    rSheet: Math.round(30 * rs),
    rField: Math.round(13 * rs),
    rTiny: Math.round(8 * rs),
    // density
    rowH: d.rowH, padY: d.padY, gap: d.gap, secGap: d.secGap, fs: d.fs,
  };
}

const CATEGORIES = {
  '野菜・果物': '#54A862',
  '肉・魚':     '#D9695F',
  '乳製品・卵': '#E0A03A',
  'パン・米':   '#C5934F',
  '飲料':       '#5690C9',
  '調味料':     '#B179B0',
  'お菓子':     '#D981A6',
  '日用品':     '#7C8AA1',
  'その他':     '#98A0A4',
};
const CATEGORY_LIST = Object.keys(CATEGORIES);

Object.assign(window, { getTokens, THEMES, CATEGORIES, CATEGORY_LIST, RADIUS, DENSITY });
