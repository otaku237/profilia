import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase-server'

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || ''

export async function GET(req: NextRequest) {
  const supabase = createServerSupabase()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user || user.email !== ADMIN_EMAIL)
    return NextResponse.json({ error: 'Accès refusé' }, { status: 403 })

  const [{ data: profiles }, { data: conversations }, { data: messages }] = await Promise.all([
    supabase.from('profiles').select('id, name, profile_type, created_at').order('created_at', { ascending: false }),
    supabase.from('conversations').select('id, user_id, created_at'),
    supabase.from('messages').select('id, role, created_at'),
  ])

  const stats = {
    totalUsers: profiles?.length || 0,
    totalConversations: conversations?.length || 0,
    totalMessages: messages?.length || 0,
    userMessages: messages?.filter(m => m.role === 'user').length || 0,
    aiMessages: messages?.filter(m => m.role === 'assistant').length || 0,
    profileBreakdown: (profiles || []).reduce((acc: Record<string, number>, p) => {
      acc[p.profile_type] = (acc[p.profile_type] || 0) + 1
      return acc
    }, {}),
    recentUsers: profiles?.slice(0, 10) || [],
    avgConvsPerUser: profiles?.length
      ? ((conversations?.length || 0) / profiles.length).toFixed(1)
      : 0,
  }

  return NextResponse.json(stats)
}
