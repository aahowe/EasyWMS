import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { ProductApi } from '#/api/wms/product';

import { z } from '#/adapter/form';
import { $t } from '#/locales';

/**
 * 获取编辑表单的字段配置
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
      component: 'Input',
      fieldName: 'category',
      label: $t('wms.product.category'),
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
        precision: 2,
        class: 'w-full',
      },
      fieldName: 'price',
      label: $t('wms.product.price'),
    },
    {
      component: 'InputNumber',
      componentProps: {
        min: 0,
        precision: 2,
        class: 'w-full',
      },
      fieldName: 'costPrice',
      label: $t('wms.product.costPrice'),
    },
    {
      component: 'Input',
      fieldName: 'barcode',
      label: $t('wms.product.barcode'),
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
    {
      component: 'InputNumber',
      componentProps: {
        min: 0,
        class: 'w-full',
      },
      fieldName: 'minStock',
      label: $t('wms.product.minStock'),
    },
    {
      component: 'InputNumber',
      componentProps: {
        min: 0,
        class: 'w-full',
      },
      fieldName: 'maxStock',
      label: $t('wms.product.maxStock'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 3,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.product.remark'),
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
      component: 'Input',
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
 * 权限选项接口
 */
interface PermissionOptions {
  canEdit?: boolean;
  canDelete?: boolean;
}

/**
 * 获取表格列配置
 * @param onActionClick 操作按钮点击回调
 * @param permissions 权限配置
 */
export function useColumns(
  onActionClick?: OnActionClickFn<ProductApi.Product>,
  permissions?: PermissionOptions,
): VxeTableGridOptions<ProductApi.Product>['columns'] {
  // 根据权限确定可用的操作按钮
  const options: string[] = [];
  if (permissions?.canEdit !== false) {
    options.push('edit');
  }
  if (permissions?.canDelete !== false) {
    options.push('delete');
  }

  const columns: VxeTableGridOptions<ProductApi.Product>['columns'] = [
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
      field: 'price',
      title: $t('wms.product.price'),
      width: 100,
      formatter: ({ cellValue }) => {
        return cellValue ? `¥${cellValue.toFixed(2)}` : '-';
      },
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
  ];

  // 只有在有操作权限时才添加操作列
  if (options.length > 0) {
    columns.push({
      align: 'right',
      cellRender: {
        attrs: {
          nameField: 'name',
          nameTitle: $t('wms.product.title'),
          onClick: onActionClick,
        },
        name: 'CellOperation',
        options,
      },
      field: 'operation',
      fixed: 'right',
      headerAlign: 'center',
      showOverflow: false,
      title: $t('common.operation'),
      width: 150,
    });
  }

  return columns;
}
