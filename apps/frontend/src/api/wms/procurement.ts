import { requestClient } from '#/api/request';

export namespace ProcurementApi {
  /**
   * 采购单接口
   * 与数据库 biz_procurement 表字段对应
   */
  export interface Procurement {
    id: string;
    /** 采购单号 - 对应数据库 order_no */
    orderNo: string;
    /** 申请人ID - 对应数据库 applicant_id */
    applicantId?: number;
    /** 申请人名称 - 关联字段 */
    applicantName?: string;
    /** 供应商ID - 对应数据库 supplier_id */
    supplierId?: number;
    /** 供应商名称 - 关联字段 */
    supplierName?: string;
    /** 状态 - 对应数据库 status (PENDING-待审, APPROVED-已批, ORDERED-已下单, DONE-完成) */
    status?: 'APPROVED' | 'DONE' | 'ORDERED' | 'PENDING' | 'REJECT';
    /** 申请原因 - 对应数据库 reason */
    reason?: string;
    /** 预计到货日期 - 对应数据库 expected_date */
    expectedDate?: string;
    /** 总金额 - 计算字段 */
    totalAmount?: number;
    /** 采购日期 - 使用 createTime */
    orderDate?: string;
    /** 采购明细 */
    items?: ProcurementItem[];
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  /**
   * 采购明细接口
   * 与数据库 biz_procurement_item 表字段对应
   */
  export interface ProcurementItem {
    id: string;
    /** 采购单ID */
    procurementId: string;
    /** 物资ID */
    productId: string;
    /** 物资名称 - 关联字段 */
    productName?: string;
    /** 物资编码 - 关联字段 */
    productCode?: string;
    /** 计划数量 - 对应数据库 plan_qty */
    quantity: number;
    /** 单价 - 对应数据库 unit_price */
    price: number;
    /** 金额 - 计算字段 */
    amount: number;
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
