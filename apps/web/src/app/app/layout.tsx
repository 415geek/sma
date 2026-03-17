import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient();
  const { data } = await supabase.auth.getUser();

  if (!data.user) redirect("/login");

  return (
    <div className="min-h-screen bg-zinc-50">
      <header className="border-b bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-6">
            <Link href="/app" className="text-sm font-semibold">
              AOS
            </Link>
            <nav className="flex items-center gap-4 text-sm text-zinc-700">
              <Link href="/app/clients" className="hover:text-black">
                Clients
              </Link>
              <Link href="/app/projects" className="hover:text-black">
                Projects
              </Link>
            </nav>
          </div>
          <form action="/auth/sign-out" method="post">
            <button className="rounded-lg border px-3 py-2 text-sm">退出</button>
          </form>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-6 py-8">{children}</main>
    </div>
  );
}

