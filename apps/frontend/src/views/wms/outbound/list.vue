<script lang="ts" setup>
import type {
  OnActionClickParams,
  VxeTableGridOptions,
} from '#/adapter/vxe-table';
import type { OutboundApi } from '#/api/wms/outbound';

import { Page, useVbenModal } from '@vben/common-ui';
import { Plus } from '@vben/icons';

import { Button, message } from 'ant-design-vue';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import {
  deleteOutbound,
  getOutbound,
  getOutboundList,
} from '#/api/wms/outbound';
import { usePermission } from '#/hooks';
import { $t } from '#/locales';

import { useColumns, useSearchSchema } from './data';
import Form from './modules/form.vue';

// 权限控制
const { canCreateOutbound } = usePermission();

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: Form,
  destroyOnClose: true,
});

/**
 * 编辑出库单
 */
async function onEdit(row: OutboundApi.Outbound) {
  // 获取详情（包含出库明细）
  const detail = await getOutbound(row.id);
  formModalApi.setData(detail).open();
}

/**
 * 创建新出库单（领用申请）
 */
function onCreate() {
  formModalApi.setData(null).open();
}

/**
 * 删除出库单
 */
function onDelete(row: OutboundApi.Outbound) {
  const hideLoading = message.loading({
    content: $t('ui.actionMessage.deleting', [row.orderNo]),
    duration: 0,
    key: 'action_process_msg',
  });
  deleteOutbound(row.id)
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
 * 审核出库单
 */
function onApprove(row: OutboundApi.Outbound) {
  // TODO: 实现审核逻辑
  message.info(`审核出库单: ${row.orderNo}`);
}

/**
 * 执行出库
 */
function onExecute(row: OutboundApi.Outbound) {
  // TODO: 实现执行出库逻辑
  message.info(`执行出库: ${row.orderNo}`);
}

/**
 * 表格操作按钮的回调函数
 */
function onActionClick({
  code,
  row,
}: OnActionClickParams<OutboundApi.Outbound>) {
  switch (code) {
    case 'approve': {
      onApprove(row);
      break;
    }
    case 'delete': {
      onDelete(row);
      break;
    }
    case 'edit': {
      onEdit(row);
      break;
    }
    case 'execute': {
      onExecute(row);
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
          return await getOutboundList({
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
    <Grid :table-title="$t('wms.outbound.listTitle')">
      <template #toolbar-tools>
        <Button v-if="canCreateOutbound" type="primary" @click="onCreate">
          <Plus class="size-5" />
          {{ $t('wms.outbound.applyTitle') }}
        </Button>
      </template>
    </Grid>
  </Page>
</template>
