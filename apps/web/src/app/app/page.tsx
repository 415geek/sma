import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

export default async function AppHome() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getUser();

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">欢迎，{data.user?.email}</h1>
      <p className="text-sm text-zinc-600">
        这是 V1 管理台：先完成 Clients / Projects 的最小闭环，后续再接入 Research→Evidence→Insights→Report 工作流。
      </p>
      <div className="flex gap-3">
        <Link className="rounded-lg bg-black px-3 py-2 text-sm text-white" href="/app/clients">
          管理 Clients
        </Link>
        <Link className="rounded-lg border px-3 py-2 text-sm" href="/app/projects">
          管理 Projects
        </Link>
      </div>
    </div>
  );
}

