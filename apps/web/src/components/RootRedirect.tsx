"use client";
import { useEffect } from "react";
import { prefsStore } from "@/lib/settings";

export function RootRedirect() {
  useEffect(() => {
    const saved = prefsStore.get().locale;
    window.location.replace(`/${saved ?? "ar"}/`);
  }, []);
  return null;
}
