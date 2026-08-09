import { useEffect, useState } from 'react';
import { get } from '../lib/http';

type Book = { id: string; title: string; summary?: string; author?: string; publisher?: string };

export default function BooksPage() {
  const [items, setItems] = useState<Book[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    get<Book[]>('/books')
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="content-page">
      <h1>الكتب</h1>
      {loading ? <p className="muted">جاري التحميل…</p> : null}
      {!loading && items.length === 0 ? <p className="muted">لا توجد كتب حالياً.</p> : null}
      <ul className="content-list">
        {items.map((item) => (
          <li key={item.id}>
            <h3>{item.title}</h3>
            {item.author ? <p className="muted">{item.author}</p> : null}
            {item.publisher ? <small className="muted">دار النشر: {item.publisher}</small> : null}
          </li>
        ))}
      </ul>
    </main>
  );
}
