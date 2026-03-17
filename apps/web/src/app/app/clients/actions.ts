"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const CreateClientSchema = z.object({
  brand_name: z.string().min(1),
  industry: z.string().min(1),
  website: z.string().url().optional().or(z.literal("")),
  city: z.string().optional().or(z.literal("")),
  state: z.string().optional().or(z.literal("")),
});

export async function createClientAction(formData: FormData) {
  const parsed = CreateClientSchema.safeParse({
    brand_name: formData.get("brand_name"),
    industry: formData.get("industry"),
    website: formData.get("website"),
    city: formData.get("city"),
    state: formData.get("state"),
  });

  if (!parsed.success) {
    return { ok: false as const, error: parsed.error.message };
  }

  const supabase = await createClient();
  const { data: userData } = await supabase.auth.getUser();
  if (!userData.user) return { ok: false as const, error: "未登录" };

  const { error } = await supabase.from("clients").insert({
    brand_name: parsed.data.brand_name,
    industry: parsed.data.industry,
    website: parsed.data.website || null,
    city: parsed.data.city || null,
    state: parsed.data.state || null,
    created_by: userData.user.id,
  });

  if (error) return { ok: false as const, error: error.message };

  revalidatePath("/app/clients");
  return { ok: true as const };
}

