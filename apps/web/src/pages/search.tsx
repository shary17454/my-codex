import { FormEvent, useState } from 'react';
import { get } from '../lib/http';

type SearchHit = { id: string; title?: string; name?: string };

export default function SearchPage() {
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const run = async (event?: FormEvent) => {
    event?.preventDefault();
    if (!q.trim()) return;
    setLoading(true);
    setError('');
    try {
      const data = await get<{ poems?: SearchHit[]; stories?: SearchHit[]; books?: SearchHit[] }>(
        `/search?query=${encodeURIComponent(q.trim())}`,
      );
      setHits([...(data?.poems || []), ...(data?.stories || []), ...(data?.books || [])]);
    } catch {
      setHits([]);
      setError('تعذّر تنفيذ البحث حالياً');
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="search-page">
      <h1>البحث في رواية</h1>
      <form className="search-bar" onSubmit={run}>
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="ابحث عن شاعر أو قصيدة..."
          aria-label="كلمة البحث"
        />
        <button type="submit" disabled={loading}>
          {loading ? '...' : 'بحث'}
        </button>
      </form>
      {error ? <p className="muted">{error}</p> : null}
      {!loading && !error && hits.length === 0 && q.trim() ? (
        <p className="muted">لا توجد نتائج مطابقة.</p>
      ) : null}
      <ul className="content-list">
        {hits.map((item) => (
          <li key={item.id}>{item.title || item.name}</li>
        ))}
      </ul>
    </main>
  );
}
