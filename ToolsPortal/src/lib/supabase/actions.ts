import { createClient } from './client'
import type {
  Tool,
  Technician,
  ToolIssue,
  ToolHistory,
  Certification,
  CertificationStatus,
  MaintenanceSchedule,
  AdminPosition,
  User,
} from '../types/database'

const supabase = () => createClient()

// ── Tool History ──

export async function recordToolHistory(params: {
  tool_id: string
  tool_name: string
  action: string
  description: string
  old_value?: string | null
  new_value?: string | null
  performed_by?: string | null
  performed_by_role?: string
  location?: string | null
  notes?: string | null
  metadata?: Record<string, unknown> | null
}) {
  const { error } = await supabase().from('tool_history').insert({
    tool_id: params.tool_id,
    tool_name: params.tool_name,
    action: params.action,
    description: params.description,
    old_value: params.old_value || null,
    new_value: params.new_value || null,
    performed_by: params.performed_by || null,
    performed_by_role: params.performed_by_role || 'admin',
    location: params.location || null,
    notes: params.notes || null,
    metadata: params.metadata || null,
  })
  if (error) console.error('Failed to record history:', error)
}

// ── Admin Notifications ──

export async function createAdminNotification(params: {
  title: string
  message: string
  technician_name?: string
  technician_email?: string
  type: string
  data?: Record<string, unknown>
}) {
  const { error } = await supabase().rpc('create_admin_notification', {
    p_title: params.title,
    p_message: params.message,
    p_technician_name: params.technician_name || '',
    p_technician_email: params.technician_email || '',
    p_type: params.type,
    p_data: params.data || null,
  })
  if (error) {
    // Fallback: direct insert if RPC doesn't exist
    await supabase().from('admin_notifications').insert({
      title: params.title,
      message: params.message,
      technician_name: params.technician_name || '',
      technician_email: params.technician_email || '',
      type: params.type,
      data: params.data || null,
      is_read: false,
      timestamp: new Date().toISOString(),
    })
  }
}

// ── Push Notifications (FCM via Edge Function) ──

async function sendPushToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  try {
    await fetch('/api/send-push', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: userId, title, body, ...(data ? { data } : {}) }),
    })
  } catch (e) {
    console.error('Push notification to user error:', e)
  }
}

async function sendPushToAdmins(
  title: string,
  body: string,
  data?: Record<string, string>
) {
  try {
    // Get admin user IDs
    let admins: { id: string }[] = []
    try {
      const rpcResult = await supabase().rpc('get_admin_user_ids')
      if (Array.isArray(rpcResult.data)) admins = rpcResult.data
    } catch {
      const { data: users } = await supabase()
        .from('users')
        .select('id')
        .eq('role', 'admin')
      if (users) admins = users
    }

    // Send push to each admin via server-side API route (avoids auth issues with browser client)
    for (const admin of admins) {
      await fetch('/api/send-push', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: admin.id, title, body, ...(data ? { data } : {}) }),
      })
    }
  } catch (e) {
    console.error('Push notification error:', e)
  }
}

// ── TOOL CRUD ──

export async function addTool(
  tool: Omit<Tool, 'id' | 'created_at' | 'updated_at'>,
  performedBy?: string
): Promise<Tool | null> {
  const now = new Date().toISOString()

  const insertPayload: Record<string, unknown> = {
    name: tool.name,
    category: tool.category,
    brand: tool.brand || null,
    model: tool.model || null,
    serial_number: tool.serial_number || null,
    purchase_date: tool.purchase_date || null,
    purchase_price: tool.purchase_price || null,
    current_value: tool.current_value || null,
    condition: tool.condition || 'Good',
    location: tool.location || null,
    assigned_to: tool.assigned_to || null,
    status: tool.assigned_to ? 'In Use' : 'Available',
    tool_type: 'inventory',
    image_path: tool.image_path || null,
    notes: tool.notes || null,
    created_at: now,
    updated_at: now,
  }
  if (tool.owned_by !== undefined) insertPayload.owned_by = tool.owned_by

  const { data, error } = await supabase()
    .from('tools')
    .insert(insertPayload)
    .select()
    .single()

  if (error) {
    console.error('Failed to add tool:', error)
    return null
  }

  // Record history
  await recordToolHistory({
    tool_id: data.id,
    tool_name: data.name,
    action: 'Created',
    description: `${data.name} was added to inventory`,
    performed_by: performedBy || 'Admin',
    performed_by_role: 'admin',
  })

  // Send push notification to admins (non-blocking, same as Flutter app)
  sendPushToAdmins(
    'New Tool Added',
    `${data.name} has been added to the inventory`,
    { type: 'tool_added', tool_id: data.id, tool_name: data.name }
  ).catch(() => {})

  return data
}

export async function updateTool(
  toolId: string,
  updates: Partial<Tool>,
  oldTool: Tool,
  performedBy?: string
): Promise<Tool | null> {
  const { data, error } = await supabase()
    .from('tools')
    .update({
      ...updates,
      updated_at: new Date().toISOString(),
    })
    .eq('id', toolId)
    .select()
    .single()

  if (error) {
    console.error('Failed to update tool:', error)
    return null
  }

  // Record history for changed fields
  const trackFields: (keyof Tool)[] = [
    'name', 'category', 'brand', 'model', 'serial_number',
    'condition', 'location', 'status', 'assigned_to', 'notes',
  ]

  for (const field of trackFields) {
    if (updates[field] !== undefined && updates[field] !== oldTool[field]) {
      await recordToolHistory({
        tool_id: toolId,
        tool_name: data.name,
        action: field === 'status' ? 'Status Changed' : field === 'location' ? 'Location Changed' : 'Updated',
        description: `${field.replace(/_/g, ' ')} changed from "${oldTool[field] || 'none'}" to "${updates[field]}"`,
        old_value: String(oldTool[field] ?? ''),
        new_value: String(updates[field] ?? ''),
        performed_by: performedBy || 'Admin',
        performed_by_role: 'admin',
      })
    }
  }

  return data
}

export async function deleteTool(toolId: string): Promise<boolean> {
  const { error } = await supabase()
    .from('tools')
    .delete()
    .eq('id', toolId)

  if (error) {
    console.error('Failed to delete tool:', error)
    return false
  }

  return true
}

// ── ASSIGN TOOL ──

export async function assignTool(
  toolId: string,
  toolName: string,
  technicianUserId: string,
  technicianName: string,
  performedBy?: string
): Promise<boolean> {
  // Update tool
  const { error } = await supabase()
    .from('tools')
    .update({
      status: 'In Use',
      assigned_to: technicianUserId,
      updated_at: new Date().toISOString(),
    })
    .eq('id', toolId)

  if (error) {
    console.error('Failed to assign tool:', error)
    return false
  }

  // Try to create assignment record (non-critical)
  try {
    await supabase().from('assignments').insert({
      tool_id: toolId,
      technician_id: technicianUserId,
      assignment_date: new Date().toISOString().split('T')[0],
    })
  } catch {
    // assignments table may not exist - non-critical
  }

  // Record history
  await recordToolHistory({
    tool_id: toolId,
    tool_name: toolName,
    action: 'Assigned',
    description: `${toolName} assigned to ${technicianName}`,
    new_value: technicianName,
    performed_by: performedBy || 'Admin',
    performed_by_role: 'admin',
  })

  // Notify technician (same as app: technician-facing type is tool_assigned)
  sendPushToUser(
    technicianUserId,
    'Tool Assigned to You',
    `${toolName} has been assigned to you. Open the app to view and accept.`,
    {
      type: 'tool_assigned',
      tool_id: toolId,
      tool_name: toolName,
      assigned_by: performedBy || 'Admin',
    }
  ).catch(() => {})

  return true
}

export async function unassignTool(
  toolId: string,
  toolName: string,
  performedBy?: string
): Promise<boolean> {
  const { error } = await supabase()
    .from('tools')
    .update({
      status: 'Available',
      assigned_to: null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', toolId)

  if (error) {
    console.error('Failed to unassign tool:', error)
    return false
  }

  await recordToolHistory({
    tool_id: toolId,
    tool_name: toolName,
    action: 'Returned',
    description: `${toolName} returned to inventory`,
    performed_by: performedBy || 'Admin',
    performed_by_role: 'admin',
  })

  return true
}

// ── TECHNICIAN CRUD ──

export async function addTechnician(
  tech: Omit<Technician, 'id' | 'created_at'>
): Promise<Technician | null> {
  const { data, error } = await supabase()
    .from('technicians')
    .insert({
      name: tech.name,
      employee_id: tech.employee_id || null,
      phone: tech.phone || null,
      email: tech.email || null,
      department: tech.department || null,
      hire_date: tech.hire_date || null,
      status: tech.status || 'Active',
      profile_picture_url: tech.profile_picture_url || null,
      user_id: tech.user_id || null,
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to add technician:', error)
    return null
  }

  return data
}

export async function updateTechnician(
  techId: string,
  updates: Partial<Technician>
): Promise<Technician | null> {
  const { data, error } = await supabase()
    .from('technicians')
    .update(updates)
    .eq('id', techId)
    .select()
    .single()

  if (error) {
    console.error('Failed to update technician:', error)
    return null
  }

  return data
}

export async function deleteTechnician(techId: string): Promise<boolean> {
  const { error } = await supabase()
    .from('technicians')
    .delete()
    .eq('id', techId)

  if (error) {
    console.error('Failed to delete technician:', error)
    return false
  }

  return true
}

// ── ISSUE OPERATIONS ──

export async function addIssue(
  issue: Omit<ToolIssue, 'id'>,
  technicianName: string,
  technicianEmail: string
): Promise<ToolIssue | null> {
  const { data, error } = await supabase()
    .from('tool_issues')
    .insert({
      tool_id: issue.tool_id,
      tool_name: issue.tool_name,
      reported_by: issue.reported_by,
      reported_by_user_id: issue.reported_by_user_id || null,
      issue_type: issue.issue_type,
      description: issue.description,
      priority: issue.priority,
      status: 'Open',
      reported_at: new Date().toISOString(),
      location: issue.location || null,
      estimated_cost: issue.estimated_cost || null,
      attachments: issue.attachments || null,
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to add issue:', error)
    return null
  }

  // Create admin notification
  await createAdminNotification({
    title: 'Issue Report',
    message: `${technicianName} reported a ${issue.issue_type.toLowerCase()} issue for ${issue.tool_name}`,
    technician_name: technicianName,
    technician_email: technicianEmail,
    type: 'issue_report',
    data: {
      issue_id: data.id,
      tool_id: issue.tool_id,
      tool_name: issue.tool_name,
      issue_type: issue.issue_type,
      priority: issue.priority,
    },
  })

  return data
}

export async function updateIssueStatus(
  issueId: string,
  newStatus: string,
  extra?: {
    assigned_to?: string
    assigned_to_user_id?: string
    resolution?: string
  }
): Promise<boolean> {
  const updates: Record<string, unknown> = { status: newStatus }

  if (extra?.assigned_to) updates.assigned_to = extra.assigned_to
  if (extra?.assigned_to_user_id) updates.assigned_to_user_id = extra.assigned_to_user_id
  if (extra?.resolution) updates.resolution = extra.resolution
  if (newStatus === 'Resolved' || newStatus === 'Closed') {
    updates.resolved_at = new Date().toISOString()
  }

  const { error } = await supabase()
    .from('tool_issues')
    .update(updates)
    .eq('id', issueId)

  if (error) {
    console.error('Failed to update issue:', error)
    return false
  }

  return true
}

// ── APPROVAL OPERATIONS ──

export async function approveWorkflow(
  workflowId: string,
  approvedBy: string,
  comments?: string
): Promise<boolean> {
  const { error } = await supabase().rpc('approve_workflow', {
    p_workflow_id: workflowId,
    p_approved_by: approvedBy,
    p_comments: comments || '',
  })

  if (error) {
    // Fallback: direct update
    const { error: updateError } = await supabase()
      .from('approval_workflows')
      .update({
        status: 'Approved',
        approved_by: approvedBy,
        approved_date: new Date().toISOString(),
        comments: comments || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', workflowId)

    if (updateError) {
      console.error('Failed to approve workflow:', updateError)
      return false
    }
  }

  return true
}

export async function rejectWorkflow(
  workflowId: string,
  rejectedBy: string,
  reason: string
): Promise<boolean> {
  const { error } = await supabase().rpc('reject_workflow', {
    p_workflow_id: workflowId,
    p_rejected_by: rejectedBy,
    p_rejection_reason: reason,
  })

  if (error) {
    // Fallback: direct update
    const { error: updateError } = await supabase()
      .from('approval_workflows')
      .update({
        status: 'Rejected',
        rejected_by: rejectedBy,
        rejected_date: new Date().toISOString(),
        rejection_reason: reason,
        updated_at: new Date().toISOString(),
      })
      .eq('id', workflowId)

    if (updateError) {
      console.error('Failed to reject workflow:', updateError)
      return false
    }
  }

  return true
}

// ── USER APPROVAL ──

export async function approvePendingUser(
  userId: string,
  approvedBy: string
): Promise<boolean> {
  const { error } = await supabase().rpc('approve_pending_user', {
    p_user_id: userId,
    p_approved_by: approvedBy,
  })

  if (error) {
    console.error('Failed to approve user:', error)
    return false
  }

  return true
}

export async function rejectPendingUser(
  userId: string,
  rejectedBy: string,
  reason: string
): Promise<boolean> {
  const { error } = await supabase().rpc('reject_pending_user', {
    p_user_id: userId,
    p_rejected_by: rejectedBy,
    p_rejection_reason: reason,
  })

  if (error) {
    console.error('Failed to reject user:', error)
    return false
  }

  return true
}

// ── IMAGE UPLOAD ──

export async function uploadToolImage(file: File): Promise<string | null> {
  const fileName = `tool_images/${Date.now()}_${file.name}`
  const { data, error } = await supabase()
    .storage
    .from('technician-images')
    .upload(fileName, file)

  if (error) {
    console.error('Failed to upload image:', error)
    return null
  }

  const { data: urlData } = supabase()
    .storage
    .from('technician-images')
    .getPublicUrl(data.path)

  return urlData.publicUrl
}

// ── ADMIN POSITION MANAGEMENT ──

export async function fetchAdminPositions(): Promise<AdminPosition[]> {
  const { data, error } = await supabase()
    .from('admin_positions')
    .select('*, position_permissions(*)')
    .eq('is_active', true)
    .order('name')

  if (error) {
    console.error('Failed to fetch positions:', error)
    return []
  }
  return data || []
}

export async function fetchAdmins(): Promise<User[]> {
  const { data, error } = await supabase()
    .from('users')
    .select('id, email, full_name, role, position_id, status, created_at')
    .eq('role', 'admin')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Failed to fetch admins:', error)
    return []
  }
  return (data || []) as User[]
}

export async function getUserPosition(userId: string): Promise<AdminPosition | null> {
  const { data: user } = await supabase()
    .from('users')
    .select('position_id')
    .eq('id', userId)
    .maybeSingle()

  if (!user?.position_id) return null

  const { data: position } = await supabase()
    .from('admin_positions')
    .select('*, position_permissions(*)')
    .eq('id', user.position_id)
    .single()

  return position || null
}

export async function inviteAdmin(
  email: string,
  name: string,
  positionId: string
): Promise<{ userId?: string; error?: string }> {
  const client = supabase()
  try {
    // Try edge function first (same as Flutter app)
    const { data, error } = await client.functions.invoke('invite-admin', {
      body: { email, full_name: name, position_id: positionId },
    })

    if (error) {
      console.error('Edge function error:', error)
      // Fallback: check if user already exists and promote them
      return await inviteAdminFallback(email, name, positionId)
    }

    const userId = data?.user_id || data?.id
    if (userId) {
      await client.rpc('update_admin_user', {
        p_user_id: userId,
        p_full_name: name,
        p_status: 'Active',
        p_position_id: positionId,
      })
    }

    return { userId }
  } catch (e: unknown) {
    console.error('Invite admin error:', e)
    return await inviteAdminFallback(email, name, positionId)
  }
}

async function inviteAdminFallback(
  email: string,
  name: string,
  positionId: string
): Promise<{ userId?: string; error?: string }> {
  try {
    const client = supabase()
    // Check if user already exists in the system
    const { data: existing } = await client
      .from('users')
      .select('id')
      .eq('email', email)
      .maybeSingle()

    if (existing) {
      // User exists — promote to admin with position
      await client
        .from('users')
        .update({ role: 'admin', position_id: positionId, full_name: name })
        .eq('id', existing.id)
      return { userId: existing.id }
    }

    return { error: 'Edge function unavailable from web. Please use the mobile app to send the invite, or ask the user to register first.' }
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'Failed to invite admin'
    return { error: msg }
  }
}

export async function updateAdmin(
  userId: string,
  name: string,
  status: string,
  positionId: string
): Promise<boolean> {
  const { error } = await supabase().rpc('update_admin_user', {
    p_user_id: userId,
    p_full_name: name,
    p_status: status,
    p_position_id: positionId,
  })

  if (error) {
    console.error('Failed to update admin:', error)
    // Fallback: direct update
    const { error: fallbackError } = await supabase()
      .from('users')
      .update({ full_name: name, position_id: positionId })
      .eq('id', userId)
    if (fallbackError) {
      console.error('Fallback update failed:', fallbackError)
      return false
    }
  }
  return true
}

export async function deleteAdmin(userId: string): Promise<boolean> {
  const { error } = await supabase()
    .from('users')
    .delete()
    .eq('id', userId)

  if (error) {
    console.error('Failed to delete admin:', error)
    return false
  }
  return true
}

// ── CALIBRATION / CERTIFICATION ──

export async function addCalibrationRecord(params: {
  tool_id: string
  tool_name: string
  certification_number: string
  issuing_authority: string
  issue_date: string
  expiry_date: string
  inspector_name?: string
  notes?: string
  location?: string
}, performedBy?: string): Promise<Certification | null> {
  const { data, error } = await supabase()
    .from('certifications')
    .insert({
      tool_id: params.tool_id,
      tool_name: params.tool_name,
      certification_type: 'Calibration Certificate',
      certification_number: params.certification_number,
      issuing_authority: params.issuing_authority,
      issue_date: params.issue_date,
      expiry_date: params.expiry_date,
      status: 'Valid',
      inspector_name: params.inspector_name || null,
      notes: params.notes || null,
      location: params.location || null,
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to add calibration record:', error)
    return null
  }

  await recordToolHistory({
    tool_id: params.tool_id,
    tool_name: params.tool_name,
    action: 'Calibrated',
    description: `${params.tool_name} calibrated — certificate ${params.certification_number}`,
    new_value: `Valid until ${params.expiry_date}`,
    performed_by: performedBy || 'Admin',
    performed_by_role: 'admin',
  })

  return data
}

export async function updateCalibrationRecord(
  id: string,
  updates: Partial<Certification>
): Promise<Certification | null> {
  const { data, error } = await supabase()
    .from('certifications')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single()

  if (error) {
    console.error('Failed to update calibration record:', error)
    return null
  }
  return data
}

export async function deleteCalibrationRecord(id: string): Promise<boolean> {
  const { error } = await supabase()
    .from('certifications')
    .delete()
    .eq('id', id)

  if (error) {
    console.error('Failed to delete calibration record:', error)
    return false
  }
  return true
}

// ── GENERIC CERTIFICATION CRUD ──

export async function addCertification(params: {
  tool_id: string
  tool_name: string
  certification_type: string
  certification_number: string
  issuing_authority: string
  issue_date: string
  expiry_date: string
  status?: CertificationStatus
  inspector_name?: string
  notes?: string
  location?: string
}, performedBy?: string): Promise<Certification | null> {
  const { data, error } = await supabase()
    .from('certifications')
    .insert({
      tool_id: params.tool_id,
      tool_name: params.tool_name,
      certification_type: params.certification_type,
      certification_number: params.certification_number,
      issuing_authority: params.issuing_authority,
      issue_date: params.issue_date,
      expiry_date: params.expiry_date,
      status: params.status || 'Valid',
      inspector_name: params.inspector_name || null,
      notes: params.notes || null,
      location: params.location || null,
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to add certification:', error)
    return null
  }

  await recordToolHistory({
    tool_id: params.tool_id,
    tool_name: params.tool_name,
    action: 'Certified',
    description: `${params.tool_name} — ${params.certification_type} ${params.certification_number}`,
    new_value: `Valid until ${params.expiry_date}`,
    performed_by: performedBy || 'Admin',
    performed_by_role: 'admin',
  })

  return data
}

export const updateCertification = updateCalibrationRecord
export const deleteCertification = deleteCalibrationRecord

// ── MAINTENANCE SCHEDULES (Calibration) ──

export async function scheduleCalibration(params: {
  tool_id: string
  tool_name: string
  scheduled_date: string
  interval_days?: number
  priority?: string
  assigned_to?: string
  estimated_cost?: number
  notes?: string
}): Promise<MaintenanceSchedule | null> {
  const intervalDays = params.interval_days || 90
  const scheduledDate = new Date(params.scheduled_date)
  const nextDate = new Date(scheduledDate)
  nextDate.setDate(nextDate.getDate() + intervalDays)

  const { data, error } = await supabase()
    .from('maintenance_schedules')
    .insert({
      tool_id: params.tool_id,
      tool_name: params.tool_name,
      maintenance_type: 'Calibration',
      description: `Scheduled calibration for ${params.tool_name}`,
      scheduled_date: params.scheduled_date,
      status: 'Scheduled',
      priority: params.priority || 'High',
      assigned_to: params.assigned_to || null,
      estimated_cost: params.estimated_cost || null,
      notes: params.notes || null,
      interval_days: intervalDays,
      next_maintenance_date: nextDate.toISOString().split('T')[0],
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to schedule calibration:', error)
    return null
  }
  return data
}

export async function updateMaintenanceSchedule(
  id: string,
  updates: Partial<MaintenanceSchedule>
): Promise<MaintenanceSchedule | null> {
  const { data, error } = await supabase()
    .from('maintenance_schedules')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single()

  if (error) {
    console.error('Failed to update schedule:', error)
    return null
  }
  return data
}

export async function completeCalibration(
  scheduleId: string,
  certData: {
    tool_id: string
    tool_name: string
    certification_number: string
    issuing_authority: string
    issue_date: string
    expiry_date: string
    inspector_name?: string
    notes?: string
  },
  performedBy?: string
): Promise<Certification | null> {
  // Mark schedule as completed
  await supabase()
    .from('maintenance_schedules')
    .update({
      status: 'Completed',
      completed_date: new Date().toISOString().split('T')[0],
      updated_at: new Date().toISOString(),
    })
    .eq('id', scheduleId)

  // Create certification record
  return addCalibrationRecord(certData, performedBy)
}
