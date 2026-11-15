import scenesJson from "@/generated/hajj-scenes.json";
import rolesJson from "@/generated/scene-roles.json";

/*
 * The 3D (isometric) pictures of the Hajj and Umrah guide (owner 2026-11-16). Drawn by
 * content/pilgrimage/build-scenes.mjs as plain shapes; each colour is a role that follows the chosen
 * colour style through scene-roles.v1.json (the app reads the same two files).
 */

export type SceneShape =
  | { t: "poly"; p: number[]; f: string; s?: string; sw?: number }
  | { t: "ell"; cx: number; cy: number; rx: number; ry: number; f: string; s?: string; sw?: number }
  | { t: "circle"; cx: number; cy: number; r: number; f: string; s?: string; sw?: number }
  | { t: "dome"; cx: number; cy: number; rx: number; ry: number; h: number; f: string; s: string }
  | { t: "line"; p: number[]; s: string; sw: number; dash?: number[]; arrow?: boolean }
  | { t: "text"; x: number; y: number; v: string; f: string; size: number; w?: number };

export interface Scene {
  w: number;
  h: number;
  title: string;
  places: string[];
  shapes: SceneShape[];
}

type RoleColour = string | ["mix", RoleColour, RoleColour, number];

export const SCENES = (scenesJson as unknown as { scenes: Record<string, Scene> }).scenes;
export const SCENE_ROLES = (rolesJson as unknown as { roles: Record<string, RoleColour> }).roles;

const PERCENT = 100;
const XY = 2;
const LABEL_HALO = 3;
const LABEL_WEIGHT = 500;

/**
 * Token name to CSS name: each capital or digit starts a new word. Matches the "S" and "2" of
 * "surface2" ("surface-2"); a plain "primary" has nothing to match.
 * https://regex101.com/?regex=%5BA-Z0-9%5D&testString=accentSoft%20surface2%20primary
 */
const kebab = (s: string): string => s.replace(/[A-Z0-9]/g, (c) => `-${c.toLowerCase()}`);

/** The CSS colour of a role: a token of the current style, a brand colour, a fixed colour, or a mix. */
export function roleColour(role: string): string {
  const c = SCENE_ROLES[role];
  if (c === undefined) throw new Error(`hajj scene: no colour for role ${role}`);
  return colour(c);
}

function colour(c: RoleColour): string {
  if (Array.isArray(c))
    return `color-mix(in srgb, ${colour(c[1])} ${Math.round(c[3] * PERCENT)}%, ${colour(c[2])})`;
  if (c.startsWith("t:")) return `var(--color-${kebab(c.slice(2))})`;
  if (c.startsWith("b:")) return `var(--brand-${kebab(c.slice(2))})`;
  return c;
}

const pts = (p: readonly number[]): string =>
  p
    .filter((_, i) => i % XY === 0)
    .map((x, i) => `${x},${p[i * XY + 1]}`)
    .join(" ");

const strokeOf = (x: { s?: string; sw?: number }): { stroke?: string; strokeWidth?: number } =>
  x.s ? { stroke: roleColour(x.s), strokeWidth: x.sw ?? 1 } : {};

type ShapeOf<T extends SceneShape["t"]> = Extract<SceneShape, { t: T }>;
type ShapeView = { [T in SceneShape["t"]]: (x: ShapeOf<T>, id: string) => React.JSX.Element };

const SHAPE_VIEW: ShapeView = {
  poly: (x) => <polygon points={pts(x.p)} fill={roleColour(x.f)} {...strokeOf(x)} strokeLinejoin="round" />,
  ell: (x) => <ellipse cx={x.cx} cy={x.cy} rx={x.rx} ry={x.ry} fill={roleColour(x.f)} {...strokeOf(x)} />,
  circle: (x) => <circle cx={x.cx} cy={x.cy} r={x.r} fill={roleColour(x.f)} {...strokeOf(x)} />,
  dome: (x) => (
    <path
      d={`M${x.cx - x.rx},${x.cy} A${x.rx},${x.h} 0 0 1 ${x.cx + x.rx},${x.cy} A${x.rx},${x.ry} 0 0 1 ${x.cx - x.rx},${x.cy}Z`}
      fill={roleColour(x.f)}
      stroke={roleColour(x.s)}
    />
  ),
  line: (x, id) => (
    <polyline
      points={pts(x.p)}
      fill="none"
      stroke={roleColour(x.s)}
      strokeWidth={x.sw}
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeDasharray={x.dash?.join(" ")}
      markerEnd={x.arrow ? `url(#${id}-ar-${x.s})` : undefined}
    />
  ),
  text: (x) => (
    <text
      x={x.x}
      y={x.y}
      fontSize={x.size}
      fontWeight={x.w ?? LABEL_WEIGHT}
      fill={roleColour(x.f)}
      textAnchor="middle"
      direction="rtl"
      stroke="var(--color-surface-2)"
      strokeWidth={LABEL_HALO}
      paintOrder="stroke"
    >
      {x.v}
    </text>
  ),
};

function Shape({ x, id }: { x: SceneShape; id: string }) {
  const view = SHAPE_VIEW[x.t] as (x: SceneShape, id: string) => React.JSX.Element;
  return view(x, id);
}

/** One picture, by its id in hajj-scenes.v1.json. */
export function HajjScene({ id }: { id: string }) {
  const s = SCENES[id];
  if (!s) return null;
  const domId = `hs-${id}`;
  const arrows = [...new Set(s.shapes.flatMap((x) => (x.t === "line" && x.arrow ? [x.s] : [])))];
  return (
    <figure className="hajj-scene" data-testid={`hajj-scene-${id}`} data-places={s.places.join(" ")}>
      <svg viewBox={`0 0 ${s.w} ${s.h}`} role="img" aria-label={s.title} lang="ar">
        <defs>
          {arrows.map((r) => (
            <marker
              key={r}
              id={`${domId}-ar-${r}`}
              viewBox="0 0 10 10"
              refX="7"
              refY="5"
              markerWidth="5"
              markerHeight="5"
              orient="auto-start-reverse"
            >
              <path d="M0,0L10,5L0,10z" fill={roleColour(r)} />
            </marker>
          ))}
        </defs>
        {s.shapes.map((x, i) => (
          <Shape key={i} x={x} id={domId} />
        ))}
      </svg>
    </figure>
  );
}
