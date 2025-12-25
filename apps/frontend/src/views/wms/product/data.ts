import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { ProductApi } from '#/api/wms/product';

import { z } from '#/adapter/form';
import { getCategoryList } from '#/api/wms/category';
import { $t } from '#/locales';

/**
 * 获取编辑表单的字段配置
 * 字段与数据库 base_product 表保持一致
 */
export function useSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'code',
      label: $t('wms.product.code'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.product.code')]))
        .max(50, $t('ui.formRules.maxLength', [$t('wms.product.code'), 50])),
    },
    {
      component: 'Input',
      fieldName: 'name',
      label: $t('wms.product.name'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.product.name')]))
        .max(100, $t('ui.formRules.maxLength', [$t('wms.product.name'), 100])),
    },
    {
      component: 'ApiSelect',
      componentProps: {
        api: async () => {
          const res = await getCategoryList({ pageSize: 200 });
          return res.items.map((item) => ({
            label: item.name,
            value: item.id,
          }));
        },
        placeholder: $t('common.pleaseSelect'),
        allowClear: true,
      },
      fieldName: 'categoryId',
      label: $t('wms.product.category'),
      rules: z
        .number()
        .min(1, $t('ui.formRules.required', [$t('wms.product.category')])),
    },
    {
      component: 'Input',
      fieldName: 'specification',
      label: $t('wms.product.specification'),
    },
    {
      component: 'Input',
      fieldName: 'unit',
      label: $t('wms.product.unit'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.product.unit')])),
    },
    {
      component: 'InputNumber',
      componentProps: {
        min: 0,
        precision: 4,
        class: 'w-full',
      },
      defaultValue: 0,
      fieldName: 'alertThreshold',
      label: $t('wms.product.alertThreshold'),
    },
    {
      component: 'RadioGroup',
      componentProps: {
        buttonStyle: 'solid',
        options: [
          { label: $t('common.enabled'), value: 1 },
          { label: $t('common.disabled'), value: 0 },
        ],
        optionType: 'button',
      },
      defaultValue: 1,
      fieldName: 'status',
      label: $t('wms.product.status'),
    },
  ];
}

/**
 * 获取搜索表单的字段配置
 */
export function useSearchSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'keyword',
      label: $t('wms.product.keyword'),
      componentProps: {
        placeholder: $t('wms.product.keywordPlaceholder'),
      },
    },
    {
      component: 'ApiSelect',
      componentProps: {
        api: async () => {
          const res = await getCategoryList({ pageSize: 200 });
          return res.items.map((item) => ({
            label: item.name,
            value: item.id,
          }));
        },
        placeholder: $t('common.pleaseSelect'),
        allowClear: true,
      },
      fieldName: 'category',
      label: $t('wms.product.category'),
    },
    {
      component: 'Select',
      componentProps: {
        allowClear: true,
        options: [
          { label: $t('common.enabled'), value: 1 },
          { label: $t('common.disabled'), value: 0 },
        ],
        placeholder: $t('common.pleaseSelect'),
      },
      fieldName: 'status',
      label: $t('wms.product.status'),
    },
  ];
}

/**
 * 获取表格列配置
 * 字段与数据库 base_product 表保持一致
 * @param onActionClick 操作按钮点击回调
 */
export function useColumns(
  onActionClick?: OnActionClickFn<ProductApi.Product>,
): VxeTableGridOptions<ProductApi.Product>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'code',
      title: $t('wms.product.code'),
      width: 120,
    },
    {
      field: 'name',
      title: $t('wms.product.name'),
      minWidth: 150,
    },
    {
      field: 'category',
      title: $t('wms.product.category'),
      width: 120,
    },
    {
      field: 'specification',
      title: $t('wms.product.specification'),
      width: 120,
    },
    {
      field: 'unit',
      title: $t('wms.product.unit'),
      width: 80,
    },
    {
      field: 'stockQty',
      title: $t('wms.product.stockQty'),
      width: 100,
    },
    {
      field: 'alertThreshold',
      title: $t('wms.product.alertThreshold'),
      width: 100,
    },
    {
      cellRender: { name: 'CellTag' },
      field: 'status',
      title: $t('wms.product.status'),
      width: 100,
    },
    {
      field: 'createTime',
      title: $t('wms.product.createTime'),
      width: 180,
    },
    {
      align: 'right',
      cellRender: {
        attrs: {
          nameField: 'name',
          nameTitle: $t('wms.product.title'),
          onClick: onActionClick,
        },
        name: 'CellOperation',
        options: ['edit', 'delete'],
      },
      field: 'operation',
      fixed: 'right',
      headerAlign: 'center',
      showOverflow: false,
      title: $t('common.operation'),
      width: 150,
    },
  ];
}
