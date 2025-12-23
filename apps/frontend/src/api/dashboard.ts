import { requestClient } from '#/api/request';

// 概览统计数据
export interface OverviewStats {
  productCount: number;
  totalStock: number;
  pendingInbound: number;
  pendingOutbound: number;
  lowStockCount: number;
  todayInbound: number;
  todayOutbound: number;
  procurementCount: number;
}

// 库存趋势项
export interface StockTrendItem {
  date: string;
  inbound: number;
  outbound: number;
}

// 分类库存
export interface CategoryStock {
  name: string;
  quantity: number;
}

// 低库存产品
export interface LowStockProduct {
  id: number;
  name: string;
  skuCode: string;
  stockQty: number;
  alertThreshold: number;
}

// 最近动态
export interface RecentActivity {
  id: number;
  type: string;
  orderNo: string;
  operator: string;
  createdAt: string;
}

// 获取概览统计
export async function getOverviewStats() {
  return requestClient.get<OverviewStats>('/dashboard/overview');
}

// 获取库存趋势
export async function getStockTrend() {
  return requestClient.get<StockTrendItem[]>('/dashboard/stock-trend');
}

// 获取分类库存分布
export async function getCategoryStock() {
  return requestClient.get<CategoryStock[]>('/dashboard/category-stock');
}

// 获取低库存产品列表
export async function getLowStockProducts() {
  return requestClient.get<LowStockProduct[]>('/dashboard/low-stock');
}

// 获取最近操作动态
export async function getRecentActivities() {
  return requestClient.get<RecentActivity[]>('/dashboard/activities');
}

