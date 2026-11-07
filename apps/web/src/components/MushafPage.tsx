import { Fragment, type Ref } from "react";
import { toArabicIndic } from "@/lib/digits";
import { isCentredPage, type Line, type ResolvedPage } from "@/lib/mushaf";
import { surahMeta } from "@/lib/pages";

export interface MushafPageProps {
  data: ResolvedPage;
  /** "s:a" of the selected ayah and of the ayah being recited. */
  selected?: string | null;
  playing?: string | null;
  /** Surah whose basmala is being recited (highlights the basmala line). */
  playingBasmala?: number | null;
  markerLabel: (s: number, a: number) => string;
  pageRef?: Ref<HTMLDivElement>;
}

function lineClass(line: Line): string {
  return line.kind === "text" ? "m-line m-text" : `m-line m-${line.kind}`;
}

type LineProps = Required<
  Pick<MushafPageProps, "selected" | "playing" | "playingBasmala" | "markerLabel">
> & {
  line: Line;
};

function LineContent({ line, selected, playing, playingBasmala, markerLabel }: LineProps) {
  if (line.kind === "sura") {
    return (
      <span className="sura-band" data-testid="sura-band">
        <span>سورة {surahMeta(line.s)?.nameAr}</span>
      </span>
    );
  }
  if (line.kind === "basmala") {
    return (
      <span className={playingBasmala === line.s ? "m-in seg playing" : "m-in"} data-testid="basmala">
        {line.text}
      </span>
    );
  }
  return (
    <span className="m-in">
      {line.segments.map((g, j) => {
        const key = `${g.s}:${g.a}`;
        const cls = ["seg", key === selected ? "selected" : "", key === playing ? "playing" : ""]
          .filter(Boolean)
          .join(" ");
        return (
          <Fragment key={j}>
            {j > 0 ? " " : null}
            <span className={cls} data-ayah={key}>
              {g.text}
            </span>
            {g.end ? (
              <>
                {" "}
                <button
                  type="button"
                  className={key === selected ? "ayah-end selected" : "ayah-end"}
                  data-ayah={key}
                  data-testid="ayah-marker"
                  aria-pressed={key === selected}
                >
                  <span aria-hidden="true">{`۝${toArabicIndic(g.a)}`}</span>
                  <span className="sr-only">{markerLabel(g.s, g.a)}</span>
                </button>
              </>
            ) : null}
          </Fragment>
        );
      })}
    </span>
  );
}

/** One Mushaf page: surah bands, basmala lines and justified text lines from the 15-line layout. */
export function MushafPage({
  data,
  selected = null,
  playing = null,
  playingBasmala = null,
  markerLabel,
  pageRef,
}: MushafPageProps) {
  const centred = isCentredPage(data.page);
  return (
    <div
      ref={pageRef}
      className={centred ? "mushaf-page centred" : "mushaf-page"}
      lang="ar"
      dir="rtl"
      data-testid="mushaf-page"
      data-page={data.page}
    >
      {data.lines.map((line, i) => (
        <Fragment key={i}>
          <div className={lineClass(line)} data-line={i + 1}>
            <LineContent
              line={line}
              selected={selected}
              playing={playing}
              playingBasmala={playingBasmala}
              markerLabel={markerLabel}
            />
          </div>
          {/* whitespace between blocks: no layout effect, keeps words apart in copied/extracted text */}
          {"\n"}
        </Fragment>
      ))}
    </div>
  );
}
