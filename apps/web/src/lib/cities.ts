import citiesJson from "@/generated/cities.json";
import { methodsConfig } from "./prayer";
import type { PrayerPrefs } from "./settings";

export interface City {
  id: string;
  nameAr: string;
  nameEn: string;
  countryAr: string;
  lat: number;
  lng: number;
  tz: string;
  method: string;
}
export const CITIES: readonly City[] = (citiesJson as { cities: City[] }).cities;

export function cityById(id: string): City | undefined {
  return CITIES.find((c) => c.id === id);
}

export interface ResolvedLocation {
  lat: number;
  lng: number;
  tz: string;
  method: string;
  defaultMethod: string;
  city: City | null;
}

export function resolveLocation(p: PrayerPrefs): ResolvedLocation {
  if (p.custom) {
    const def = "mwl";
    return { ...p.custom, defaultMethod: def, method: p.method ?? def, city: null };
  }
  const city = cityById(p.cityId) ?? (CITIES[0] as City);
  const def = city.method in methodsConfig.methods ? city.method : "mwl";
  return { lat: city.lat, lng: city.lng, tz: city.tz, defaultMethod: def, method: p.method ?? def, city };
}
