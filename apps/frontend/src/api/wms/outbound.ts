import { requestClient } from '#/api/request';

export namespace OutboundApi {
  export interface Outbound {
    id: string;
    orderNo: string;
    type: 'other' | 'return' | 'sale' | 'transfer';
    status: 'cancelled' | 'completed' | 'draft' | 'pending' | 'picking';
    warehouseId?: string;
    warehouseName?: string;
    customerId?: string;
    customerName?: string;
    totalQuantity?: number;
    operatorId?: string;
    operatorName?: string;
    outboundDate: string;
    remark?: string;
    items?: OutboundItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  export interface OutboundItem {
    id: string;
    outboundId: string;
    productId: string;
    productName?: string;
    productCode?: string;
    quantity: number;
    pickedQuantity?: number;
    locationId?: string;
    locationName?: string;
    batchNo?: string;
  }

  export interface OutboundListParams {
    page?: number;
    pageSize?: number;
    orderNo?: string;
    type?: string;
    status?: string;
    startDate?: string;
    endDate?: string;
  }

  export interface OutboundListResult {
    items: Outbound[];
    total: number;
  }
}

/**
 * 获取出库单列表
 */
async function getOutboundList(params?: OutboundApi.OutboundListParams) {
  return requestClient.get<OutboundApi.OutboundListResult>('/outbounds', {
    params,
  });
}

/**
 * 获取出库单详情
 */
async function getOutbound(id: string) {
  return requestClient.get<OutboundApi.Outbound>(`/outbounds/${id}`);
}

/**
 * 创建出库单
 */
async function createOutbound(data: Omit<OutboundApi.Outbound, 'id'>) {
  return requestClient.post('/outbounds', data);
}

/**
 * 更新出库单
 */
async function updateOutbound(
  id: string,
  data: Omit<OutboundApi.Outbound, 'id'>,
) {
  return requestClient.put(`/outbounds/${id}`, data);
}

/**
 * 删除出库单
 */
async function deleteOutbound(id: string) {
  return requestClient.delete(`/outbounds/${id}`);
}

export {
  createOutbound,
  deleteOutbound,
  getOutbound,
  getOutboundList,
  updateOutbound,
};
