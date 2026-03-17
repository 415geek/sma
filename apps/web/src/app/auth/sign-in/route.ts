import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const formData = await request.formData();
  const email = String(formData.get("email") ?? "").trim();

  if (!email) {
    return NextResponse.redirect(new URL("/login", request.url), { status: 303 });
  }

  const supabase = await createClient();
  const redirectTo = new URL("/auth/callback", request.url).toString();

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: redirectTo },
  });

  const url = new URL("/login", request.url);
  if (error) url.searchParams.set("error", error.message);
  else url.searchParams.set("sent", "1");

  return NextResponse.redirect(url, { status: 303 });
}

