import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { ProcurementApi } from '#/api/wms/procurement';

import { z } from '#/adapter/form';
import { $t } from '#/locales';

// 采购单状态选项
export const statusOptions = [
  { label: '草稿', value: 'draft', color: 'default' },
  { label: '待审核', value: 'pending', color: 'processing' },
  { label: '已审核', value: 'approved', color: 'success' },
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
      fieldName: 'orderNo',
      label: $t('wms.procurement.orderNo'),
      componentProps: {
        disabled: true,
        placeholder: '系统自动生成',
      },
    },
    {
      component: 'Input',
      fieldName: 'supplierName',
      label: $t('wms.procurement.supplierName'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.procurement.supplierName')])),
    },
    {
      component: 'DatePicker',
      componentProps: {
        class: 'w-full',
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'orderDate',
      label: $t('wms.procurement.orderDate'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.procurement.orderDate')])),
    },
    {
      component: 'DatePicker',
      componentProps: {
        class: 'w-full',
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'expectedDate',
      label: $t('wms.procurement.expectedDate'),
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
      label: $t('wms.procurement.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 3,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.procurement.remark'),
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
      fieldName: 'orderNo',
      label: $t('wms.procurement.orderNo'),
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
      label: $t('wms.procurement.status'),
    },
    {
      component: 'RangePicker',
      componentProps: {
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'dateRange',
      label: $t('wms.procurement.orderDate'),
    },
  ];
}

/**
 * 获取表格列配置
 */
export function useColumns(
  onActionClick?: OnActionClickFn<ProcurementApi.Procurement>,
): VxeTableGridOptions<ProcurementApi.Procurement>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'orderNo',
      title: $t('wms.procurement.orderNo'),
      width: 160,
    },
    {
      field: 'supplierName',
      title: $t('wms.procurement.supplierName'),
      minWidth: 150,
    },
    {
      field: 'orderDate',
      title: $t('wms.procurement.orderDate'),
      width: 120,
    },
    {
      field: 'expectedDate',
      title: $t('wms.procurement.expectedDate'),
      width: 120,
    },
    {
      field: 'totalAmount',
      title: $t('wms.procurement.totalAmount'),
      width: 120,
      formatter: ({ cellValue }) => {
        return cellValue ? `¥${cellValue.toFixed(2)}` : '-';
      },
    },
    {
      cellRender: {
        name: 'CellTag',
        props: {
          colors: {
            draft: 'default',
            pending: 'processing',
            approved: 'success',
            completed: 'success',
            cancelled: 'error',
          },
        },
      },
      field: 'status',
      title: $t('wms.procurement.status'),
      width: 100,
    },
    {
      field: 'createTime',
      title: $t('wms.procurement.createTime'),
      width: 180,
    },
    {
      align: 'right',
      cellRender: {
        attrs: {
          nameField: 'orderNo',
          nameTitle: $t('wms.procurement.title'),
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
