import Link from "next/link";
import "@/generated/tokens.css";
import "./globals.css";

export default function NotFound() {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <main id="main">
          <h1>٤٠٤ — الصفحة غير موجودة · Page not found</h1>
          <p>
            <Link href="/ar/">الرئيسية</Link> · <Link href="/en/">Home</Link>
          </p>
        </main>
      </body>
    </html>
  );
}
