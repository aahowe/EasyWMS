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

  /**
   * 盘点单接口
   * 与数据库 biz_inventory_check 表字段对应
   */
  export interface InventoryCheck {
    id: string;
    /** 盘点单号 - 对应数据库 check_no */
    checkNo: string;
    /** 盘点人ID - 对应数据库 checker_id */
    checkerId?: number;
    /** 状态 - 对应数据库 status (CHECKING-盘点中, FINISHED-已调账结束) */
    status?: 'cancelled' | 'checking' | 'completed' | 'draft';
    /** 盘点日期 - 对应数据库 check_date */
    checkDate?: string;
    /** 备注 */
    remark?: string;
    /** 仓库名称 - 前端虚拟字段 */
    warehouseName?: string;
    /** 操作员ID - 前端虚拟字段 */
    operatorId?: string;
    /** 操作员名称 - 前端虚拟字段 */
    operatorName?: string;
    /** 盘点明细 */
    items?: InventoryCheckItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  /**
   * 盘点明细接口
   * 与数据库 biz_inventory_check_item 表字段对应
   */
  export interface InventoryCheckItem {
    id: string;
    /** 盘点单ID */
    checkId: string;
    /** 物资ID */
    productId: string;
    /** 物资名称 - 关联字段 */
    productName?: string;
    /** 物资编码 - 关联字段 */
    productCode?: string;
    /** 账面数量 - 对应数据库 book_qty */
    systemQuantity: number;
    /** 实盘数量 - 对应数据库 actual_qty */
    actualQuantity: number;
    /** 盈亏数量 - 对应数据库 diff_qty */
    differenceQuantity: number;
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
