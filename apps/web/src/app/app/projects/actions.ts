"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const CreateProjectSchema = z.object({
  client_id: z.string().uuid(),
  project_type: z.enum(["initial_research", "monthly_strategy", "campaign", "one_off"]),
  project_name: z.string().optional().or(z.literal("")),
});

export async function createProjectAction(formData: FormData) {
  const parsed = CreateProjectSchema.safeParse({
    client_id: formData.get("client_id"),
    project_type: formData.get("project_type"),
    project_name: formData.get("project_name"),
  });

  if (!parsed.success) return { ok: false as const, error: parsed.error.message };

  const supabase = await createClient();
  const { data: userData } = await supabase.auth.getUser();
  if (!userData.user) return { ok: false as const, error: "未登录" };

  // projects 表目前没有 created_by，这里仅依赖 RLS 通过 client 归属判断（迁移里会补）
  const { error } = await supabase.from("projects").insert({
    client_id: parsed.data.client_id,
    project_type: parsed.data.project_type,
    project_name: parsed.data.project_name || null,
  });

  if (error) return { ok: false as const, error: error.message };

  revalidatePath("/app/projects");
  return { ok: true as const };
}

