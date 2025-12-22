<script lang="ts" setup>
import type { VxeTableGridOptions } from '#/adapter/vxe-table';

import { Page } from '@vben/common-ui';

import { useVbenVxeGrid } from '#/adapter/vxe-table';
import { getStockList } from '#/api/wms/inventory';
import { $t } from '#/locales';

import { useColumns, useSearchSchema } from './data';

const [Grid] = useVbenVxeGrid({
  formOptions: {
    collapsed: false,
    schema: useSearchSchema(),
    showCollapseButton: true,
    submitOnChange: false,
  },
  gridOptions: {
    columns: useColumns(),
    height: 'auto',
    keepSource: true,
    pagerConfig: {},
    proxyConfig: {
      ajax: {
        query: async ({ page }, formValues) => {
          return await getStockList({
            page: page.currentPage,
            pageSize: page.pageSize,
            ...formValues,
          });
        },
      },
    },
    toolbarConfig: {
      custom: true,
      export: true,
      refresh: true,
      zoom: true,
    },
  } as VxeTableGridOptions,
});
</script>

<template>
  <Page auto-content-height>
    <Grid :table-title="$t('wms.inventory.stockListTitle')" />
  </Page>
</template>
