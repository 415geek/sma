import { createClient } from "@/lib/supabase/server";
import { createProjectAction } from "./actions";

export default async function ProjectsPage({
  searchParams,
}: {
  searchParams: Promise<{ client?: string }>;
}) {
  const { client } = await searchParams;
  const supabase = await createClient();

  const { data: clients } = await supabase.from("clients").select("id, brand_name").order("created_at", {
    ascending: false,
  });

  const { data: projects, error } = await supabase
    .from("projects")
    .select("id, project_type, project_name, status, target_month, created_at, client_id")
    .order("created_at", { ascending: false });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Projects</h1>
        <p className="mt-1 text-sm text-zinc-600">按 Client 创建项目，并驱动后续工作流状态机。</p>
      </div>

      <div className="rounded-2xl border bg-white p-5">
        <h2 className="text-sm font-semibold">创建 Project</h2>
        <form action={createProjectAction} className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2">
          <select
            name="client_id"
            required
            defaultValue={client ?? ""}
            className="rounded-lg border px-3 py-2 text-sm"
          >
            <option value="" disabled>
              选择 Client（必选）
            </option>
            {(clients ?? []).map((c) => (
              <option key={c.id} value={c.id}>
                {c.brand_name}
              </option>
            ))}
          </select>

          <select name="project_type" required className="rounded-lg border px-3 py-2 text-sm" defaultValue="monthly_strategy">
            <option value="initial_research">initial_research</option>
            <option value="monthly_strategy">monthly_strategy</option>
            <option value="campaign">campaign</option>
            <option value="one_off">one_off</option>
          </select>

          <input name="project_name" placeholder="项目名（可选）" className="rounded-lg border px-3 py-2 text-sm md:col-span-2" />

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
          ) : projects?.length ? (
            <ul className="divide-y">
              {projects.map((p) => (
                <li key={p.id} className="py-3">
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <div className="text-sm font-medium">
                        {p.project_name || p.project_type}{" "}
                        <span className="ml-2 rounded-md bg-zinc-100 px-2 py-0.5 text-xs text-zinc-700">
                          {p.status}
                        </span>
                      </div>
                      <div className="text-xs text-zinc-600">{p.id}</div>
                    </div>
                  </div>
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

