// ui.jsx — shared UI primitives for MyFamiList

const { useState, useEffect, useRef } = React;

// Press feedback wrapper
function Press({ children, onClick, style, scale = 0.97, disabled, ...rest }) {
  const [down, setDown] = useState(false);
  return (
    <div
      onPointerDown={() => !disabled && setDown(true)}
      onPointerUp={() => setDown(false)}
      onPointerLeave={() => setDown(false)}
      onClick={disabled ? undefined : onClick}
      style={{
        transform: down ? `scale(${scale})` : 'scale(1)',
        transition: 'transform .12s cubic-bezier(.2,.8,.3,1), opacity .12s',
        opacity: disabled ? 0.4 : down ? 0.86 : 1,
        cursor: disabled ? 'default' : 'pointer',
        WebkitTapHighlightColor: 'transparent',
        ...style,
      }}
      {...rest}
    >
      {children}
    </div>
  );
}

function Avatar({ m, size = 32, ring, t }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: size, flexShrink: 0,
      background: m.photo ? `center/cover url(${m.photo})` : m.color, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: m.emoji ? size * 0.52 : size * 0.4, fontWeight: 600, letterSpacing: 0,
      boxShadow: ring ? `0 0 0 2px ${ring}` : 'none',
      fontFeatureSettings: '"palt"', overflow: 'hidden',
    }}>
      {m.photo ? '' : (m.emoji || m.name.slice(0, 1))}
    </div>
  );
}

function AvatarStack({ ids, members, size = 26, max = 4, bg = '#fff' }) {
  const show = ids.slice(0, max);
  const extra = ids.length - show.length;
  return (
    <div style={{ display: 'flex', alignItems: 'center' }}>
      {show.map((id, i) => (
        <div key={id} style={{ marginLeft: i === 0 ? 0 : -size * 0.34, zIndex: max - i }}>
          <Avatar m={members[id]} size={size} ring={bg} />
        </div>
      ))}
      {extra > 0 && (
        <div style={{
          marginLeft: -size * 0.34, width: size, height: size, borderRadius: size,
          background: '#9AA0A6', color: '#fff', boxShadow: `0 0 0 2px ${bg}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: size * 0.36, fontWeight: 600,
        }}>+{extra}</div>
      )}
    </div>
  );
}

function Checkbox({ checked, color, size = 26, onClick, t }) {
  return (
    <Press onClick={onClick} scale={0.85} style={{ flexShrink: 0 }}>
      <div style={{
        width: size, height: size, borderRadius: size,
        background: checked ? color : 'transparent',
        border: checked ? `1.5px solid ${color}` : `1.8px solid ${t.textTer}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'background .16s, border-color .16s',
      }}>
        <div style={{ transform: checked ? 'scale(1)' : 'scale(0.4)', opacity: checked ? 1 : 0, transition: 'transform .18s cubic-bezier(.2,.9,.3,1.4), opacity .12s' }}>
          <Icon name="check" size={size * 0.62} color="#fff" sw={2.6} />
        </div>
      </div>
    </Press>
  );
}

function PrimaryButton({ children, onClick, t, disabled, full = true, tone = 'primary', icon }) {
  const bg = tone === 'primary' ? t.primary : t.fieldBg;
  const fg = tone === 'primary' ? t.onPrimary : t.text;
  return (
    <Press onClick={onClick} disabled={disabled} scale={0.975} style={{
      height: 52, borderRadius: t.rBtn, background: bg, color: fg,
      width: full ? '100%' : undefined, padding: full ? 0 : '0 22px',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      fontSize: 17, fontWeight: 600, letterSpacing: 0.2,
      boxShadow: tone === 'primary' ? '0 6px 16px -6px rgba(0,0,0,0.35)' : 'none',
    }}>
      {icon && <Icon name={icon} size={20} color={fg} sw={2.1} />}
      {children}
    </Press>
  );
}

// Bottom sheet with backdrop + slide-up
function BottomSheet({ open, onClose, t, children, maxH = '88%', pad = true }) {
  const [mounted, setMounted] = useState(open);
  const [shown, setShown] = useState(false);
  useEffect(() => {
    if (open) {
      setMounted(true);
      const tm = setTimeout(() => setShown(true), 20);
      return () => clearTimeout(tm);
    } else {
      setShown(false);
      const tm = setTimeout(() => setMounted(false), 320);
      return () => clearTimeout(tm);
    }
  }, [open]);
  if (!mounted) return null;
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 200 }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: 'rgba(10,20,15,0.42)',
        opacity: shown ? 1 : 0, transition: 'opacity .3s',
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        maxHeight: maxH, background: t.surface,
        borderTopLeftRadius: t.rSheet, borderTopRightRadius: t.rSheet,
        transform: shown ? 'translateY(0)' : 'translateY(102%)',
        transition: 'transform .34s cubic-bezier(.2,.85,.25,1)',
        boxShadow: '0 -10px 40px rgba(0,0,0,0.22)',
        display: 'flex', flexDirection: 'column', overflow: 'hidden',
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 9, flexShrink: 0 }}>
          <div style={{ width: 38, height: 5, borderRadius: 5, background: t.textTer }} />
        </div>
        <div style={{ overflowY: 'auto', padding: pad ? '8px 20px 30px' : '8px 0 30px' }}>
          {children}
        </div>
      </div>
    </div>
  );
}

// section label
function SectionLabel({ children, t, style }) {
  return (
    <div style={{
      fontSize: 13, fontWeight: 600, color: t.textSec, letterSpacing: 0.2,
      padding: '0 4px 8px', ...style,
    }}>{children}</div>
  );
}

// rounded card container
function Card({ children, t, style, onClick }) {
  const Comp = onClick ? Press : 'div';
  return (
    <Comp onClick={onClick} style={{
      background: t.surface, borderRadius: t.rCard, boxShadow: t.shadow,
      overflow: 'hidden', ...style,
    }}>{children}</Comp>
  );
}

function CatDot({ cat, size = 9 }) {
  return <div style={{ width: size, height: size, borderRadius: size, background: CATEGORIES[cat] || '#9AA0A6', flexShrink: 0 }} />;
}

Object.assign(window, { Press, Avatar, AvatarStack, Checkbox, PrimaryButton, BottomSheet, SectionLabel, Card, CatDot });
