import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { InventoryApi } from '#/api/wms/inventory';

import { getProductList } from '#/api/wms/product';
import { $t } from '#/locales';

// 盘点状态选项 - 与数据库 biz_inventory_check 表 status 字段对应
export const statusOptions = [
  { label: '盘点中', value: 'checking', color: 'processing' },
  { label: '已完成', value: 'completed', color: 'success' },
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
      component: 'Select',
      componentProps: {
        options: statusOptions.map((item) => ({
          label: item.label,
          value: item.value,
        })),
      },
      defaultValue: 'checking',
      fieldName: 'status',
      label: $t('wms.inventoryCheck.status'),
    },
    {
      component: 'Textarea',
      componentProps: {
        maxLength: 200,
        rows: 2,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.inventoryCheck.remark'),
    },
  ];
}

/**
 * 获取产品选择器选项（包含库存信息）
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
 * 字段与数据库 biz_inventory_check 表保持一致
 */
export function useColumns(
  onActionClick?: OnActionClickFn<InventoryApi.InventoryCheck>,
): VxeTableGridOptions<InventoryApi.InventoryCheck>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'checkNo',
      title: $t('wms.inventoryCheck.checkNo'),
      width: 180,
    },
    {
      cellRender: {
        name: 'CellTag',
        props: {
          colors: {
            checking: 'processing',
            completed: 'success',
          },
        },
      },
      field: 'status',
      title: $t('wms.inventoryCheck.status'),
      width: 100,
    },
    {
      field: 'checkDate',
      title: $t('wms.inventoryCheck.checkDate'),
      width: 120,
    },
    {
      field: 'operatorName',
      title: $t('wms.inventoryCheck.operatorName'),
      width: 100,
    },
    {
      field: 'remark',
      title: $t('wms.inventoryCheck.remark'),
      minWidth: 150,
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
