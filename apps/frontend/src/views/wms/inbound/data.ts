import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { InboundApi } from '#/api/wms/inbound';

import { z } from '#/adapter/form';
import { $t } from '#/locales';

// 入库类型选项
export const typeOptions = [
  { label: '采购入库', value: 'purchase' },
  { label: '退货入库', value: 'return' },
  { label: '调拨入库', value: 'transfer' },
  { label: '其他入库', value: 'other' },
];

// 入库状态选项
export const statusOptions = [
  { label: '草稿', value: 'draft', color: 'default' },
  { label: '待入库', value: 'pending', color: 'processing' },
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
      label: $t('wms.inbound.orderNo'),
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
      defaultValue: 'purchase',
      fieldName: 'type',
      label: $t('wms.inbound.type'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.inbound.type')])),
    },
    {
      component: 'Input',
      fieldName: 'warehouseName',
      label: $t('wms.inbound.warehouseName'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.inbound.warehouseName')])),
    },
    {
      component: 'Input',
      fieldName: 'sourceOrderNo',
      label: $t('wms.inbound.sourceOrderNo'),
    },
    {
      component: 'DatePicker',
      componentProps: {
        class: 'w-full',
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'inboundDate',
      label: $t('wms.inbound.inboundDate'),
      rules: z
        .string()
        .min(1, $t('ui.formRules.required', [$t('wms.inbound.inboundDate')])),
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
      label: $t('wms.inbound.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 3,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.inbound.remark'),
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
      label: $t('wms.inbound.orderNo'),
    },
    {
      component: 'Select',
      componentProps: {
        allowClear: true,
        options: typeOptions,
        placeholder: $t('common.pleaseSelect'),
      },
      fieldName: 'type',
      label: $t('wms.inbound.type'),
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
      label: $t('wms.inbound.status'),
    },
    {
      component: 'RangePicker',
      componentProps: {
        valueFormat: 'YYYY-MM-DD',
      },
      fieldName: 'dateRange',
      label: $t('wms.inbound.inboundDate'),
    },
  ];
}

/**
 * 获取表格列配置
 */
export function useColumns(
  onActionClick?: OnActionClickFn<InboundApi.Inbound>,
): VxeTableGridOptions<InboundApi.Inbound>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'orderNo',
      title: $t('wms.inbound.orderNo'),
      width: 160,
    },
    {
      field: 'type',
      title: $t('wms.inbound.type'),
      width: 120,
      formatter: ({ cellValue }) => {
        const item = typeOptions.find((opt) => opt.value === cellValue);
        return item?.label || cellValue;
      },
    },
    {
      field: 'warehouseName',
      title: $t('wms.inbound.warehouseName'),
      minWidth: 120,
    },
    {
      field: 'sourceOrderNo',
      title: $t('wms.inbound.sourceOrderNo'),
      width: 160,
    },
    {
      field: 'totalQuantity',
      title: $t('wms.inbound.totalQuantity'),
      width: 100,
    },
    {
      field: 'inboundDate',
      title: $t('wms.inbound.inboundDate'),
      width: 120,
    },
    {
      cellRender: {
        name: 'CellTag',
        props: {
          colors: {
            draft: 'default',
            pending: 'processing',
            completed: 'success',
            cancelled: 'error',
          },
        },
      },
      field: 'status',
      title: $t('wms.inbound.status'),
      width: 100,
    },
    {
      field: 'operatorName',
      title: $t('wms.inbound.operatorName'),
      width: 100,
    },
    {
      field: 'createTime',
      title: $t('wms.inbound.createTime'),
      width: 180,
    },
    {
      align: 'right',
      cellRender: {
        attrs: {
          nameField: 'orderNo',
          nameTitle: $t('wms.inbound.title'),
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
