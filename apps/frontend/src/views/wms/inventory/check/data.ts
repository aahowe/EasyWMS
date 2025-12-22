import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { InventoryApi } from '#/api/wms/inventory';

import { z } from '#/adapter/form';
import { $t } from '#/locales';

// 盘点状态选项
export const statusOptions = [
  { label: '草稿', value: 'draft', color: 'default' },
  { label: '盘点中', value: 'checking', color: 'processing' },
  { label: '已完成', value: 'completed', color: 'success' },
  { label: '已取消', value: 'cancelled', color: 'error' },
];

/**
 * 获取编辑表单的字段配置
 */
export function useSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'checkNo',
      label: $t('wms.inventoryCheck.checkNo'),
      componentProps: {
        disabled: true,
        placeholder: '系统自动生成',
      },
    },
    {
      component: 'Input',
      fieldName: 'warehouseName',
      label: $t('wms.inventoryCheck.warehouseName'),
      rules: z
        .string()
        .min(
          1,
          $t('ui.formRules.required', [$t('wms.inventoryCheck.warehouseName')]),
        ),
    },
    {
      component: 'DatePicker',
      componentProps: {
        class: 'w-full',
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'checkDate',
      label: $t('wms.inventoryCheck.checkDate'),
      rules: z
        .string()
        .min(
          1,
          $t('ui.formRules.required', [$t('wms.inventoryCheck.checkDate')]),
        ),
    },
    {
      component: 'Select',
      componentProps: {
        options: statusOptions.map((item) => ({
          label: item.label,
          value: item.value,
        })),
      },
      defaultValue: 'draft',
      fieldName: 'status',
      label: $t('wms.inventoryCheck.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 3,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.inventoryCheck.remark'),
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
      fieldName: 'checkNo',
      label: $t('wms.inventoryCheck.checkNo'),
    },
    {
      component: 'Select',
      componentProps: {
        allowClear: true,
        options: statusOptions.map((item) => ({
          label: item.label,
          value: item.value,
        })),
        placeholder: $t('common.pleaseSelect'),
      },
      fieldName: 'status',
      label: $t('wms.inventoryCheck.status'),
    },
    {
      component: 'RangePicker',
      componentProps: {
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'dateRange',
      label: $t('wms.inventoryCheck.checkDate'),
    },
  ];
}

/**
 * 获取表格列配置
 */
export function useColumns(
  onActionClick?: OnActionClickFn<InventoryApi.InventoryCheck>,
): VxeTableGridOptions<InventoryApi.InventoryCheck>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'checkNo',
      title: $t('wms.inventoryCheck.checkNo'),
      width: 160,
    },
    {
      field: 'warehouseName',
      title: $t('wms.inventoryCheck.warehouseName'),
      minWidth: 120,
    },
    {
      field: 'checkDate',
      title: $t('wms.inventoryCheck.checkDate'),
      width: 120,
    },
    {
      cellRender: {
        name: 'CellTag',
        props: {
          colors: {
            draft: 'default',
            checking: 'processing',
            completed: 'success',
            cancelled: 'error',
          },
        },
      },
      field: 'status',
      title: $t('wms.inventoryCheck.status'),
      width: 100,
    },
    {
      field: 'operatorName',
      title: $t('wms.inventoryCheck.operatorName'),
      width: 100,
    },
    {
      field: 'createTime',
      title: $t('wms.inventoryCheck.createTime'),
      width: 180,
    },
    {
      align: 'right',
      cellRender: {
        attrs: {
          nameField: 'checkNo',
          nameTitle: $t('wms.inventoryCheck.title'),
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
