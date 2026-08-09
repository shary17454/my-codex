import Link from 'next/link';
import { useEffect, useState } from 'react';
import { get } from '../lib/http';

type HomePayload = {
  hero: string;
  featuredSections: string[];
};

const sectionHref = (section: string) => {
  if (section.includes('شعراء') || section.includes('شاعر')) return '/poets';
  if (section.includes('قصائد') || section.includes('شعر')) return '/poems';
  if (section.includes('قصص')) return '/stories';
  if (section.includes('كتب') || section.includes('مراجع')) return '/books';
  return '/search';
};

export default function Home() {
  const [data, setData] = useState<HomePayload | null>(null);

  useEffect(() => {
    get<HomePayload>('/home')
      .then(setData)
      .catch(() =>
        setData({
          hero: 'رواية… ذاكرة التراث العربي',
          featuredSections: ['الشعر', 'الشعراء', 'القصص', 'الكتب والمراجع'],
        }),
      );
  }, []);

  return (
    <main className="home">
      <h1>{data?.hero || 'رواية… ذاكرة التراث العربي'}</h1>
      <p className="muted">استكشف القصائد والشعراء والقصص والمراجع من مصدر واحد.</p>

      <section>
        <h2>الأقسام المختارة</h2>
        <ul className="section-grid">
          {(data?.featuredSections || []).map((item) => (
            <li key={item}>
              <Link href={sectionHref(item)}>{item}</Link>
            </li>
          ))}
        </ul>
      </section>

      <section className="cta-row" aria-label="اختصارات">
        <Link href="/search">ابدأ البحث</Link>
        <Link href="/poems" className="secondary">
          القصائد
        </Link>
        <Link href="/poets" className="secondary">
          الشعراء
        </Link>
        <Link href="/reading-lists" className="secondary">
          قوائم القراءة
        </Link>
      </section>
    </main>
  );
}
