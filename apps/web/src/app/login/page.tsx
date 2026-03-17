import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function LoginPage() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getUser();
  if (data.user) redirect("/app");

  return (
    <div className="min-h-screen bg-zinc-50 p-6">
      <div className="mx-auto max-w-md rounded-2xl border bg-white p-6 shadow-sm">
        <h1 className="text-xl font-semibold">登录 AOS</h1>
        <p className="mt-2 text-sm text-zinc-600">
          使用邮箱登录（Magic link）。上线时建议在 Supabase Auth 里开启邮箱确认与反滥用策略。
        </p>

        <form action="/auth/sign-in" method="post" className="mt-6 space-y-3">
          <label className="block text-sm font-medium text-zinc-800">
            邮箱
            <input
              name="email"
              type="email"
              required
              className="mt-2 w-full rounded-lg border px-3 py-2 text-sm"
              placeholder="you@company.com"
            />
          </label>

          <button
            type="submit"
            className="w-full rounded-lg bg-black px-3 py-2 text-sm font-medium text-white"
          >
            发送登录链接
          </button>
        </form>
      </div>
    </div>
  );
}

