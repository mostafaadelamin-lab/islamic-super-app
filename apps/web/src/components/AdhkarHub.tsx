import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { withBase } from "@/lib/base-path";
import { Icon, type IconName } from "@/components/Icon";

/** Hisn al-Muslim sections, grouped as on the app's adhkar page (adhkar_screen.dart). */
const DAILY: readonly [string, IconName][] = [
  ["sleep", "moon"],
  ["prayer", "prayer"],
  ["remembrance", "beads"],
];
const DUAS: readonly [string, IconName][] = [
  ["hardship", "dua"],
  ["illness", "adhkar"],
  ["travel", "location"],
  ["home", "home"],
  ["food", "calendarCheck"],
  ["people", "dua"],
  ["nature", "sunrise"],
  ["hajj", "kaaba"],
];

/** Sheikh Mishary Alafasy's morning and evening adhkar, the same recordings the app ships offline. */
export const ADHKAR_AUDIO = {
  morning: "/audio/adhkar_morning_alafasy.mp3",
  evening: "/audio/adhkar_evening_alafasy.mp3",
} as const;

/** The app's adhkar hub: daily adhkar, duas by occasion, and listening to the adhkar. */
export function AdhkarHub({ locale }: { locale: Locale }) {
  const chip = ([id, icon]: readonly [string, IconName]) => (
    <li key={id}>
      {/* A full page load, so Hisn al-Muslim reads the #section on arrival. */}
      <a
        className="tile tile-sm"
        href={withBase(`${href(locale, "hisn")}#${id}`)}
        data-testid={`adhkar-hub-${id}`}
      >
        <span className="tile-icon">
          <Icon name={icon} />
        </span>
        <span className="tile-text">
          <strong>{t(locale, `hisn.section.${id}`)}</strong>
        </span>
      </a>
    </li>
  );
  return (
    <section className="adhkar-hub" data-testid="adhkar-hub">
      <h2>{t(locale, "adhkar.daily")}</h2>
      <ul className="tiles tiles-sm">{DAILY.map(chip)}</ul>
      <h2>{t(locale, "adhkar.duas")}</h2>
      <ul className="tiles tiles-sm">{DUAS.map(chip)}</ul>
      <h2>{t(locale, "ruqyah.title")}</h2>
      <ul className="tiles tiles-sm">
        {(
          [
            ["ruqyah", "ruqyah.title", "shield"],
            ["kids/ruqyah", "ruqyah.kidsTitle", "kids"],
          ] as const
        ).map(([path, key, icon]) => (
          <li key={path}>
            <a
              className="tile tile-sm"
              href={withBase(href(locale, path))}
              data-testid={`adhkar-hub-${path}`}
            >
              <span className="tile-icon">
                <Icon name={icon} />
              </span>
              <span className="tile-text">
                <strong>{t(locale, key)}</strong>
              </span>
            </a>
          </li>
        ))}
      </ul>
      <h2>{t(locale, "adhkar.listenHeader")}</h2>
      <div className="grid adhkar-listen">
        {(["morning", "evening"] as const).map((s) => (
          // Owner 2026-11-27: the recording plays inside the morning / evening adhkar themselves.
          <a className="card tile" key={s} href={`#${s}-listen`} data-testid={`adhkar-audio-${s}`}>
            <span className="tile-icon">
              <Icon name="headphones" />
            </span>
            <span className="tile-text">
              <strong>{t(locale, `adhkar.${s}Title`)}</strong>
              <span className="muted small">{t(locale, "adhkar.alafasy")}</span>
            </span>
          </a>
        ))}
      </div>
    </section>
  );
}
