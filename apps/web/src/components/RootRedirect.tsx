"use client";
import { useEffect } from "react";
import { prefsStore } from "@/lib/settings";
import { withBase } from "@/lib/base-path";

export function RootRedirect() {
  useEffect(() => {
    const saved = prefsStore.get().locale;
    window.location.replace(withBase(`/${saved ?? "ar"}/`));
  }, []);
  return null;
}
