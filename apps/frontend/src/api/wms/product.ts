import { requestClient } from '#/api/request';

export namespace ProductApi {
  export interface Product {
    id: string;
    code: string;
    name: string;
    category?: string;
    specification?: string;
    unit: string;
    price?: number;
    costPrice?: number;
    barcode?: string;
    status: 0 | 1;
    minStock?: number;
    maxStock?: number;
    remark?: string;
    createTime?: string;
    updateTime?: string;
    [key: string]: any;
  }

  export interface ProductListParams {
    page?: number;
    pageSize?: number;
    keyword?: string;
    category?: string;
    status?: 0 | 1;
  }

  export interface ProductListResult {
    items: Product[];
    total: number;
  }
}

/**
 * 获取产品列表
 */
async function getProductList(params?: ProductApi.ProductListParams) {
  return requestClient.get<ProductApi.ProductListResult>('/products', {
    params,
  });
}

/**
 * 获取产品详情
 */
async function getProduct(id: string) {
  return requestClient.get<ProductApi.Product>(`/products/${id}`);
}

/**
 * 创建产品
 */
async function createProduct(data: Omit<ProductApi.Product, 'id'>) {
  return requestClient.post('/products', data);
}

/**
 * 更新产品
 */
async function updateProduct(id: string, data: Omit<ProductApi.Product, 'id'>) {
  return requestClient.put(`/products/${id}`, data);
}

/**
 * 删除产品
 */
async function deleteProduct(id: string) {
  return requestClient.delete(`/products/${id}`);
}

export {
  createProduct,
  deleteProduct,
  getProduct,
  getProductList,
  updateProduct,
};
