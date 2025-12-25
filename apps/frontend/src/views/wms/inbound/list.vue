<script lang="ts" setup>
import type {
  OnActionClickParams,
  VxeTableGridOptions,
} from '#/adapter/vxe-table';
import type { InboundApi } from '#/api/wms/inbound';

import { Page, useVbenModal } from '@vben/common-ui';
import { Plus } from '@vben/icons';

import { Button, message } from 'ant-design-vue';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { deleteInbound, getInbound, getInboundList } from '#/api/wms/inbound';
import { $t } from '#/locales';

import { useColumns, useSearchSchema } from './data';
import Form from './modules/form.vue';

const [FormModal, formModalApi] = useVbenModal({
  connectedComponent: Form,
  destroyOnClose: true,
});

/**
 * 编辑入库单
 */
async function onEdit(row: InboundApi.Inbound) {
  // 获取详情（包含入库明细）
  const detail = await getInbound(row.id);
  formModalApi.setData(detail).open();
}

/**
 * 创建新入库单
 */
function onCreate() {
  formModalApi.setData(null).open();
}

/**
 * 删除入库单
 */
function onDelete(row: InboundApi.Inbound) {
  const hideLoading = message.loading({
    content: $t('ui.actionMessage.deleting', [row.orderNo]),
    duration: 0,
    key: 'action_process_msg',
  });
  deleteInbound(row.id)
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
 * 表格操作按钮的回调函数
 */
function onActionClick({ code, row }: OnActionClickParams<InboundApi.Inbound>) {
  switch (code) {
    case 'delete': {
      onDelete(row);
      break;
    }
    case 'edit': {
      onEdit(row);
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
          return await getInboundList({
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
    <Grid :table-title="$t('wms.inbound.listTitle')">
      <template #toolbar-tools>
        <Button type="primary" @click="onCreate">
          <Plus class="size-5" />
          {{ $t('ui.actionTitle.create', [$t('wms.inbound.title')]) }}
        </Button>
      </template>
    </Grid>
  </Page>
</template>
