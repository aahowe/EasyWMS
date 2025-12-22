import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { InventoryApi } from '#/api/wms/inventory';

import { $t } from '#/locales';

/**
 * 获取搜索表单的字段配置
 */
export function useSearchSchema(): VbenFormSchema[] {
  return [
    {
      component: 'Input',
      fieldName: 'productName',
      label: $t('wms.inventory.productName'),
      componentProps: {
        placeholder: $t('wms.inventory.productNamePlaceholder'),
      },
    },
    {
      component: 'Input',
      fieldName: 'warehouseId',
      label: $t('wms.inventory.warehouseName'),
    },
    {
      component: 'Switch',
      fieldName: 'lowStock',
      label: $t('wms.inventory.lowStockOnly'),
      componentProps: {
        checkedChildren: '是',
        unCheckedChildren: '否',
      },
    },
  ];
}

/**
 * 获取表格列配置
 */
export function useColumns(): VxeTableGridOptions<InventoryApi.Stock>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'productCode',
      title: $t('wms.inventory.productCode'),
      width: 120,
    },
    {
      field: 'productName',
      title: $t('wms.inventory.productName'),
      minWidth: 150,
    },
    {
      field: 'warehouseName',
      title: $t('wms.inventory.warehouseName'),
      width: 120,
    },
    {
      field: 'locationName',
      title: $t('wms.inventory.locationName'),
      width: 120,
    },
    {
      field: 'batchNo',
      title: $t('wms.inventory.batchNo'),
      width: 120,
    },
    {
      field: 'quantity',
      title: $t('wms.inventory.quantity'),
      width: 100,
      cellRender: {
        name: 'CellTag',
        props: {
          type: 'number',
        },
      },
    },
    {
      field: 'availableQuantity',
      title: $t('wms.inventory.availableQuantity'),
      width: 120,
    },
    {
      field: 'lockedQuantity',
      title: $t('wms.inventory.lockedQuantity'),
      width: 100,
    },
    {
      field: 'costPrice',
      title: $t('wms.inventory.costPrice'),
      width: 100,
      formatter: ({ cellValue }) => {
        return cellValue ? `¥${cellValue.toFixed(2)}` : '-';
      },
    },
    {
      field: 'expirationDate',
      title: $t('wms.inventory.expirationDate'),
      width: 120,
    },
    {
      field: 'updateTime',
      title: $t('wms.inventory.updateTime'),
      width: 180,
    },
  ];
}
