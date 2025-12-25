import { requestClient } from '#/api/request';

export namespace SupplierApi {
  export interface Supplier {
    id: number;
    name: string;
    contact?: string;
    phone?: string;
    address?: string;
    status: 0 | 1;
    createTime?: string;
    updateTime?: string;
  }

  export interface SupplierListParams {
    page?: number;
    pageSize?: number;
    keyword?: string;
    status?: 0 | 1;
  }

  export interface SupplierListResult {
    items: Supplier[];
    total: number;
  }
}

/**
 * 获取供应商列表
 */
async function getSupplierList(params?: SupplierApi.SupplierListParams) {
  return requestClient.get<SupplierApi.SupplierListResult>('/suppliers', {
    params,
  });
}

/**
 * 获取供应商详情
 */
async function getSupplier(id: number) {
  return requestClient.get<SupplierApi.Supplier>(`/suppliers/${id}`);
}

/**
 * 创建供应商
 */
async function createSupplier(data: Omit<SupplierApi.Supplier, 'id'>) {
  return requestClient.post('/suppliers', data);
}

/**
 * 更新供应商
 */
async function updateSupplier(
  id: number,
  data: Omit<SupplierApi.Supplier, 'id'>,
) {
  return requestClient.put(`/suppliers/${id}`, data);
}

/**
 * 删除供应商
 */
async function deleteSupplier(id: number) {
  return requestClient.delete(`/suppliers/${id}`);
}

export {
  createSupplier,
  deleteSupplier,
  getSupplier,
  getSupplierList,
  updateSupplier,
};

