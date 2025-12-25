import { requestClient } from '#/api/request';

export namespace CategoryApi {
  export interface Category {
    id: number;
    name: string;
    parentId: number;
    children?: Category[];
  }

  export interface CategoryListParams {
    page?: number;
    pageSize?: number;
    keyword?: string;
  }

  export interface CategoryListResult {
    items: Category[];
    total: number;
  }
}

/**
 * 获取分类列表
 */
async function getCategoryList(params?: CategoryApi.CategoryListParams) {
  return requestClient.get<CategoryApi.CategoryListResult>('/categories', {
    params,
  });
}

/**
 * 获取分类树
 */
async function getCategoryTree() {
  return requestClient.get<CategoryApi.Category[]>('/categories/tree');
}

/**
 * 获取分类详情
 */
async function getCategory(id: number) {
  return requestClient.get<CategoryApi.Category>(`/categories/${id}`);
}

/**
 * 创建分类
 */
async function createCategory(data: Omit<CategoryApi.Category, 'id'>) {
  return requestClient.post('/categories', data);
}

/**
 * 更新分类
 */
async function updateCategory(
  id: number,
  data: Omit<CategoryApi.Category, 'id'>,
) {
  return requestClient.put(`/categories/${id}`, data);
}

/**
 * 删除分类
 */
async function deleteCategory(id: number) {
  return requestClient.delete(`/categories/${id}`);
}

export {
  createCategory,
  deleteCategory,
  getCategory,
  getCategoryList,
  getCategoryTree,
  updateCategory,
};

