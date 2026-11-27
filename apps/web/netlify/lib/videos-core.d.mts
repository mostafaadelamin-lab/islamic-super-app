// Types for videos-core.mjs (plain JS so the Netlify Function needs no build step).
export interface CoreHit {
  ref?: string;
  title: string;
  channel?: string | null;
  channelId?: string | null;
  duration?: string | null;
  trusted?: boolean;
}
export interface FeedSource {
  id: string;
  channelId?: string;
  handle?: string;
  name: { ar: string; en: string };
  category: string;
}
type Get = (url: string) => Promise<string | null>;
export const PER_SOURCE: number;
export const ISLAMIC_WORDS: string[];
export const BLOCKED_WORDS: string[];
export function normalize(s: string): string;
export function isBlocked(text: string): boolean;
export function looksIslamic(text: string): boolean;
export function allowedVideo(hit: CoreHit, trustedChannelIds: Set<string>): boolean;
export function looksRecitation(text: string): boolean;
export function notRecitation(text: string): boolean;
export function allowedFeedTitle(title: string): boolean;
export function allowedChannel(title: string): boolean;
export const RECITATION_WORDS: string[];
export const NON_RECITATION_WORDS: string[];
export const EXCLUDED_PEOPLE: string[];
export function parseFeed(
  xml: string,
  shortsOnly?: boolean,
): { ref: string; title: string; published: string | null }[];
export function channelIdFromPage(html: string): string | null;
export function parseVideoSearch(html: string, max?: number): Required<Omit<CoreHit, "trusted">>[];
export function mix<T extends { id: string; published?: string | null }>(perSource: T[][]): T[];
export function parseChannelVideos(
  html: string,
  max?: number,
): { ref: string; title: string; published: null }[];
export function fetchSource(
  cid: string,
  get: Get,
): Promise<{ ref: string; title: string; published: string | null }[] | null>;
export function buildFeed(
  sources: FeedSource[],
  get: Get,
): Promise<{ schema: string; sources: FeedSource[]; items: Record<string, unknown>[] & { ref: string }[] }>;
export function searchVideos(
  query: string,
  get: Get,
  trustedChannelIds: Set<string>,
): Promise<{
  schema: string;
  query: string;
  items: (Required<Omit<CoreHit, "trusted">> & { trusted: boolean })[];
}>;
