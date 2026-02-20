import { format } from 'date-fns'
import type { Tool, ToolIssue, ToolHistory, Technician, ApprovalWorkflow } from '../types/database'

// ── Types ──

export type ReportType = 'inventory' | 'assignments' | 'issues' | 'financial' | 'comprehensive' | 'history'

export interface ReportData {
  tools: Tool[]
  issues: ToolIssue[]
  history: ToolHistory[]
  technicians: Technician[]
  approvals: ApprovalWorkflow[]
}

interface ReportOptions {
  type: ReportType
  dateFrom?: string
  dateTo?: string
  data: ReportData
}

// ── Helpers ──

const fmt = (d?: string) => (d ? format(new Date(d), 'dd MMM yyyy') : '')
const fmtDT = (d?: string) => (d ? format(new Date(d), 'yyyy-MM-dd HH:mm:ss') : '')
const fmtAED = (v?: number) => (v != null ? `AED ${v.toLocaleString('en-AE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : '')
const nowStr = () => format(new Date(), 'dd MMM yyyy HH:mm')

function filterByDate<T>(items: T[], field: keyof T, from?: string, to?: string): T[] {
  if (!from && !to) return items
  return items.filter((item) => {
    const val = item[field as keyof T] as string | undefined
    if (!val) return true
    const d = new Date(val)
    if (from && d < new Date(from)) return false
    if (to && d > new Date(to + 'T23:59:59')) return false
    return true
  })
}

function dateRangeText(from?: string, to?: string): string {
  if (from && to) return `${fmt(from)} - ${fmt(to)}`
  if (from) return `From ${fmt(from)}`
  if (to) return `Until ${fmt(to)}`
  return 'All Time'
}

function getTechName(userId: string | undefined, technicians: Technician[]): string {
  if (!userId) return ''
  const tech = technicians.find((t) => t.user_id === userId || t.id === userId)
  return tech?.name || userId
}

// ── Color palette (matching mobile: blueGrey scheme) ──

const COLORS = {
  headerBg: [55, 71, 79] as [number, number, number],       // blueGrey900
  headerBgLight: [84, 110, 122] as [number, number, number], // blueGrey700
  text: [69, 90, 100] as [number, number, number],           // blueGrey800
  textLight: [96, 125, 139] as [number, number, number],     // blueGrey600
  textMuted: [120, 144, 156] as [number, number, number],    // blueGrey500
  border: [207, 216, 220] as [number, number, number],       // blueGrey200
  sectionTitle: [55, 71, 79] as [number, number, number],    // blueGrey900
  companyName: [84, 110, 122] as [number, number, number],   // blueGrey700
}

// ── PDF Generators ──

async function loadJsPDF() {
  const { jsPDF } = await import('jspdf')
  const autoTableModule = await import('jspdf-autotable')
  return { jsPDF, autoTable: autoTableModule.default }
}

function addReportHeader(doc: any, title: string, dateFrom?: string, dateTo?: string) {
  // Company name
  doc.setFontSize(13)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(...COLORS.companyName)
  doc.text('RGS HVAC SERVICES', 14, 18)

  // Report title
  doc.setFontSize(20)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(...COLORS.sectionTitle)
  doc.text(title, 14, 28)

  // Date range + generated
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(...COLORS.textLight)
  doc.text(`Reporting period: ${dateRangeText(dateFrom, dateTo)}`, 14, 35)

  doc.setFontSize(9)
  doc.setTextColor(...COLORS.textMuted)
  doc.text(`Generated: ${nowStr()}`, 14 + doc.getTextWidth(`Reporting period: ${dateRangeText(dateFrom, dateTo)}`) + 12, 35)

  // Divider
  doc.setDrawColor(...COLORS.border)
  doc.setLineWidth(0.4)
  doc.line(14, 39, doc.internal.pageSize.getWidth() - 14, 39)

  doc.setTextColor(0)
  return 46
}

function addSectionTitle(doc: any, y: number, title: string): number {
  doc.setFontSize(18)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(...COLORS.sectionTitle)
  doc.text(title, 14, y)
  doc.setTextColor(0)
  return y + 6
}

function addSubtitle(doc: any, y: number, text: string): number {
  doc.setFontSize(12)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(...COLORS.textLight)
  doc.text(text, 14, y)
  doc.setTextColor(0)
  return y + 8
}

function addSubSectionTitle(doc: any, y: number, title: string): number {
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(...COLORS.text)
  doc.text(title, 14, y)
  doc.setTextColor(0)
  return y + 6
}

function dataTable(doc: any, autoTable: any, y: number, heads: string[], body: string[][], opts?: { headerColor?: [number, number, number] }) {
  autoTable(doc, {
    startY: y,
    head: [heads],
    body,
    theme: 'grid',
    headStyles: {
      fillColor: opts?.headerColor || COLORS.headerBg,
      textColor: [255, 255, 255],
      fontStyle: 'bold',
      fontSize: 9,
      cellPadding: 2,
    },
    bodyStyles: {
      fontSize: 8,
      textColor: COLORS.text,
      cellPadding: 2,
    },
    styles: {
      lineColor: COLORS.border,
      lineWidth: 0.4,
      overflow: 'linebreak',
    },
    margin: { left: 14, right: 14 },
  })
  return (doc as any).lastAutoTable.finalY + 10
}

function smallTable(doc: any, autoTable: any, y: number, heads: string[], body: string[][], opts?: { headerColor?: [number, number, number]; tableWidth?: number }) {
  autoTable(doc, {
    startY: y,
    head: [heads],
    body,
    theme: 'grid',
    headStyles: {
      fillColor: opts?.headerColor || COLORS.headerBgLight,
      textColor: [255, 255, 255],
      fontStyle: 'bold',
      fontSize: 9,
      cellPadding: 2,
    },
    bodyStyles: {
      fontSize: 8,
      textColor: COLORS.text,
      cellPadding: 2,
    },
    styles: {
      lineColor: COLORS.border,
      lineWidth: 0.4,
    },
    margin: { left: 14, right: 14 },
    tableWidth: opts?.tableWidth,
  })
  return (doc as any).lastAutoTable.finalY + 10
}

// Check if we need a new page (returns new Y or adds page)
function ensureSpace(doc: any, y: number, needed: number): number {
  const pageH = doc.internal.pageSize.getHeight()
  if (y + needed > pageH - 30) {
    doc.addPage()
    return 20
  }
  return y
}

// ── Individual PDF reports ──

async function generateInventoryPDF(opts: ReportOptions) {
  const { jsPDF, autoTable } = await loadJsPDF()
  const doc = new jsPDF('l') // landscape for wide table
  const tools = filterByDate(opts.data.tools, 'created_at', opts.dateFrom, opts.dateTo)
  let y = addReportHeader(doc, 'Tools Inventory Report', opts.dateFrom, opts.dateTo)

  y = addSectionTitle(doc, y, 'Tools Inventory')
  y = addSubtitle(doc, y, `Total Tools: ${tools.length}`)

  y = dataTable(doc, autoTable, y,
    ['Tool Name', 'Category', 'Brand', 'Model', 'Serial Number', 'Status', 'Condition', 'Location', 'Assigned To', 'Purchase Date', 'Purchase Price'],
    tools.map((t) => [
      t.name, t.category, t.brand || '', t.model || '', t.serial_number || '',
      t.status, t.condition, t.location || '',
      getTechName(t.assigned_to, opts.data.technicians),
      fmt(t.purchase_date), fmtAED(t.purchase_price),
    ])
  )

  return doc
}

async function generateAssignmentsPDF(opts: ReportOptions) {
  const { jsPDF, autoTable } = await loadJsPDF()
  const doc = new jsPDF('l')
  const assigned = opts.data.tools.filter((t) => t.assigned_to)
  let y = addReportHeader(doc, 'Tool Assignments Report', opts.dateFrom, opts.dateTo)

  y = addSectionTitle(doc, y, 'Tool Assignments')
  y = addSubtitle(doc, y, `Total Assignments: ${assigned.length}`)

  y = dataTable(doc, autoTable, y,
    ['Tool Name', 'Category', 'Assigned To', 'Status', 'Condition', 'Location', 'Assigned Date'],
    assigned.map((t) => [
      t.name, t.category,
      getTechName(t.assigned_to, opts.data.technicians),
      t.status, t.condition, t.location || '',
      fmtDT(t.updated_at),
    ])
  )

  return doc
}

async function generateIssuesPDF(opts: ReportOptions) {
  const { jsPDF, autoTable } = await loadJsPDF()
  const doc = new jsPDF('l')
  const issues = filterByDate(opts.data.issues, 'reported_at', opts.dateFrom, opts.dateTo)
  let y = addReportHeader(doc, 'Tool Issues Report', opts.dateFrom, opts.dateTo)

  y = addSectionTitle(doc, y, 'Tool Issues')
  y = addSubtitle(doc, y, `Total Issues: ${issues.length}`)

  y = dataTable(doc, autoTable, y,
    ['Tool', 'Type', 'Priority', 'Status', 'Reported', 'Reporter', 'Cost', 'Summary'],
    issues.map((i) => [
      i.tool_name, i.issue_type, i.priority, i.status,
      fmt(i.reported_at), i.reported_by, fmtAED(i.estimated_cost),
      i.description.length > 50 ? i.description.slice(0, 47) + '...' : i.description,
    ]),
    { headerColor: COLORS.headerBg }
  )

  return doc
}

async function generateFinancialPDF(opts: ReportOptions) {
  const { jsPDF, autoTable } = await loadJsPDF()
  const doc = new jsPDF()
  const { tools, issues } = opts.data
  let y = addReportHeader(doc, 'Financial Summary', opts.dateFrom, opts.dateTo)

  y = addSectionTitle(doc, y, 'Financial Summary')

  const totalPurchase = tools.reduce((s, t) => s + (t.purchase_price || 0), 0)
  const totalExpenditures = issues.reduce((s, i) => s + (i.estimated_cost || 0), 0)

  y = smallTable(doc, autoTable, y,
    ['Metric', 'Value'],
    [
      ['Total Tools', String(tools.length)],
      ['Total Purchase Price', fmtAED(totalPurchase)],
      ['Total Expenditures', fmtAED(totalExpenditures)],
      ['Total Investment', fmtAED(totalPurchase + totalExpenditures)],
    ],
    { headerColor: COLORS.headerBg }
  )

  // Status Distribution
  const statusCounts: Record<string, number> = {}
  tools.forEach((t) => { statusCounts[t.status] = (statusCounts[t.status] || 0) + 1 })

  y = addSubSectionTitle(doc, y, 'Status Distribution')
  y = smallTable(doc, autoTable, y,
    ['Status', 'Count'],
    Object.entries(statusCounts).map(([s, c]) => [s, String(c)]),
    { headerColor: COLORS.headerBgLight }
  )

  return doc
}

async function generateHistoryPDF(opts: ReportOptions) {
  const { jsPDF, autoTable } = await loadJsPDF()
  const doc = new jsPDF('l')
  const history = filterByDate(opts.data.history, 'timestamp', opts.dateFrom, opts.dateTo)
  let y = addReportHeader(doc, 'Audit Trail Report', opts.dateFrom, opts.dateTo)

  y = addSectionTitle(doc, y, 'Tool History')
  y = addSubtitle(doc, y, `Total Records: ${history.length}`)

  y = dataTable(doc, autoTable, y,
    ['Date', 'Tool', 'Action', 'Description', 'Old Value', 'New Value', 'Performed By'],
    history.map((h) => [
      fmt(h.timestamp), h.tool_name, h.action,
      h.description.length > 60 ? h.description.slice(0, 57) + '...' : h.description,
      h.old_value || '', h.new_value || '', h.performed_by || '',
    ])
  )

  return doc
}

async function generateComprehensivePDF(opts: ReportOptions) {
  const { jsPDF, autoTable } = await loadJsPDF()
  const doc = new jsPDF('l') // landscape for wide tables
  const { tools, issues, technicians, history, approvals } = opts.data
  let y = addReportHeader(doc, 'Comprehensive Tool Report', opts.dateFrom, opts.dateTo)

  // ── 1. Tools Inventory ──
  y = addSectionTitle(doc, y, 'Tools Inventory')
  y = addSubtitle(doc, y, `Total Tools: ${tools.length}`)

  y = dataTable(doc, autoTable, y,
    ['Tool Name', 'Category', 'Brand', 'Model', 'Serial Number', 'Status', 'Condition', 'Location', 'Assigned To', 'Purchase Date', 'Purchase Price'],
    tools.map((t) => [
      t.name, t.category, t.brand || '', t.model || '', t.serial_number || '',
      t.status, t.condition, t.location || '',
      getTechName(t.assigned_to, technicians),
      fmt(t.purchase_date), fmtAED(t.purchase_price),
    ])
  )

  // ── 2. Tool Assignments ──
  const assigned = tools.filter((t) => t.assigned_to)
  y = ensureSpace(doc, y, 60)
  y = addSectionTitle(doc, y, 'Tool Assignments')
  y = addSubtitle(doc, y, `Total Assignments: ${assigned.length}`)

  if (assigned.length > 0) {
    y = dataTable(doc, autoTable, y,
      ['Tool Name', 'Category', 'Assigned To', 'Status', 'Condition', 'Location', 'Assigned Date'],
      assigned.map((t) => [
        t.name, t.category, getTechName(t.assigned_to, technicians),
        t.status, t.condition, t.location || '', fmtDT(t.updated_at),
      ])
    )
  }

  // ── 3. Technician Summary ──
  y = ensureSpace(doc, y, 60)
  y = addSectionTitle(doc, y, 'Technician Summary')
  y = addSubtitle(doc, y, `Total Technicians: ${technicians.length}`)

  const techToolCounts: Record<string, { count: number; names: string[] }> = {}
  technicians.forEach((t) => { techToolCounts[t.name] = { count: 0, names: [] } })
  tools.forEach((t) => {
    if (t.assigned_to) {
      const name = getTechName(t.assigned_to, technicians)
      if (!techToolCounts[name]) techToolCounts[name] = { count: 0, names: [] }
      techToolCounts[name].count++
      techToolCounts[name].names.push(t.name)
    }
  })

  y = dataTable(doc, autoTable, y,
    ['Technician', 'Tools Assigned', 'Tool Names'],
    Object.entries(techToolCounts)
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([name, d]) => [name, String(d.count), d.names.join(', ')])
  )

  // ── 4. Financial Summary ──
  y = ensureSpace(doc, y, 80)
  y = addSectionTitle(doc, y, 'Financial Summary')

  const totalPurchase = tools.reduce((s, t) => s + (t.purchase_price || 0), 0)
  const totalExpenditures = issues.reduce((s, i) => s + (i.estimated_cost || 0), 0)

  y = smallTable(doc, autoTable, y,
    ['Metric', 'Value'],
    [
      ['Total Tools', String(tools.length)],
      ['Total Purchase Price', fmtAED(totalPurchase)],
      ['Total Expenditures', fmtAED(totalExpenditures)],
      ['Total Investment', fmtAED(totalPurchase + totalExpenditures)],
    ],
    { headerColor: COLORS.headerBg }
  )

  // Status Distribution
  const statusCounts: Record<string, number> = {}
  tools.forEach((t) => { statusCounts[t.status] = (statusCounts[t.status] || 0) + 1 })

  y = addSubSectionTitle(doc, y, 'Status Distribution')
  y = smallTable(doc, autoTable, y,
    ['Status', 'Count'],
    Object.entries(statusCounts).map(([s, c]) => [s, String(c)]),
    { headerColor: COLORS.headerBgLight }
  )

  // ── 5. Tool Issues ──
  y = ensureSpace(doc, y, 60)
  y = addSectionTitle(doc, y, 'Tool Issues')
  y = addSubtitle(doc, y, `Total Issues: ${issues.length}`)

  if (issues.length > 0) {
    y = dataTable(doc, autoTable, y,
      ['Tool', 'Type', 'Priority', 'Status', 'Reported', 'Reporter', 'Cost', 'Summary'],
      issues.map((i) => [
        i.tool_name, i.issue_type, i.priority, i.status,
        fmt(i.reported_at), i.reported_by, fmtAED(i.estimated_cost),
        i.description.length > 50 ? i.description.slice(0, 47) + '...' : i.description,
      ])
    )
  } else {
    doc.setFontSize(10)
    doc.setTextColor(...COLORS.textMuted)
    doc.text('No tool issues found for the selected period.', 14, y)
    doc.setTextColor(0)
    y += 14
  }

  // ── 6. Approval Workflows ──
  y = ensureSpace(doc, y, 60)
  if (approvals.length > 0) {
    y = addSectionTitle(doc, y, 'Approval Workflows Summary')

    const awStatus: Record<string, number> = {}
    approvals.forEach((a) => { awStatus[a.status] = (awStatus[a.status] || 0) + 1 })

    y = smallTable(doc, autoTable, y,
      ['Status', 'Count'],
      Object.entries(awStatus).map(([s, c]) => [s, String(c)]),
      { headerColor: COLORS.headerBgLight }
    )
  } else {
    doc.setFontSize(10)
    doc.setTextColor(...COLORS.textMuted)
    doc.text('No approval workflows found for the selected period.', 14, y)
    doc.setTextColor(0)
    y += 14
  }

  // ── 7. Tool History ──
  y = ensureSpace(doc, y, 60)
  y = addSectionTitle(doc, y, 'Tool History')
  y = addSubtitle(doc, y, `Total Tools: ${tools.length}`)

  y = dataTable(doc, autoTable, y,
    ['Tool Name', 'Category', 'Status', 'Condition', 'Created', 'Last Updated', 'Location'],
    tools.map((t) => [
      t.name, t.category, t.status, t.condition,
      fmtDT(t.created_at), fmtDT(t.updated_at), t.location || '',
    ])
  )

  return doc
}

// ── CSV Generators ──

function escapeCsv(val: string): string {
  if (val.includes(',') || val.includes('"') || val.includes('\n')) {
    return `"${val.replace(/"/g, '""')}"`
  }
  return val
}

function toCsv(headers: string[], rows: string[][]): string {
  const lines = [headers.map(escapeCsv).join(',')]
  rows.forEach((row) => lines.push(row.map((c) => escapeCsv(c || '')).join(',')))
  return lines.join('\n')
}

function generateInventoryCSV(opts: ReportOptions): string {
  const tools = filterByDate(opts.data.tools, 'created_at', opts.dateFrom, opts.dateTo)
  return toCsv(
    ['Name', 'Category', 'Brand', 'Model', 'Serial Number', 'Status', 'Condition', 'Location', 'Assigned To', 'Purchase Date', 'Purchase Price', 'Current Value'],
    tools.map((t) => [
      t.name, t.category, t.brand || '', t.model || '', t.serial_number || '',
      t.status, t.condition, t.location || '',
      getTechName(t.assigned_to, opts.data.technicians),
      fmt(t.purchase_date), t.purchase_price?.toString() || '', t.current_value?.toString() || '',
    ])
  )
}

function generateAssignmentsCSV(opts: ReportOptions): string {
  const assigned = opts.data.tools.filter((t) => t.assigned_to)
  return toCsv(
    ['Tool Name', 'Category', 'Assigned To', 'Status', 'Condition', 'Location', 'Assigned Date'],
    assigned.map((t) => [
      t.name, t.category, getTechName(t.assigned_to, opts.data.technicians),
      t.status, t.condition, t.location || '', fmtDT(t.updated_at),
    ])
  )
}

function generateIssuesCSV(opts: ReportOptions): string {
  const issues = filterByDate(opts.data.issues, 'reported_at', opts.dateFrom, opts.dateTo)
  return toCsv(
    ['Tool', 'Type', 'Priority', 'Status', 'Reported By', 'Reported At', 'Resolved At', 'Est. Cost', 'Description'],
    issues.map((i) => [
      i.tool_name, i.issue_type, i.priority, i.status, i.reported_by,
      fmt(i.reported_at), fmt(i.resolved_at), i.estimated_cost?.toString() || '',
      i.description,
    ])
  )
}

function generateFinancialCSV(opts: ReportOptions): string {
  return toCsv(
    ['Name', 'Category', 'Purchase Price', 'Current Value', 'Depreciation', 'Status', 'Condition'],
    opts.data.tools.map((t) => {
      const pp = t.purchase_price || 0
      const cv = t.current_value || pp
      return [t.name, t.category, pp.toString(), cv.toString(), (pp - cv).toString(), t.status, t.condition]
    })
  )
}

function generateHistoryCSV(opts: ReportOptions): string {
  const history = filterByDate(opts.data.history, 'timestamp', opts.dateFrom, opts.dateTo)
  return toCsv(
    ['Date', 'Tool', 'Action', 'Description', 'Old Value', 'New Value', 'Performed By'],
    history.map((h) => [
      fmt(h.timestamp), h.tool_name, h.action, h.description,
      h.old_value || '', h.new_value || '', h.performed_by || '',
    ])
  )
}

function generateComprehensiveCSV(opts: ReportOptions): string {
  return generateInventoryCSV(opts)
}

// ── Excel Generators (dynamic import) ──

async function loadExcelJS() {
  const mod = await import('exceljs')
  return mod.default || mod
}

function addExcelHeader(sheet: any, title: string, dateFrom?: string, dateTo?: string) {
  // Insert 5 rows at the top for the header
  sheet.insertRow(1, [])
  sheet.insertRow(1, [])
  sheet.insertRow(1, [])
  sheet.insertRow(1, [])
  sheet.insertRow(1, [])

  // Row 1: Company name
  const r1 = sheet.getRow(1)
  r1.getCell(1).value = 'RGS HVAC SERVICES'
  r1.getCell(1).font = { bold: true, size: 14, color: { argb: 'FF546E7A' } }
  r1.height = 22

  // Row 2: Report title
  const r2 = sheet.getRow(2)
  r2.getCell(1).value = title
  r2.getCell(1).font = { bold: true, size: 18, color: { argb: 'FF37474F' } }
  r2.height = 28

  // Row 3: Reporting period
  const r3 = sheet.getRow(3)
  r3.getCell(1).value = `Reporting Period: ${dateRangeText(dateFrom, dateTo)}`
  r3.getCell(1).font = { size: 10, color: { argb: 'FF78909C' } }

  // Row 4: Generated date
  const r4 = sheet.getRow(4)
  r4.getCell(1).value = `Generated: ${nowStr()}`
  r4.getCell(1).font = { size: 9, color: { argb: 'FF90A4AE' } }

  // Row 5: empty spacer (already inserted)
}

function styleHeader(sheet: any, color?: string, dataStartRow?: number) {
  const row = dataStartRow || 1
  const headerRow = sheet.getRow(row)
  headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 }
  headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: color || 'FF37474F' } }
  headerRow.alignment = { vertical: 'middle', horizontal: 'center' }
  headerRow.height = 24
  sheet.columns.forEach((col: any) => {
    col.width = Math.max(col.width || 12, 14)
  })
}

async function generateInventoryExcel(opts: ReportOptions) {
  const ExcelJS = await loadExcelJS()
  const wb = new ExcelJS.Workbook()
  const tools = filterByDate(opts.data.tools, 'created_at', opts.dateFrom, opts.dateTo)

  const sheet = wb.addWorksheet('Tools Inventory')
  sheet.columns = [
    { header: 'Name', key: 'name', width: 25 },
    { header: 'Category', key: 'category', width: 18 },
    { header: 'Brand', key: 'brand', width: 15 },
    { header: 'Model', key: 'model', width: 15 },
    { header: 'Serial Number', key: 'serial', width: 20 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Condition', key: 'condition', width: 12 },
    { header: 'Location', key: 'location', width: 18 },
    { header: 'Assigned To', key: 'assigned', width: 18 },
    { header: 'Purchase Date', key: 'date', width: 14 },
    { header: 'Purchase Price', key: 'price', width: 16 },
  ]
  tools.forEach((t) => sheet.addRow({
    name: t.name, category: t.category, brand: t.brand || '', model: t.model || '',
    serial: t.serial_number || '', status: t.status, condition: t.condition,
    location: t.location || '', assigned: getTechName(t.assigned_to, opts.data.technicians),
    date: fmt(t.purchase_date), price: t.purchase_price || 0,
  }))
  addExcelHeader(sheet, 'Tools Inventory Report', opts.dateFrom, opts.dateTo)
  styleHeader(sheet, undefined, 6)

  return wb
}

async function generateAssignmentsExcel(opts: ReportOptions) {
  const ExcelJS = await loadExcelJS()
  const wb = new ExcelJS.Workbook()
  const assigned = opts.data.tools.filter((t) => t.assigned_to)

  const sheet = wb.addWorksheet('Assignments')
  sheet.columns = [
    { header: 'Tool Name', key: 'name', width: 25 },
    { header: 'Category', key: 'category', width: 18 },
    { header: 'Assigned To', key: 'assigned', width: 22 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Condition', key: 'condition', width: 12 },
    { header: 'Location', key: 'location', width: 18 },
    { header: 'Assigned Date', key: 'date', width: 20 },
  ]
  assigned.forEach((t) => sheet.addRow({
    name: t.name, category: t.category,
    assigned: getTechName(t.assigned_to, opts.data.technicians),
    status: t.status, condition: t.condition, location: t.location || '',
    date: fmtDT(t.updated_at),
  }))
  addExcelHeader(sheet, 'Tool Assignments Report', opts.dateFrom, opts.dateTo)
  styleHeader(sheet, undefined, 6)

  return wb
}

async function generateIssuesExcel(opts: ReportOptions) {
  const ExcelJS = await loadExcelJS()
  const wb = new ExcelJS.Workbook()
  const issues = filterByDate(opts.data.issues, 'reported_at', opts.dateFrom, opts.dateTo)

  const sheet = wb.addWorksheet('Issues')
  sheet.columns = [
    { header: 'Tool', key: 'tool', width: 22 },
    { header: 'Type', key: 'type', width: 15 },
    { header: 'Priority', key: 'priority', width: 12 },
    { header: 'Status', key: 'status', width: 14 },
    { header: 'Reported By', key: 'reported_by', width: 18 },
    { header: 'Reported At', key: 'reported_at', width: 16 },
    { header: 'Resolved At', key: 'resolved_at', width: 16 },
    { header: 'Est. Cost (AED)', key: 'cost', width: 16 },
    { header: 'Description', key: 'desc', width: 35 },
  ]
  issues.forEach((i) => sheet.addRow({
    tool: i.tool_name, type: i.issue_type, priority: i.priority, status: i.status,
    reported_by: i.reported_by, reported_at: fmt(i.reported_at), resolved_at: fmt(i.resolved_at),
    cost: i.estimated_cost || 0, desc: i.description,
  }))
  addExcelHeader(sheet, 'Tool Issues Report', opts.dateFrom, opts.dateTo)
  styleHeader(sheet, undefined, 6)

  return wb
}

async function generateFinancialExcel(opts: ReportOptions) {
  const ExcelJS = await loadExcelJS()
  const wb = new ExcelJS.Workbook()
  const tools = opts.data.tools

  const summary = wb.addWorksheet('Summary')
  summary.columns = [{ header: 'Metric', key: 'metric', width: 25 }, { header: 'Value (AED)', key: 'value', width: 20 }]
  const totalPurchase = tools.reduce((s, t) => s + (t.purchase_price || 0), 0)
  const totalExp = opts.data.issues.reduce((s, i) => s + (i.estimated_cost || 0), 0)
  summary.addRows([
    { metric: 'Total Tools', value: tools.length },
    { metric: 'Total Purchase Price', value: totalPurchase },
    { metric: 'Total Expenditures', value: totalExp },
    { metric: 'Total Investment', value: totalPurchase + totalExp },
  ])
  addExcelHeader(summary, 'Financial Summary', opts.dateFrom, opts.dateTo)
  styleHeader(summary, undefined, 6)

  const sheet = wb.addWorksheet('Tools')
  sheet.columns = [
    { header: 'Name', key: 'name', width: 25 },
    { header: 'Category', key: 'category', width: 18 },
    { header: 'Purchase Price', key: 'purchase', width: 16 },
    { header: 'Current Value', key: 'current', width: 16 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Condition', key: 'condition', width: 12 },
  ]
  tools.forEach((t) => {
    sheet.addRow({ name: t.name, category: t.category, purchase: t.purchase_price || 0, current: t.current_value || t.purchase_price || 0, status: t.status, condition: t.condition })
  })
  styleHeader(sheet, undefined, 1)

  return wb
}

async function generateHistoryExcel(opts: ReportOptions) {
  const ExcelJS = await loadExcelJS()
  const wb = new ExcelJS.Workbook()
  const history = filterByDate(opts.data.history, 'timestamp', opts.dateFrom, opts.dateTo)

  const sheet = wb.addWorksheet('Audit Trail')
  sheet.columns = [
    { header: 'Date', key: 'date', width: 16 },
    { header: 'Tool', key: 'tool', width: 22 },
    { header: 'Action', key: 'action', width: 18 },
    { header: 'Description', key: 'desc', width: 35 },
    { header: 'Old Value', key: 'old', width: 18 },
    { header: 'New Value', key: 'new', width: 18 },
    { header: 'Performed By', key: 'by', width: 18 },
  ]
  history.forEach((h) => sheet.addRow({
    date: fmt(h.timestamp), tool: h.tool_name, action: h.action, desc: h.description,
    old: h.old_value || '', new: h.new_value || '', by: h.performed_by || '',
  }))
  addExcelHeader(sheet, 'Audit Trail Report', opts.dateFrom, opts.dateTo)
  styleHeader(sheet, undefined, 6)

  return wb
}

async function generateComprehensiveExcel(opts: ReportOptions) {
  const ExcelJS = await loadExcelJS()
  const wb = new ExcelJS.Workbook()
  const { tools, issues, technicians, approvals, history } = opts.data

  // ── Summary Sheet ──
  const summarySheet = wb.addWorksheet('Summary')
  summarySheet.columns = [{ header: '', key: 'label', width: 30 }, { header: '', key: 'value', width: 25 }]

  // Header info
  summarySheet.addRow({ label: 'RGS HVAC SERVICES' })
  summarySheet.getRow(1).getCell(1).font = { bold: true, size: 16, color: { argb: 'FF546E7A' } }
  summarySheet.addRow({ label: 'Comprehensive Tool Report' })
  summarySheet.getRow(2).getCell(1).font = { bold: true, size: 20, color: { argb: 'FF37474F' } }
  summarySheet.addRow({ label: `Reporting Period: ${dateRangeText(opts.dateFrom, opts.dateTo)}` })
  summarySheet.getRow(3).getCell(1).font = { size: 10, color: { argb: 'FF78909C' } }
  summarySheet.addRow({ label: `Generated: ${nowStr()}` })
  summarySheet.getRow(4).getCell(1).font = { size: 9, color: { argb: 'FF90A4AE' } }
  summarySheet.addRow({}) // spacer

  // Key metrics
  const totalPurchase = tools.reduce((s, t) => s + (t.purchase_price || 0), 0)
  const totalExp = issues.reduce((s, i) => s + (i.estimated_cost || 0), 0)
  const assigned = tools.filter((t) => t.assigned_to)

  const metricsHeaderRow = summarySheet.addRow({ label: 'Metric', value: 'Value' })
  metricsHeaderRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 }
  metricsHeaderRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF37474F' } }
  metricsHeaderRow.alignment = { vertical: 'middle', horizontal: 'center' }
  metricsHeaderRow.height = 24

  summarySheet.addRow({ label: 'Total Tools', value: tools.length })
  summarySheet.addRow({ label: 'Assigned Tools', value: assigned.length })
  summarySheet.addRow({ label: 'Total Technicians', value: technicians.length })
  summarySheet.addRow({ label: 'Total Issues', value: issues.length })
  summarySheet.addRow({ label: 'Total Approvals', value: approvals.length })
  summarySheet.addRow({ label: 'History Records', value: history.length })
  summarySheet.addRow({}) // spacer
  summarySheet.addRow({ label: 'Total Purchase Value', value: fmtAED(totalPurchase) })
  summarySheet.addRow({ label: 'Total Expenditures', value: fmtAED(totalExp) })
  summarySheet.addRow({ label: 'Total Investment', value: fmtAED(totalPurchase + totalExp) })

  // Status distribution
  summarySheet.addRow({}) // spacer
  const statusHeaderRow = summarySheet.addRow({ label: 'Status Distribution', value: 'Count' })
  statusHeaderRow.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 10 }
  statusHeaderRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF546E7A' } }
  statusHeaderRow.alignment = { vertical: 'middle', horizontal: 'center' }
  statusHeaderRow.height = 24
  const statusCounts: Record<string, number> = {}
  tools.forEach((t) => { statusCounts[t.status] = (statusCounts[t.status] || 0) + 1 })
  Object.entries(statusCounts).forEach(([s, c]) => summarySheet.addRow({ label: s, value: c }))

  // ── Tools Sheet ──
  const toolsSheet = wb.addWorksheet('Tools')
  toolsSheet.columns = [
    { header: 'Name', key: 'name', width: 25 },
    { header: 'Category', key: 'category', width: 18 },
    { header: 'Brand', key: 'brand', width: 15 },
    { header: 'Model', key: 'model', width: 15 },
    { header: 'Serial Number', key: 'serial', width: 20 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Condition', key: 'condition', width: 12 },
    { header: 'Location', key: 'location', width: 18 },
    { header: 'Assigned To', key: 'assigned', width: 18 },
    { header: 'Purchase Date', key: 'date', width: 14 },
    { header: 'Purchase Price', key: 'price', width: 16 },
  ]
  tools.forEach((t) => toolsSheet.addRow({
    name: t.name, category: t.category, brand: t.brand || '', model: t.model || '',
    serial: t.serial_number || '', status: t.status, condition: t.condition,
    location: t.location || '', assigned: getTechName(t.assigned_to, technicians),
    date: fmt(t.purchase_date), price: t.purchase_price || 0,
  }))
  addExcelHeader(toolsSheet, 'Tools Inventory', opts.dateFrom, opts.dateTo)
  styleHeader(toolsSheet, undefined, 6)

  // ── Issues Sheet ──
  const issuesSheet = wb.addWorksheet('Issues')
  issuesSheet.columns = [
    { header: 'Tool', key: 'tool', width: 22 },
    { header: 'Type', key: 'type', width: 15 },
    { header: 'Priority', key: 'priority', width: 12 },
    { header: 'Status', key: 'status', width: 14 },
    { header: 'Reported By', key: 'by', width: 18 },
    { header: 'Date', key: 'date', width: 16 },
    { header: 'Cost (AED)', key: 'cost', width: 14 },
    { header: 'Description', key: 'desc', width: 35 },
  ]
  issues.forEach((i) => issuesSheet.addRow({
    tool: i.tool_name, type: i.issue_type, priority: i.priority, status: i.status,
    by: i.reported_by, date: fmt(i.reported_at), cost: i.estimated_cost || 0,
    desc: i.description,
  }))
  addExcelHeader(issuesSheet, 'Tool Issues', opts.dateFrom, opts.dateTo)
  styleHeader(issuesSheet, undefined, 6)

  // ── Technicians Sheet ──
  const techSheet = wb.addWorksheet('Technicians')
  techSheet.columns = [
    { header: 'Name', key: 'name', width: 22 },
    { header: 'Employee ID', key: 'eid', width: 16 },
    { header: 'Department', key: 'dept', width: 18 },
    { header: 'Email', key: 'email', width: 25 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Tools Assigned', key: 'tools_count', width: 16 },
  ]
  technicians.forEach((t) => {
    const toolCount = tools.filter((tool) => tool.assigned_to === t.user_id || tool.assigned_to === t.id).length
    techSheet.addRow({
      name: t.name, eid: t.employee_id || '', dept: t.department || '', email: t.email || '',
      status: t.status, tools_count: toolCount,
    })
  })
  addExcelHeader(techSheet, 'Technician Summary', opts.dateFrom, opts.dateTo)
  styleHeader(techSheet, undefined, 6)

  // ── Approvals Sheet ──
  const appSheet = wb.addWorksheet('Approvals')
  appSheet.columns = [
    { header: 'Title', key: 'title', width: 25 },
    { header: 'Type', key: 'type', width: 18 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Priority', key: 'priority', width: 12 },
    { header: 'Requester', key: 'requester', width: 20 },
    { header: 'Date', key: 'date', width: 16 },
  ]
  approvals.forEach((a) => appSheet.addRow({
    title: a.title, type: a.request_type, status: a.status, priority: a.priority,
    requester: a.requester_name, date: fmt(a.request_date),
  }))
  addExcelHeader(appSheet, 'Approval Workflows', opts.dateFrom, opts.dateTo)
  styleHeader(appSheet, undefined, 6)

  // ── History Sheet ──
  const histSheet = wb.addWorksheet('Audit Trail')
  histSheet.columns = [
    { header: 'Date', key: 'date', width: 16 },
    { header: 'Tool', key: 'tool', width: 22 },
    { header: 'Action', key: 'action', width: 18 },
    { header: 'Description', key: 'desc', width: 35 },
    { header: 'Old Value', key: 'old', width: 18 },
    { header: 'New Value', key: 'new', width: 18 },
    { header: 'Performed By', key: 'by', width: 18 },
  ]
  history.forEach((h) => histSheet.addRow({
    date: fmt(h.timestamp), tool: h.tool_name, action: h.action, desc: h.description,
    old: h.old_value || '', new: h.new_value || '', by: h.performed_by || '',
  }))
  addExcelHeader(histSheet, 'Tool History / Audit Trail', opts.dateFrom, opts.dateTo)
  styleHeader(histSheet, undefined, 6)

  return wb
}

async function saveWorkbook(wb: any, filename: string) {
  const buffer = await wb.xlsx.writeBuffer()
  const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

// ── Public API ──

export async function generateExcel(opts: ReportOptions): Promise<void> {
  const generators: Record<ReportType, (o: ReportOptions) => Promise<any>> = {
    inventory: generateInventoryExcel,
    assignments: generateAssignmentsExcel,
    issues: generateIssuesExcel,
    financial: generateFinancialExcel,
    comprehensive: generateComprehensiveExcel,
    history: generateHistoryExcel,
  }

  const wb = await generators[opts.type](opts)
  const label = opts.type.charAt(0).toUpperCase() + opts.type.slice(1)
  await saveWorkbook(wb, `RGS_${label}_Report_${format(new Date(), 'yyyy-MM-dd')}.xlsx`)
}

export async function generatePDF(opts: ReportOptions): Promise<void> {
  const generators: Record<ReportType, (o: ReportOptions) => Promise<any>> = {
    inventory: generateInventoryPDF,
    assignments: generateAssignmentsPDF,
    issues: generateIssuesPDF,
    financial: generateFinancialPDF,
    comprehensive: generateComprehensivePDF,
    history: generateHistoryPDF,
  }

  const doc = await generators[opts.type](opts)
  const label = opts.type.charAt(0).toUpperCase() + opts.type.slice(1)
  doc.save(`RGS_${label}_Report_${format(new Date(), 'yyyy-MM-dd')}.pdf`)
}

export function generateCSV(opts: ReportOptions): void {
  const generators: Record<ReportType, (o: ReportOptions) => string> = {
    inventory: generateInventoryCSV,
    assignments: generateAssignmentsCSV,
    issues: generateIssuesCSV,
    financial: generateFinancialCSV,
    comprehensive: generateComprehensiveCSV,
    history: generateHistoryCSV,
  }

  const csv = generators[opts.type](opts)
  const label = opts.type.charAt(0).toUpperCase() + opts.type.slice(1)
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `RGS_${label}_Report_${format(new Date(), 'yyyy-MM-dd')}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
