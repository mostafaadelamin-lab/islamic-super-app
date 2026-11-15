import { Icon, type IconName } from "./Icon";

/** Icons of the Mushaf reader: the same shared Rattil icon set as everywhere else. */
export type ReaderIconName = Extract<
  IconName,
  | "chevronDown"
  | "back"
  | "help"
  | "list"
  | "bookmarks"
  | "openBook"
  | "search"
  | "repeat"
  | "split"
  | "reciter"
  | "expand"
  | "shrink"
>;

export function ReaderIcon({ name, size }: { name: ReaderIconName; size?: number }) {
  return <Icon name={name} size={size} />;
}
