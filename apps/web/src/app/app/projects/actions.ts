"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const CreateProjectSchema = z.object({
  client_id: z.string().uuid(),
  project_type: z.enum(["initial_research", "monthly_strategy", "campaign", "one_off"]),
  project_name: z.string().optional().or(z.literal("")),
});

async function runCreateProject(formData: FormData) {
  const parsed = CreateProjectSchema.safeParse({
    client_id: formData.get("client_id"),
    project_type: formData.get("project_type"),
    project_name: formData.get("project_name"),
  });

  if (!parsed.success) return { ok: false as const, error: parsed.error.message };

  const supabase = await createClient();
  const { data: userData } = await supabase.auth.getUser();
  if (!userData.user) return { ok: false as const, error: "未登录" };

  const { error } = await supabase.from("projects").insert({
    client_id: parsed.data.client_id,
    project_type: parsed.data.project_type,
    project_name: parsed.data.project_name || null,
  });

  if (error) return { ok: false as const, error: error.message };

  return { ok: true as const };
}

/** Form action: must return void (Next.js <form action> typing). */
export async function createProjectAction(formData: FormData): Promise<void> {
  const result = await runCreateProject(formData);
  const clientId = formData.get("client_id");
  const clientQ =
    typeof clientId === "string" && clientId.length > 0 ? `client=${encodeURIComponent(clientId)}&` : "";

  if (!result.ok) {
    redirect(`/app/projects?${clientQ}e=${encodeURIComponent(result.error)}`);
  }
  revalidatePath("/app/projects");
  redirect(`/app/projects?${clientQ}ok=1`);
}

