import { requestClient } from '#/api/request';

export namespace OutboundApi {
  /**
   * 出库单接口
   * 与数据库 biz_outbound 表字段对应
   */
  export interface Outbound {
    id: string;
    /** 出库单号 - 对应数据库 outbound_no */
    orderNo: string;
    /** 申请人ID - 对应数据库 applicant_id */
    applicantId?: number;
    /** 申请人名称 - 关联字段 */
    applicantName?: string;
    /** 部门ID - 对应数据库 dept_id */
    deptId?: number;
    /** 部门名称 - 关联字段 */
    deptName?: string;
    /** 状态 - 对应数据库 status (PENDING-待审, APPROVED-已批, DONE-已领用, REJECT-驳回) */
    status?: 'cancelled' | 'completed' | 'draft' | 'pending' | 'picking';
    /** 用途 - 对应数据库 purpose */
    purpose?: string;
    /** 审核人ID - 对应数据库 reviewer_id */
    reviewerId?: number;
    /** 审核人名称 - 关联字段 */
    reviewerName?: string;
    /** 审核时间 - 对应数据库 review_time */
    reviewTime?: string;
    /** 出库时间 - 对应数据库 outbound_date */
    outboundDate?: string;
    /** 出库类型 - 前端虚拟字段 */
    type?: 'other' | 'return' | 'sale' | 'transfer';
    /** 仓库名称 - 前端虚拟字段 */
    warehouseName?: string;
    /** 总数量 - 前端虚拟字段 */
    totalQuantity?: number;
    /** 操作人名称 - 前端虚拟字段 */
    operatorName?: string;
    /** 出库明细 */
    items?: OutboundItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  /**
   * 出库明细接口
   * 与数据库 biz_outbound_item 表字段对应
   */
  export interface OutboundItem {
    id: string;
    /** 出库单ID */
    outboundId: string;
    /** 物资ID */
    productId: string;
    /** 物资名称 - 关联字段 */
    productName?: string;
    /** 物资编码 - 关联字段 */
    productCode?: string;
    /** 申请数量 - 对应数据库 apply_qty */
    quantity: number;
    /** 实发数量 - 对应数据库 actual_qty */
    pickedQuantity?: number;
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
