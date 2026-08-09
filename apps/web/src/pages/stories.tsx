import { useEffect, useState } from 'react';
import { get } from '../lib/http';

type Story = { id: string; title: string; summary?: string; location?: string };

export default function StoriesPage() {
  const [items, setItems] = useState<Story[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    get<Story[]>('/stories')
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="content-page">
      <h1>القصص</h1>
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && items.length === 0 ? <p className="muted">لا توجد قصص حالياً.</p> : null}
      <ul className="content-list">
        {items.map((item) => (
          <li key={item.id}>
            <h3>{item.title}</h3>
            {item.summary ? <p className="muted">{item.summary}</p> : null}
            {item.location ? <small className="muted">{item.location}</small> : null}
          </li>
        ))}
      </ul>
    </main>
  );
}
