// Types matching the existing Supabase tables (shared with Flutter app)

export type UserRole = 'admin' | 'technician' | 'pending'

export type ToolStatus = 'Available' | 'In Use' | 'Maintenance' | 'Retired'
export type ToolType = 'inventory' | 'shared' | 'assigned'
export type ToolCondition = 'Excellent' | 'Good' | 'Fair' | 'Poor'

export type IssueType = 'Faulty' | 'Lost' | 'Damaged' | 'Missing Parts' | 'Other'
export type IssuePriority = 'Low' | 'Medium' | 'High' | 'Critical'
export type IssueStatus = 'Open' | 'In Progress' | 'Resolved' | 'Closed'

export type ApprovalRequestType =
  | 'Tool Assignment'
  | 'Tool Purchase'
  | 'Tool Disposal'
  | 'Maintenance'
  | 'Transfer'
  | 'Repair'
  | 'Calibration'
  | 'Certification'
export type ApprovalStatus = 'Pending' | 'Approved' | 'Rejected' | 'Cancelled'

export type MaintenanceStatus = 'Scheduled' | 'In Progress' | 'Completed' | 'Overdue' | 'Cancelled'
export type CertificationStatus = 'Valid' | 'Expired' | 'Expiring Soon' | 'Revoked'
export type AssignmentStatus = 'Active' | 'On Leave' | 'Transferred' | 'Returned'

export type NotificationType =
  | 'access_request'
  | 'tool_request'
  | 'tool_added'
  | 'maintenance_request'
  | 'issue_report'
  | 'user_approved'
  | 'general'

// ── Table Types ──

export interface User {
  id: string
  email: string
  full_name: string
  employee_id?: string
  phone?: string
  department?: string
  role: UserRole
  position_id?: string
  profile_picture_url?: string
  created_at?: string
  updated_at?: string
}

export interface Tool {
  id: string
  name: string
  category: string
  brand?: string
  model?: string
  serial_number?: string
  purchase_date?: string
  purchase_price?: number
  current_value?: number
  condition: string
  location?: string
  assigned_to?: string
  status: ToolStatus
  tool_type: ToolType
  image_path?: string
  notes?: string
  created_at?: string
  updated_at?: string
  /** Admin user id who added/owns this tool (for "My Tools") */
  owned_by?: string
  // Joined field (not in table)
  assigned_user_name?: string
}

export interface Technician {
  id: string
  user_id?: string
  name: string
  employee_id?: string
  phone?: string
  email?: string
  department?: string
  hire_date?: string
  status: string
  profile_picture_url?: string
  created_at?: string
}

export interface ToolIssue {
  id: string
  tool_id: string
  tool_name: string
  reported_by: string
  reported_by_user_id?: string
  issue_type: IssueType
  description: string
  priority: IssuePriority
  status: IssueStatus
  assigned_to?: string
  assigned_to_user_id?: string
  resolution?: string
  reported_at: string
  resolved_at?: string
  attachments?: string[]
  location?: string
  estimated_cost?: number
}

export interface ApprovalWorkflow {
  id: string
  request_type: ApprovalRequestType
  title: string
  description: string
  requester_id: string
  requester_name: string
  requester_role: string
  status: ApprovalStatus
  priority: IssuePriority
  request_date: string
  due_date?: string
  assigned_to?: string
  assigned_to_role?: string
  comments?: string
  rejection_reason?: string
  approved_date?: string
  rejected_date?: string
  approved_by?: string
  rejected_by?: string
  request_data?: Record<string, unknown>
  location?: string
  created_at?: string
  updated_at?: string
}

export interface MaintenanceSchedule {
  id: string
  tool_id: string
  tool_name: string
  maintenance_type: string
  description: string
  scheduled_date: string
  completed_date?: string
  status: MaintenanceStatus
  priority: IssuePriority
  assigned_to?: string
  notes?: string
  estimated_cost?: number
  actual_cost?: number
  parts_used?: string
  next_maintenance_date?: string
  interval_days?: number
  created_at?: string
  updated_at?: string
}

export interface Certification {
  id: string
  tool_id: string
  tool_name: string
  certification_type: string
  certification_number: string
  issuing_authority: string
  issue_date: string
  expiry_date: string
  status: CertificationStatus
  notes?: string
  document_path?: string
  inspector_name?: string
  inspector_id?: string
  location?: string
  created_at?: string
  updated_at?: string
}

export interface ToolHistory {
  id: string
  tool_id: string
  tool_name: string
  action: string
  description: string
  old_value?: string
  new_value?: string
  performed_by?: string
  performed_by_role?: string
  timestamp: string
  location?: string
  notes?: string
  metadata?: Record<string, unknown>
}

export interface AdminNotification {
  id: string
  title: string
  message: string
  technician_name?: string
  technician_email?: string
  type: NotificationType
  timestamp: string
  is_read: boolean
  data?: Record<string, unknown>
}

export interface PendingUserApproval {
  id: string
  user_id: string
  email: string
  full_name: string
  employee_id?: string
  phone?: string
  department?: string
  hire_date?: string
  status: string
  rejection_reason?: string
  rejection_count?: number
  submitted_at?: string
  reviewed_at?: string
  reviewed_by?: string
  profile_picture_url?: string
}

export interface Location {
  id: number
  name: string
  address: string
  city?: string
  state?: string
  country?: string
  postal_code?: string
  phone?: string
  email?: string
  manager_name?: string
  is_active: boolean
  notes?: string
  created_at?: string
  updated_at?: string
}

export interface PermanentAssignment {
  id: string
  tool_id: string
  technician_id: string
  location_id?: number
  assigned_date: string
  assigned_by?: string
  notes?: string
  status: AssignmentStatus
  created_at?: string
  updated_at?: string
}

export interface PositionPermission {
  id: string
  position_id: string
  permission_name: string
  is_granted: boolean
}

export interface AdminPosition {
  id: string
  name: string
  description?: string
  is_active: boolean
  position_permissions: PositionPermission[]
  created_at?: string
  updated_at?: string
}
