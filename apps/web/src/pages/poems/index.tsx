import Link from 'next/link';
import { useEffect, useState } from 'react';
import { get } from '../../lib/http';

type Poem = {
  id: string;
  title: string;
  poet?: { fullName?: string };
};

export default function PoemsPage() {
  const [poems, setPoems] = useState<Poem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    get<Poem[]>('/poems')
      .then(setPoems)
      .catch(() => setPoems([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="content-page">
      <h1>قصائد منصة رواية</h1>
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && poems.length === 0 ? <p className="muted">لا توجد قصائد منشورة حالياً.</p> : null}
      <ul className="content-list">
        {poems.map((p) => (
          <li key={p.id}>
            <Link href={`/poems/${p.id}`}>{p.title}</Link>
            {p.poet?.fullName ? <div className="muted">الشاعر: {p.poet.fullName}</div> : null}
          </li>
        ))}
      </ul>
    </main>
  );
}
