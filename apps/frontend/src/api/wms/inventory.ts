import { requestClient } from '#/api/request';

export namespace InventoryApi {
  export interface Stock {
    id: string;
    productId: string;
    productCode?: string;
    productName?: string;
    warehouseId: string;
    warehouseName?: string;
    locationId?: string;
    locationName?: string;
    quantity: number;
    availableQuantity: number;
    lockedQuantity?: number;
    batchNo?: string;
    productionDate?: string;
    expirationDate?: string;
    costPrice?: number;
    updateTime?: string;
    [key: string]: any;
  }

  export interface StockListParams {
    page?: number;
    pageSize?: number;
    productId?: string;
    productName?: string;
    warehouseId?: string;
    lowStock?: boolean;
  }

  export interface StockListResult {
    items: Stock[];
    total: number;
  }

  export interface InventoryCheck {
    id: string;
    checkNo: string;
    warehouseId: string;
    warehouseName?: string;
    status: 'cancelled' | 'checking' | 'completed' | 'draft';
    checkDate: string;
    operatorId?: string;
    operatorName?: string;
    remark?: string;
    items?: InventoryCheckItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  export interface InventoryCheckItem {
    id: string;
    checkId: string;
    productId: string;
    productName?: string;
    productCode?: string;
    locationId?: string;
    locationName?: string;
    systemQuantity: number;
    actualQuantity: number;
    differenceQuantity: number;
    remark?: string;
  }

  export interface InventoryCheckListParams {
    page?: number;
    pageSize?: number;
    checkNo?: string;
    warehouseId?: string;
    status?: string;
    startDate?: string;
    endDate?: string;
  }

  export interface InventoryCheckListResult {
    items: InventoryCheck[];
    total: number;
  }
}

/**
 * 获取库存列表
 */
async function getStockList(params?: InventoryApi.StockListParams) {
  return requestClient.get<InventoryApi.StockListResult>('/inventory/stock', {
    params,
  });
}

/**
 * 获取库存详情
 */
async function getStock(id: string) {
  return requestClient.get<InventoryApi.Stock>(`/inventory/stock/${id}`);
}

/**
 * 获取盘点单列表
 */
async function getInventoryCheckList(
  params?: InventoryApi.InventoryCheckListParams,
) {
  return requestClient.get<InventoryApi.InventoryCheckListResult>(
    '/inventory/checks',
    { params },
  );
}

/**
 * 获取盘点单详情
 */
async function getInventoryCheck(id: string) {
  return requestClient.get<InventoryApi.InventoryCheck>(
    `/inventory/checks/${id}`,
  );
}

/**
 * 创建盘点单
 */
async function createInventoryCheck(
  data: Omit<InventoryApi.InventoryCheck, 'id'>,
) {
  return requestClient.post('/inventory/checks', data);
}

/**
 * 更新盘点单
 */
async function updateInventoryCheck(
  id: string,
  data: Omit<InventoryApi.InventoryCheck, 'id'>,
) {
  return requestClient.put(`/inventory/checks/${id}`, data);
}

/**
 * 删除盘点单
 */
async function deleteInventoryCheck(id: string) {
  return requestClient.delete(`/inventory/checks/${id}`);
}

export {
  createInventoryCheck,
  deleteInventoryCheck,
  getInventoryCheck,
  getInventoryCheckList,
  getStock,
  getStockList,
  updateInventoryCheck,
};
