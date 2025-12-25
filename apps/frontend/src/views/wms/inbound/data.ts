import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';

import type { VbenFormSchema } from '#/adapter/form';
import type { OnActionClickFn } from '#/adapter/vxe-table';
import type { InboundApi } from '#/api/wms/inbound';

import { getProcurementList } from '#/api/wms/procurement';
import { getProductList } from '#/api/wms/product';
import { $t } from '#/locales';

// 入库类型选项 - 用于前端显示
export const typeOptions = [
  { label: '采购入库', value: 'purchase' },
  { label: '其他入库', value: 'other' },
];

// 入库状态选项 - 与数据库 biz_inbound 表 status 字段对应 (0-草稿, 1-已完成)
export const statusOptions = [
  { label: '草稿', value: 'draft', color: 'default' },
  { label: '已完成', value: 'completed', color: 'success' },
];

/**
 * 获取编辑表单的字段配置
 * 字段与数据库 biz_inbound 表保持一致（除日期外均可编辑）
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
      component: 'ApiSelect',
      componentProps: {
        api: async () => {
          // 获取已审核、已下单、已完成的采购单作为来源单
          const res = await getProcurementList({
            pageSize: 500,
          });
          // 过滤出可用的采购单状态：APPROVED, ORDERED, DONE
          const validStatuses = new Set(['APPROVED', 'DONE', 'ORDERED']);
          return res.items
            .filter((item) => validStatuses.has(item.status || ''))
            .map((item) => ({
              label: `${item.orderNo} - ${item.supplierName || '未指定供应商'}`,
              value: item.id,
            }));
        },
        placeholder: '选择采购单（可选）',
        allowClear: true,
        showSearch: true,
        filterOption: (input: string, option: any) =>
          option.label.toLowerCase().includes(input.toLowerCase()),
      },
      fieldName: 'sourceId',
      label: $t('wms.inbound.sourceOrderNo'),
    },
    {
      component: 'Select',
      componentProps: {
        options: [
          { label: '正常入库', value: 0 },
          { label: '暂估入库', value: 1 },
        ],
      },
      defaultValue: 0,
      fieldName: 'isTemporary',
      label: '入库方式',
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
        rows: 2,
        showCount: true,
      },
      fieldName: 'remark',
      label: $t('wms.inbound.remark'),
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
 * 字段与数据库 biz_inbound 表保持一致
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
      label: $t('wms.inbound.createTime'),
    },
  ];
}

/**
 * 获取表格列配置
 * 字段与数据库 biz_inbound 表保持一致
 */
export function useColumns(
  onActionClick?: OnActionClickFn<InboundApi.Inbound>,
): VxeTableGridOptions<InboundApi.Inbound>['columns'] {
  return [
    { title: '序号', type: 'seq', width: 60 },
    {
      field: 'orderNo',
      title: $t('wms.inbound.orderNo'),
      width: 180,
    },
    {
      field: 'type',
      title: $t('wms.inbound.type'),
      width: 100,
      formatter: ({ cellValue }) => {
        const item = typeOptions.find((opt) => opt.value === cellValue);
        return item?.label || '其他入库';
      },
    },
    {
      field: 'sourceOrderNo',
      title: $t('wms.inbound.sourceOrderNo'),
      width: 180,
      formatter: ({ cellValue }) => {
        return cellValue || '-';
      },
    },
    {
      field: 'totalQuantity',
      title: $t('wms.inbound.totalQuantity'),
      width: 100,
    },
    {
      cellRender: {
        name: 'CellTag',
        props: {
          colors: {
            draft: 'default',
            completed: 'success',
          },
        },
      },
      field: 'status',
      title: $t('wms.inbound.status'),
      width: 100,
    },
    {
      field: 'inboundDate',
      title: $t('wms.inbound.inboundDate'),
      width: 180,
      formatter: ({ cellValue }) => {
        if (!cellValue) return '-';
        // 格式化日期时间
        const date = new Date(cellValue);
        return date.toLocaleString('zh-CN', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
        });
      },
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
