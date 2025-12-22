import { requestClient } from '#/api/request';

export namespace InboundApi {
  export interface Inbound {
    id: string;
    orderNo: string;
    type: 'other' | 'purchase' | 'return' | 'transfer';
    status: 'cancelled' | 'completed' | 'draft' | 'pending';
    warehouseId?: string;
    warehouseName?: string;
    sourceOrderNo?: string;
    totalQuantity?: number;
    operatorId?: string;
    operatorName?: string;
    inboundDate: string;
    remark?: string;
    items?: InboundItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  export interface InboundItem {
    id: string;
    inboundId: string;
    productId: string;
    productName?: string;
    productCode?: string;
    quantity: number;
    locationId?: string;
    locationName?: string;
    batchNo?: string;
    productionDate?: string;
    expirationDate?: string;
  }

  export interface InboundListParams {
    page?: number;
    pageSize?: number;
    orderNo?: string;
    type?: string;
    status?: string;
    startDate?: string;
    endDate?: string;
  }

  export interface InboundListResult {
    items: Inbound[];
    total: number;
  }
}

/**
 * 获取入库单列表
 */
async function getInboundList(params?: InboundApi.InboundListParams) {
  return requestClient.get<InboundApi.InboundListResult>('/inbounds', {
    params,
  });
}

/**
 * 获取入库单详情
 */
async function getInbound(id: string) {
  return requestClient.get<InboundApi.Inbound>(`/inbounds/${id}`);
}

/**
 * 创建入库单
 */
async function createInbound(data: Omit<InboundApi.Inbound, 'id'>) {
  return requestClient.post('/inbounds', data);
}

/**
 * 更新入库单
 */
async function updateInbound(id: string, data: Omit<InboundApi.Inbound, 'id'>) {
  return requestClient.put(`/inbounds/${id}`, data);
}

/**
 * 删除入库单
 */
async function deleteInbound(id: string) {
  return requestClient.delete(`/inbounds/${id}`);
}

export {
  createInbound,
  deleteInbound,
  getInbound,
  getInboundList,
  updateInbound,
};
