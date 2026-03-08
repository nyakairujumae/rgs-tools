import { NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { Paddle, Environment } from '@paddle/paddle-node-sdk'

export async function POST(request: Request) {
  try {
    const { priceId, orgId } = await request.json()

    if (!priceId || !orgId) {
      return NextResponse.json({ error: 'Missing priceId or orgId' }, { status: 400 })
    }

    // Verify the user is authenticated and is an admin of this org
    const cookieStore = await cookies()
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll: () => cookieStore.getAll(),
          setAll: () => {},
        },
      }
    )

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data: profile } = await supabase
      .from('users')
      .select('role, organization_id, email')
      .eq('id', user.id)
      .single()

    if (!profile || profile.role !== 'admin' || profile.organization_id !== orgId) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const paddle = new Paddle(process.env.PADDLE_API_KEY!, {
      environment: process.env.NEXT_PUBLIC_PADDLE_ENV === 'sandbox'
        ? Environment.Sandbox
        : Environment.Production,
    })

    // Get or create Paddle customer
    const { data: org } = await supabase
      .from('organizations')
      .select('paddle_customer_id, name')
      .eq('id', orgId)
      .single()

    let customerId = org?.paddle_customer_id

    if (!customerId) {
      const customer = await paddle.customers.create({
        email: user.email!,
        name: org?.name || user.email!,
      })
      customerId = customer.id

      await supabase
        .from('organizations')
        .update({ paddle_customer_id: customerId })
        .eq('id', orgId)
    }

    // Create a transaction (Paddle's checkout session equivalent)
    const transaction = await paddle.transactions.create({
      items: [{ priceId, quantity: 1 }],
      customerId,
      customData: { org_id: orgId },
    })

    return NextResponse.json({ transactionId: transaction.id })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal error'
    console.error('Paddle checkout error:', message)
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
