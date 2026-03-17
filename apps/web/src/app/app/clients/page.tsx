import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { createClientAction } from "./actions";

export default async function ClientsPage({
  searchParams,
}: {
  searchParams: Promise<{ e?: string; ok?: string }>;
}) {
  const { e, ok } = await searchParams;
  const supabase = await createClient();
  const { data: userData } = await supabase.auth.getUser();

  const { data: clients, error } = await supabase
    .from("clients")
    .select("id, brand_name, industry, city, state, created_at")
    .order("created_at", { ascending: false });

  return (
    <div className="space-y-6">
      <div className="flex items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Clients</h1>
          <p className="mt-1 text-sm text-zinc-600">当前登录：{userData.user?.email}</p>
        </div>
      </div>

      <div className="rounded-2xl border bg-white p-5">
        <h2 className="text-sm font-semibold">创建 Client</h2>
        {e ? (
          <p className="mt-2 text-sm text-red-600" role="alert">
            {e}
          </p>
        ) : null}
        {ok ? (
          <p className="mt-2 text-sm text-green-700" role="status">
            创建成功
          </p>
        ) : null}
        <form action={createClientAction} className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2">
          <input
            name="brand_name"
            placeholder="品牌名（必填）"
            className="rounded-lg border px-3 py-2 text-sm"
            required
          />
          <input
            name="industry"
            placeholder="行业（必填）"
            className="rounded-lg border px-3 py-2 text-sm"
            required
          />
          <input name="website" placeholder="网站（可选）" className="rounded-lg border px-3 py-2 text-sm" />
          <div className="grid grid-cols-2 gap-3">
            <input name="city" placeholder="城市" className="rounded-lg border px-3 py-2 text-sm" />
            <input name="state" placeholder="州/省" className="rounded-lg border px-3 py-2 text-sm" />
          </div>
          <div className="md:col-span-2">
            <button className="rounded-lg bg-black px-3 py-2 text-sm text-white">创建</button>
          </div>
        </form>
      </div>

      <div className="rounded-2xl border bg-white">
        <div className="border-b px-5 py-3 text-sm font-semibold">列表</div>
        <div className="p-5">
          {error ? (
            <p className="text-sm text-red-600">读取失败：{error.message}</p>
          ) : clients?.length ? (
            <ul className="divide-y">
              {clients.map((c) => (
                <li key={c.id} className="flex items-center justify-between gap-4 py-3">
                  <div>
                    <div className="text-sm font-medium">{c.brand_name}</div>
                    <div className="text-xs text-zinc-600">
                      {c.industry}
                      {c.city || c.state ? ` · ${[c.city, c.state].filter(Boolean).join(", ")}` : ""}
                    </div>
                  </div>
                  <Link className="text-sm underline" href={`/app/projects?client=${c.id}`}>
                    创建 Project
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-zinc-600">暂无数据</p>
          )}
        </div>
      </div>
    </div>
  );
}

