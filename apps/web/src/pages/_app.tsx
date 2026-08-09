import type { AppProps } from 'next/app';
import Head from 'next/head';
import Link from 'next/link';
import '../styles/globals.css';

const nav = [
  { href: '/', label: 'الرئيسية' },
  { href: '/poems', label: 'قصائد' },
  { href: '/poets', label: 'شعراء' },
  { href: '/stories', label: 'قصص' },
  { href: '/books', label: 'كتب' },
  { href: '/search', label: 'بحث' },
];

export default function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <title>رواية</title>
        <meta name="description" content="منصة رواية… ذاكرة التراث العربي" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <div className="app-shell">
        <header className="site-header">
          <Link href="/" className="brand">
            رواية
          </Link>
          <p className="tagline">ذاكرة التراث العربي</p>
          <nav className="site-nav" aria-label="التنقل الرئيسي">
            {nav.map((item) => (
              <Link key={item.href} href={item.href}>
                {item.label}
              </Link>
            ))}
          </nav>
        </header>
        <Component {...pageProps} />
      </div>
    </>
  );
}
