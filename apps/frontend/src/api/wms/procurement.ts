import { requestClient } from '#/api/request';

export namespace ProcurementApi {
  export interface Procurement {
    id: string;
    orderNo: string;
    supplierId?: string;
    supplierName?: string;
    status: 'approved' | 'cancelled' | 'completed' | 'draft' | 'pending';
    totalAmount?: number;
    orderDate: string;
    expectedDate?: string;
    remark?: string;
    items?: ProcurementItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  export interface ProcurementItem {
    id: string;
    procurementId: string;
    productId: string;
    productName?: string;
    productCode?: string;
    quantity: number;
    price: number;
    amount: number;
    receivedQuantity?: number;
  }

  export interface ProcurementListParams {
    page?: number;
    pageSize?: number;
    orderNo?: string;
    status?: string;
    startDate?: string;
    endDate?: string;
  }

  export interface ProcurementListResult {
    items: Procurement[];
    total: number;
  }
}

/**
 * 获取采购单列表
 */
async function getProcurementList(
  params?: ProcurementApi.ProcurementListParams,
) {
  return requestClient.get<ProcurementApi.ProcurementListResult>(
    '/procurements',
    { params },
  );
}

/**
 * 获取采购单详情
 */
async function getProcurement(id: string) {
  return requestClient.get<ProcurementApi.Procurement>(`/procurements/${id}`);
}

/**
 * 创建采购单
 */
async function createProcurement(
  data: Omit<ProcurementApi.Procurement, 'id'>,
) {
  return requestClient.post('/procurements', data);
}

/**
 * 更新采购单
 */
async function updateProcurement(
  id: string,
  data: Omit<ProcurementApi.Procurement, 'id'>,
) {
  return requestClient.put(`/procurements/${id}`, data);
}

/**
 * 删除采购单
 */
async function deleteProcurement(id: string) {
  return requestClient.delete(`/procurements/${id}`);
}

export {
  createProcurement,
  deleteProcurement,
  getProcurement,
  getProcurementList,
  updateProcurement,
};
