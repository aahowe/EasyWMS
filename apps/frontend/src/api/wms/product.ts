import { requestClient } from '#/api/request';

export namespace ProductApi {
  /**
   * 物资档案接口
   * 与数据库 base_product 表字段对应
   */
  export interface Product {
    id: string;
    /** SKU编码 - 对应数据库 sku_code */
    code: string;
    /** 物资名称 */
    name: string;
    /** 分类ID - 对应数据库 category_id */
    categoryId?: number;
    /** 分类名称 - 关联字段 */
    category?: string;
    /** 规格型号 */
    specification?: string;
    /** 计量单位 */
    unit: string;
    /** 实时库存数量 - 对应数据库 stock_qty */
    stockQty?: number;
    /** 预警阈值 - 对应数据库 alert_threshold */
    alertThreshold?: number;
    /** 状态: 1-启用, 0-停用 */
    status: 0 | 1;
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
