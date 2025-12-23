<script lang="ts" setup>
import type {
  WorkbenchQuickNavItem,
  WorkbenchTodoItem,
  WorkbenchTrendItem,
} from '@vben/common-ui';

import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';

import {
  AnalysisChartCard,
  WorkbenchHeader,
  WorkbenchQuickNav,
  WorkbenchTodo,
  WorkbenchTrends,
} from '@vben/common-ui';
import { preferences } from '@vben/preferences';
import { useUserStore } from '@vben/stores';

import { getRecentActivities } from '#/api/dashboard';
import type { RecentActivity } from '#/api/dashboard';

import CategoryStockChart from '../analytics/category-stock-chart.vue';
import { getCategoryStock } from '#/api/dashboard';
import type { CategoryStock } from '#/api/dashboard';

const userStore = useUserStore();
const router = useRouter();

// 分类库存数据
const categoryStock = ref<CategoryStock[]>([]);

// 快捷导航 - WMS相关功能
const quickNavItems: WorkbenchQuickNavItem[] = [
  {
    color: '#1fdaca',
    icon: 'ion:home-outline',
    title: '数据总览',
    url: '/analytics',
  },
  {
    color: '#3fb27f',
    icon: 'ion:cube-outline',
    title: '产品管理',
    url: '/wms/basic/product',
  },
  {
    color: '#e18525',
    icon: 'ion:cart-outline',
    title: '采购管理',
    url: '/wms/procurement',
  },
  {
    color: '#bf0c2c',
    icon: 'ion:arrow-down-circle-outline',
    title: '入库管理',
    url: '/wms/inbound',
  },
  {
    color: '#4daf1bc9',
    icon: 'ion:arrow-up-circle-outline',
    title: '出库管理',
    url: '/wms/outbound',
  },
  {
    color: '#00d8ff',
    icon: 'ion:layers-outline',
    title: '库存查询',
    url: '/wms/inventory/stock',
  },
];

// 待办事项
const todoItems = ref<WorkbenchTodoItem[]>([
  {
    completed: false,
    content: '检查低库存产品，及时发起采购申请',
    date: new Date().toISOString().slice(0, 10),
    title: '库存预警处理',
  },
  {
    completed: false,
    content: '审核今日待入库的采购订单',
    date: new Date().toISOString().slice(0, 10),
    title: '入库单审核',
  },
  {
    completed: false,
    content: '处理待出库的发货申请',
    date: new Date().toISOString().slice(0, 10),
    title: '出库单处理',
  },
  {
    completed: true,
    content: '完成本月库存盘点工作',
    date: new Date().toISOString().slice(0, 10),
    title: '库存盘点',
  },
]);

// 最近动态
const trendItems = ref<WorkbenchTrendItem[]>([]);

// 获取动态类型标签
function getActivityLabel(type: string) {
  const labels: Record<string, string> = {
    IN: '入库',
    OUT: '出库',
    ADJUST: '调整',
  };
  return labels[type] || type;
}

// 加载最近动态
async function loadActivities() {
  try {
    const activities = await getRecentActivities();
    trendItems.value = activities.map((item: RecentActivity) => ({
      avatar: 'svg:avatar-1',
      content: `执行了 <a>${getActivityLabel(item.type)}</a> 操作，单号 <a>${item.orderNo}</a>`,
      date: item.createdAt,
      title: item.operator || '系统',
    }));
  } catch (error) {
    console.error('Failed to load activities:', error);
  }
}

// 加载分类库存
async function loadCategoryStock() {
  try {
    categoryStock.value = await getCategoryStock();
  } catch (error) {
    console.error('Failed to load category stock:', error);
  }
}

// 导航方法
function navTo(nav: WorkbenchQuickNavItem) {
  if (nav.url?.startsWith('/')) {
    router.push(nav.url).catch((error) => {
      console.error('Navigation failed:', error);
    });
  }
}

onMounted(() => {
  loadActivities();
  loadCategoryStock();
});
</script>

<template>
  <div class="p-5">
    <WorkbenchHeader
      :avatar="userStore.userInfo?.avatar || preferences.app.defaultAvatar"
    >
      <template #title>
        早安，{{ userStore.userInfo?.realName || '用户' }}，欢迎使用EasyWMS仓库管理系统！
      </template>
      <template #description>
        高效管理您的仓库，实时掌握库存动态
      </template>
    </WorkbenchHeader>

    <div class="mt-5 flex flex-col lg:flex-row">
      <div class="w-full lg:mr-4 lg:w-2/5">
        <WorkbenchQuickNav
          :items="quickNavItems"
          title="快捷导航"
          @click="navTo"
        />
        <WorkbenchTodo :items="todoItems" class="mt-5" title="待办事项" />
      </div>
      <div class="mt-5 w-full lg:mt-0 lg:w-3/5">
        <WorkbenchTrends :items="trendItems" title="最近操作动态" />
        <AnalysisChartCard class="mt-5" title="分类库存分布">
          <CategoryStockChart :data="categoryStock" />
        </AnalysisChartCard>
      </div>
    </div>
  </div>
</template>
