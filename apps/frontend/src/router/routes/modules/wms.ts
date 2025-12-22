import type { RouteRecordRaw } from 'vue-router';

import { $t } from '#/locales';

const routes: RouteRecordRaw[] = [
  // 基础数据管理
  {
    meta: {
      icon: 'mdi:package-variant-closed',
      order: 10,
      title: $t('wms.basicData.title'),
    },
    name: 'WmsBasicData',
    path: '/wms/basic',
    children: [
      {
        path: '/wms/basic/product',
        name: 'WmsProduct',
        meta: {
          icon: 'mdi:package-variant',
          title: $t('wms.product.title'),
        },
        component: () => import('#/views/wms/product/list.vue'),
      },
    ],
  },
  // 采购管理
  {
    meta: {
      icon: 'mdi:cart-outline',
      order: 20,
      title: $t('wms.procurement.menuTitle'),
    },
    name: 'WmsProcurement',
    path: '/wms/procurement',
    children: [
      {
        path: '/wms/procurement/list',
        name: 'WmsProcurementList',
        meta: {
          icon: 'mdi:clipboard-list-outline',
          title: $t('wms.procurement.listTitle'),
        },
        component: () => import('#/views/wms/procurement/list.vue'),
      },
    ],
  },
  // 入库管理
  {
    meta: {
      icon: 'mdi:package-down',
      order: 30,
      title: $t('wms.inbound.menuTitle'),
    },
    name: 'WmsInbound',
    path: '/wms/inbound',
    children: [
      {
        path: '/wms/inbound/list',
        name: 'WmsInboundList',
        meta: {
          icon: 'mdi:clipboard-arrow-down-outline',
          title: $t('wms.inbound.listTitle'),
        },
        component: () => import('#/views/wms/inbound/list.vue'),
      },
    ],
  },
  // 出库管理
  {
    meta: {
      icon: 'mdi:package-up',
      order: 40,
      title: $t('wms.outbound.menuTitle'),
    },
    name: 'WmsOutbound',
    path: '/wms/outbound',
    children: [
      {
        path: '/wms/outbound/list',
        name: 'WmsOutboundList',
        meta: {
          icon: 'mdi:clipboard-arrow-up-outline',
          title: $t('wms.outbound.listTitle'),
        },
        component: () => import('#/views/wms/outbound/list.vue'),
      },
    ],
  },
  // 库存管理
  {
    meta: {
      icon: 'mdi:warehouse',
      order: 50,
      title: $t('wms.inventory.menuTitle'),
    },
    name: 'WmsInventory',
    path: '/wms/inventory',
    children: [
      {
        path: '/wms/inventory/stock',
        name: 'WmsInventoryStock',
        meta: {
          icon: 'mdi:cube-outline',
          title: $t('wms.inventory.stockListTitle'),
        },
        component: () => import('#/views/wms/inventory/stock/list.vue'),
      },
      {
        path: '/wms/inventory/check',
        name: 'WmsInventoryCheck',
        meta: {
          icon: 'mdi:clipboard-check-outline',
          title: $t('wms.inventoryCheck.listTitle'),
        },
        component: () => import('#/views/wms/inventory/check/list.vue'),
      },
    ],
  },
];

export default routes;

