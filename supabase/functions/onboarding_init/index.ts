// Серверная инициализация онбординга (заготовка).
// Возвращает строгий JSON для клиента; при отсутствии секретов — безопасный fallback.

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const fallback = {
    hidden_class: null as string | null,
    hidden_class_reason: null as string | null,
    quests: [] as unknown[],
    note: "fallback: configure AI secrets and prompt pipeline on the server",
  };

  try {
    const apiKey = Deno.env.get("ONBOARDING_LLM_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify(fallback), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Здесь позже: вызов модели, валидация схемы, лимиты.
    return new Response(JSON.stringify(fallback), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(
      JSON.stringify({
        ...fallback,
        error: String(e),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
