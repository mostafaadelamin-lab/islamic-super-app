import Link from "next/link";
import { RootRedirect } from "@/components/RootRedirect";
import { withBase } from "@/lib/base-path";

export default function RootPage() {
  return (
    <main id="main">
      <noscript>
        <meta httpEquiv="refresh" content={`0; url=${withBase("/ar/")}`} />
      </noscript>
      <RootRedirect />
      <p>
        <Link href="/ar/">العربية</Link> · <Link href="/en/">English</Link>
      </p>
    </main>
  );
}
