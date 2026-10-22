import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL, key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return response;
  const supabase = createServerClient(url, key, { cookies: { getAll: () => request.cookies.getAll(), setAll(cookiesToSet) { cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value)); response = NextResponse.next({ request }); cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options)); } } });
  const { data: { user } } = await supabase.auth.getUser();
  const pathname = request.nextUrl.pathname;
  if (pathname.startsWith("/channels") && !user) { const target = request.nextUrl.clone(); target.pathname = "/login"; target.searchParams.set("next", pathname); return NextResponse.redirect(target); }
  if (pathname === "/channels/@me" && user) { const target = request.nextUrl.clone(); target.pathname = "/channels/me"; return NextResponse.rewrite(target); }
  if (pathname === "/login" && user) { const target = request.nextUrl.clone(); target.pathname = "/channels/me"; target.search = ""; return NextResponse.redirect(target); }
  return response;
}
