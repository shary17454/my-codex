import { useEffect, useState } from 'react';
import { get } from '../lib/http';

type Poet = { id: string; fullName: string; knownAs?: string; region?: string };

export default function PoetsPage() {
  const [poets, setPoets] = useState<Poet[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    get<Poet[]>('/poets')
      .then(setPoets)
      .catch(() => setPoets([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="content-page">
      <h1>الشعراء</h1>
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && poets.length === 0 ? <p className="muted">لا يوجد شعراء حالياً.</p> : null}
      <ul className="content-list">
        {poets.map((p) => (
          <li key={p.id}>
            <h3>{p.fullName}</h3>
            {p.knownAs ? <p className="muted">{p.knownAs}</p> : null}
            {p.region ? <small className="muted">{p.region}</small> : null}
          </li>
        ))}
      </ul>
    </main>
  );
}
