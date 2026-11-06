import Link from "next/link";
import { RootRedirect } from "@/components/RootRedirect";

export default function RootPage() {
  return (
    <main id="main">
      <noscript>
        <meta httpEquiv="refresh" content="0; url=/ar/" />
      </noscript>
      <RootRedirect />
      <p>
        <Link href="/ar/">العربية</Link> · <Link href="/en/">English</Link>
      </p>
    </main>
  );
}
