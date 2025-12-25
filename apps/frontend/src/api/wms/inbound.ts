import { requestClient } from '#/api/request';

export namespace InboundApi {
  /**
   * 入库单接口
   * 与数据库 biz_inbound 表字段对应
   */
  export interface Inbound {
    id: string;
    /** 入库单号 - 对应数据库 inbound_no */
    orderNo: string;
    /** 来源单ID - 对应数据库 source_id */
    sourceId?: number;
    /** 是否暂估 - 对应数据库 is_temporary (1-暂估, 0-正常) */
    isTemporary?: number;
    /** 状态 - 对应数据库 status (1-已完成, 0-草稿) */
    statusCode?: number;
    /** 入库类型 - 前端虚拟字段 */
    type?: 'other' | 'purchase' | 'return' | 'transfer';
    /** 状态文本 - 前端虚拟字段 */
    status?: 'cancelled' | 'completed' | 'draft' | 'pending';
    /** 仓库名称 - 前端虚拟字段 */
    warehouseName?: string;
    /** 来源单号 - 前端虚拟字段 */
    sourceOrderNo?: string;
    /** 总数量 - 前端虚拟字段 */
    totalQuantity?: number;
    /** 操作员ID - 对应数据库 warehouse_user_id */
    operatorId?: string;
    /** 操作员名称 - 前端虚拟字段 */
    operatorName?: string;
    /** 入库时间 - 对应数据库 inbound_date */
    inboundDate?: string;
    /** 备注 */
    remark?: string;
    /** 入库明细 */
    items?: InboundItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  /**
   * 入库明细接口
   * 与数据库 biz_inbound_item 表字段对应
   */
  export interface InboundItem {
    id: string;
    /** 入库单ID */
    inboundId: string;
    /** 物资ID */
    productId: string;
    /** 物资名称 - 关联字段 */
    productName?: string;
    /** 物资编码 - 关联字段 */
    productCode?: string;
    /** 实收数量 - 对应数据库 actual_qty */
    quantity: number;
    /** 库位 - 对应数据库 location */
    locationName?: string;
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
