import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { ProcurementApi } from '#/api/wms/procurement';

import { z } from '#/adapter/form';
import { getProductList } from '#/api/wms/product';
import { getSupplierList } from '#/api/wms/supplier';
import { $t } from '#/locales';

// 采购单状态选项 - 与数据库 biz_procurement 表 status 字段对应
export const statusOptions = [
  { label: '待审核', value: 'PENDING', color: 'processing' },
  { label: '已审核', value: 'APPROVED', color: 'success' },
  { label: '已下单', value: 'ORDERED', color: 'warning' },
  { label: '已完成', value: 'DONE', color: 'success' },
  { label: '已取消', value: 'REJECT', color: 'error' },
];

// 状态显示映射
export const statusLabels: Record<string, string> = {
  PENDING: '待审核',
  APPROVED: '已审核',
  ORDERED: '已下单',
  DONE: '已完成',
  REJECT: '已取消',
};

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
      component: 'ApiSelect',
      componentProps: {
        api: async () => {
          const res = await getSupplierList({ pageSize: 200, status: 1 });
          return res.items.map((item) => ({
            label: item.name,
            value: item.id,
          }));
        },
        placeholder: $t('common.pleaseSelect'),
        allowClear: true,
      },
      fieldName: 'supplierId',
      label: $t('wms.procurement.supplierName'),
      rules: z
        .number()
        .min(1, $t('ui.formRules.required', [$t('wms.procurement.supplierName')])),
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
      defaultValue: 'PENDING',
      fieldName: 'status',
      label: $t('wms.procurement.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 2,
        showCount: true,
      },
      fieldName: 'reason',
      label: '采购原因',
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
  }));
}

/**
 * 获取搜索表单的字段配置
 * 字段与数据库 biz_procurement 表保持一致
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
      label: $t('wms.procurement.createTime'),
    },
  ];
}

/**
 * 获取表格列配置
 * 字段与数据库 biz_procurement 表保持一致
 */
export function useColumns(
  onActionClick?: OnActionClickFn<ProcurementApi.Procurement>,
): VxeTableGridOptions<ProcurementApi.Procurement>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'orderNo',
      title: $t('wms.procurement.orderNo'),
      width: 180,
    },
    {
      field: 'supplierName',
      title: $t('wms.procurement.supplierName'),
      minWidth: 150,
    },
    {
      field: 'reason',
      title: '采购原因',
      minWidth: 150,
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
            PENDING: 'processing',
            APPROVED: 'success',
            ORDERED: 'warning',
            DONE: 'success',
            REJECT: 'error',
          },
        },
      },
      field: 'status',
      title: $t('wms.procurement.status'),
      width: 100,
      formatter: ({ cellValue }) => {
        return statusLabels[cellValue] || cellValue;
      },
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
