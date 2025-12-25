<script lang="ts" setup>
import type {
  OnActionClickParams,
  VxeTableGridOptions,
} from '#/adapter/vxe-table';
import type { ProcurementApi } from '#/api/wms/procurement';

import { Page, useVbenModal } from '@vben/common-ui';
import { Plus } from '@vben/icons';

import { Button, message } from 'ant-design-vue';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import {
  deleteProcurement,
  getProcurement,
  getProcurementList,
} from '#/api/wms/procurement';
import { usePermission } from '#/hooks';
import { $t } from '#/locales';

import { useColumns, useSearchSchema } from './data';
import Form from './modules/form.vue';

// 权限控制
const { canCreateProcurement } = usePermission();

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: Form,
  destroyOnClose: true,
});

/**
 * 编辑采购单
 */
async function onEdit(row: ProcurementApi.Procurement) {
  // 获取详情（包含采购明细）
  const detail = await getProcurement(row.id);
  formModalApi.setData(detail).open();
}

/**
 * 创建新采购单
 */
function onCreate() {
  formModalApi.setData(null).open();
}

/**
 * 删除采购单
 */
function onDelete(row: ProcurementApi.Procurement) {
  const hideLoading = message.loading({
    content: $t('ui.actionMessage.deleting', [row.orderNo]),
    duration: 0,
    key: 'action_process_msg',
  });
  deleteProcurement(row.id)
    .then(() => {
      message.success({
        content: $t('ui.actionMessage.deleteSuccess', [row.orderNo]),
        key: 'action_process_msg',
      });
      refreshGrid();
    })
    .catch(() => {
      hideLoading();
    });
}

/**
 * 审批采购单
 */
function onApprove(row: ProcurementApi.Procurement) {
  // TODO: 实现审批逻辑
  message.info(`审批采购单: ${row.orderNo}`);
}

/**
 * 表格操作按钮的回调函数
 */
function onActionClick({
  code,
  row,
}: OnActionClickParams<ProcurementApi.Procurement>) {
  switch (code) {
    case 'delete': {
      onDelete(row);
      break;
    }
    case 'edit': {
      onEdit(row);
      break;
    }
    case 'approve': {
      onApprove(row);
      break;
    }
  }
}

const [Grid, gridApi] = useVbenVxeGrid({
  formOptions: {
    collapsed: false,
    schema: useSearchSchema(),
    showCollapseButton: true,
    submitOnChange: false,
    fieldMappingTime: [['dateRange', ['startDate', 'endDate']]],
  },
  gridOptions: {
    columns: useColumns(onActionClick),
    height: 'auto',
    keepSource: true,
    pagerConfig: {},
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          return await getProcurementList({
            page: page.currentPage,
            pageSize: page.pageSize,
            ...formValues,
          });
        },
      },
    },
    toolbarConfig: {
      custom: true,
      export: false,
      refresh: true,
      zoom: true,
    },
  } as VxeTableGridOptions,
});

/**
 * 刷新表格
 */
function refreshGrid() {
  gridApi.query();
}
</script>

<template>
  <Page auto-content-height>
    <FormModal @success="refreshGrid" />
    <Grid :table-title="$t('wms.procurement.listTitle')">
      <template #toolbar-tools>
        <Button v-if="canCreateProcurement" type="primary" @click="onCreate">
          <Plus class="size-5" />
          {{ $t('ui.actionTitle.create', [$t('wms.procurement.title')]) }}
        </Button>
      </template>
    </Grid>
  </Page>
</template>
