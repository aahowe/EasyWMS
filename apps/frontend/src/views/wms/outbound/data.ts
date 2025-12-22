import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { OutboundApi } from '#/api/wms/outbound';

import { z } from '#/adapter/form';
import { $t } from '#/locales';

// 出库类型选项
export const typeOptions = [
  { label: '销售出库', value: 'sale' },
  { label: '退货出库', value: 'return' },
  { label: '调拨出库', value: 'transfer' },
  { label: '其他出库', value: 'other' },
];

// 出库状态选项
export const statusOptions = [
  { label: '草稿', value: 'draft', color: 'default' },
  { label: '待出库', value: 'pending', color: 'processing' },
  { label: '拣货中', value: 'picking', color: 'warning' },
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
      label: $t('wms.outbound.orderNo'),
      componentProps: {
        disabled: true,
        placeholder: '系统自动生成',
      },
    },
    {
      component: 'Select',
      componentProps: {
        options: typeOptions,
      },
      defaultValue: 'sale',
      fieldName: 'type',
      label: $t('wms.outbound.type'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.outbound.type')])),
    },
    {
      component: 'Input',
      fieldName: 'warehouseName',
      label: $t('wms.outbound.warehouseName'),
      rules: z
        .string()
        .min(
          1,
          $t('ui.formRules.required', [$t('wms.outbound.warehouseName')]),
        ),
    },
    {
      component: 'Input',
      fieldName: 'customerName',
      label: $t('wms.outbound.customerName'),
    },
    {
      component: 'DatePicker',
      componentProps: {
        class: 'w-full',
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'outboundDate',
      label: $t('wms.outbound.outboundDate'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.outbound.outboundDate')])),
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
      label: $t('wms.outbound.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 3,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.outbound.remark'),
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
      label: $t('wms.outbound.orderNo'),
    },
    {
      component: 'Select',
      componentProps: {
        allowClear: true,
        options: typeOptions,
        placeholder: $t('common.pleaseSelect'),
      },
      fieldName: 'type',
      label: $t('wms.outbound.type'),
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
      label: $t('wms.outbound.status'),
    },
    {
      component: 'RangePicker',
      componentProps: {
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'dateRange',
      label: $t('wms.outbound.outboundDate'),
    },
  ];
}

/**
 * 获取表格列配置
 */
export function useColumns(
  onActionClick?: OnActionClickFn<OutboundApi.Outbound>,
): VxeTableGridOptions<OutboundApi.Outbound>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'orderNo',
      title: $t('wms.outbound.orderNo'),
      width: 160,
    },
    {
      field: 'type',
      title: $t('wms.outbound.type'),
      width: 120,
      formatter: ({ cellValue }) => {
        const item = typeOptions.find((opt) => opt.value === cellValue);
        return item?.label || cellValue;
      },
    },
    {
      field: 'warehouseName',
      title: $t('wms.outbound.warehouseName'),
      minWidth: 120,
    },
    {
      field: 'customerName',
      title: $t('wms.outbound.customerName'),
      minWidth: 120,
    },
    {
      field: 'totalQuantity',
      title: $t('wms.outbound.totalQuantity'),
      width: 100,
    },
    {
      field: 'outboundDate',
      title: $t('wms.outbound.outboundDate'),
      width: 120,
    },
    {
      cellRender: {
        name: 'CellTag',
        props: {
          colors: {
            draft: 'default',
            pending: 'processing',
            picking: 'warning',
            completed: 'success',
            cancelled: 'error',
          },
        },
      },
      field: 'status',
      title: $t('wms.outbound.status'),
      width: 100,
    },
    {
      field: 'operatorName',
      title: $t('wms.outbound.operatorName'),
      width: 100,
    },
    {
      field: 'createTime',
      title: $t('wms.outbound.createTime'),
      width: 180,
    },
    {
      align: 'right',
      cellRender: {
        attrs: {
          nameField: 'orderNo',
          nameTitle: $t('wms.outbound.title'),
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
