import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { Paddle, Environment, EventName } from '@paddle/paddle-node-sdk'

// Use service role key server-side to bypass RLS for webhook updates
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

const paddle = new Paddle(process.env.PADDLE_API_KEY!, {
  environment: process.env.NEXT_PUBLIC_PADDLE_ENV === 'sandbox'
    ? Environment.sandbox
    : Environment.production,
})

export async function POST(request: Request) {
  const signature = request.headers.get('paddle-signature') ?? ''
  const rawBody = await request.text()

  try {
    const event = await paddle.webhooks.unmarshal(
      rawBody,
      process.env.PADDLE_WEBHOOK_SECRET!,
      signature
    )

    const orgId: string | undefined =
      (event.data as { customData?: { org_id?: string } })?.customData?.org_id

    switch (event.eventType) {
      case EventName.SubscriptionActivated:
      case EventName.SubscriptionUpdated: {
        const sub = event.data as {
          id: string
          status: string
          items?: Array<{ price?: { productId?: string } }>
          currentBillingPeriod?: { endsAt?: string }
          customData?: { org_id?: string }
        }
        const resolvedOrgId = orgId || sub.customData?.org_id
        if (!resolvedOrgId) break

        const plan = derivePlan(sub.items?.[0]?.price?.productId)

        await supabase
          .from('organizations')
          .update({
            paddle_subscription_id: sub.id,
            subscription_plan: plan,
            subscription_status: sub.status === 'active' ? 'active' : sub.status,
            subscription_ends_at: sub.currentBillingPeriod?.endsAt ?? null,
          })
          .eq('id', resolvedOrgId)
        break
      }

      case EventName.SubscriptionCanceled: {
        const sub = event.data as {
          id: string
          customData?: { org_id?: string }
          scheduledChange?: { effectiveAt?: string }
        }
        const resolvedOrgId = orgId || sub.customData?.org_id
        if (!resolvedOrgId) break

        await supabase
          .from('organizations')
          .update({
            subscription_status: 'cancelled',
            subscription_ends_at: sub.scheduledChange?.effectiveAt ?? null,
          })
          .eq('id', resolvedOrgId)
        break
      }

      case EventName.SubscriptionPastDue: {
        const sub = event.data as { customData?: { org_id?: string } }
        const resolvedOrgId = orgId || sub.customData?.org_id
        if (!resolvedOrgId) break

        await supabase
          .from('organizations')
          .update({ subscription_status: 'past_due' })
          .eq('id', resolvedOrgId)
        break
      }
    }

    return NextResponse.json({ received: true })
  } catch (err) {
    console.error('Paddle webhook error:', err)
    return NextResponse.json({ error: 'Webhook processing failed' }, { status: 400 })
  }
}

function derivePlan(productId?: string): string {
  if (!productId) return 'starter'
  const id = productId.toLowerCase()
  if (id.includes('pro')) return 'pro'
  if (id.includes('starter')) return 'starter'
  return 'starter'
}
