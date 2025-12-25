import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { OutboundApi } from '#/api/wms/outbound';

import { z } from '#/adapter/form';
import { getProductList } from '#/api/wms/product';
import { $t } from '#/locales';

// 出库状态选项 - 与数据库 biz_outbound 表 status 字段对应
export const statusOptions = [
  { label: '待审核', value: 'pending', color: 'processing' },
  { label: '已审核', value: 'picking', color: 'warning' },
  { label: '已领用', value: 'completed', color: 'success' },
  { label: '已驳回', value: 'cancelled', color: 'error' },
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
        options: statusOptions.map((item) => ({
          label: item.label,
          value: item.value,
        })),
      },
      defaultValue: 'pending',
      fieldName: 'status',
      label: $t('wms.outbound.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 2,
        showCount: true,
      },
      fieldName: 'purpose',
      label: '领用用途',
      rules: z.string().min(1, '请填写领用用途'),
    },
  ];
}

/**
 * 获取产品选择器选项
 */
export async function getProductOptions() {
  const res = await getProductList({ pageSize: 500, status: 1 });
  return res.items.map((item) => ({
    label: `${item.code} - ${item.name}`,
    value: item.id,
    code: item.code,
    name: item.name,
    unit: item.unit,
    stockQty: (item as any).stockQty || 0,
  }));
}

/**
 * 获取搜索表单的字段配置
 * 字段与数据库 biz_outbound 表保持一致
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
      label: $t('wms.outbound.createTime'),
    },
  ];
}

/**
 * 获取表格列配置
 * 字段与数据库 biz_outbound 表保持一致
 */
export function useColumns(
  onActionClick?: OnActionClickFn<OutboundApi.Outbound>,
): VxeTableGridOptions<OutboundApi.Outbound>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'orderNo',
      title: $t('wms.outbound.orderNo'),
      width: 180,
    },
    {
      field: 'applicantName',
      title: '申请人',
      width: 100,
    },
    {
      field: 'deptName',
      title: '领用部门',
      minWidth: 120,
    },
    {
      field: 'purpose',
      title: '用途',
      minWidth: 150,
    },
    {
      field: 'totalQuantity',
      title: $t('wms.outbound.totalQuantity'),
      width: 100,
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
      field: 'outboundDate',
      title: $t('wms.outbound.outboundDate'),
      width: 120,
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
