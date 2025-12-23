<script lang="ts" setup>
import type { AnalysisOverviewItem } from '@vben/common-ui';

import { computed, onMounted, ref } from 'vue';

import { AnalysisChartCard, AnalysisOverview } from '@vben/common-ui';
import {
  SvgBellIcon,
  SvgCakeIcon,
  SvgCardIcon,
  SvgDownloadIcon,
} from '@vben/icons';

import {
  getCategoryStock,
  getLowStockProducts,
  getOverviewStats,
  getStockTrend,
} from '#/api/dashboard';
import type {
  CategoryStock,
  LowStockProduct,
  OverviewStats,
  StockTrendItem,
} from '#/api/dashboard';

import StockTrendChart from './stock-trend-chart.vue';
import CategoryStockChart from './category-stock-chart.vue';
import LowStockTable from './low-stock-table.vue';

// 概览数据
const stats = ref<OverviewStats>({
  productCount: 0,
  totalStock: 0,
  pendingInbound: 0,
  pendingOutbound: 0,
  lowStockCount: 0,
  todayInbound: 0,
  todayOutbound: 0,
  procurementCount: 0,
});

// 库存趋势数据
const stockTrend = ref<StockTrendItem[]>([]);

// 分类库存数据
const categoryStock = ref<CategoryStock[]>([]);

// 低库存产品数据
const lowStockProducts = ref<LowStockProduct[]>([]);

// 加载中状态
const loading = ref(true);

// 概览项目配置
const overviewItems = computed((): AnalysisOverviewItem[] => [
  {
    icon: SvgCardIcon,
    title: '产品数量',
    totalTitle: '总库存量',
    totalValue: Math.round(stats.value.totalStock),
    value: stats.value.productCount,
  },
  {
    icon: SvgCakeIcon,
    title: '待入库单',
    totalTitle: '今日入库',
    totalValue: stats.value.todayInbound,
    value: stats.value.pendingInbound,
  },
  {
    icon: SvgDownloadIcon,
    title: '待出库单',
    totalTitle: '今日出库',
    totalValue: stats.value.todayOutbound,
    value: stats.value.pendingOutbound,
  },
  {
    icon: SvgBellIcon,
    title: '库存预警',
    totalTitle: '采购单数',
    totalValue: stats.value.procurementCount,
    value: stats.value.lowStockCount,
  },
]);

// 加载数据
async function loadData() {
  loading.value = true;
  try {
    const [statsRes, trendRes, categoryRes, lowStockRes] = await Promise.all([
      getOverviewStats(),
      getStockTrend(),
      getCategoryStock(),
      getLowStockProducts(),
    ]);

    stats.value = statsRes || stats.value;
    stockTrend.value = trendRes || [];
    categoryStock.value = categoryRes || [];
    lowStockProducts.value = lowStockRes || [];
  } catch (error) {
    console.error('Failed to load dashboard data:', error);
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadData();
});
</script>

<template>
  <div class="p-5">
    <AnalysisOverview :items="overviewItems" />

    <div class="mt-5">
      <AnalysisChartCard title="库存变化趋势（近7天）">
        <StockTrendChart :data="stockTrend" :loading="loading" />
      </AnalysisChartCard>
    </div>

    <div class="mt-5 w-full md:flex">
      <AnalysisChartCard class="md:mr-4 md:w-1/2" title="分类库存分布">
        <CategoryStockChart :data="categoryStock" :loading="loading" />
      </AnalysisChartCard>
      <AnalysisChartCard class="mt-5 md:mt-0 md:w-1/2" title="低库存预警">
        <LowStockTable :data="lowStockProducts" :loading="loading" />
      </AnalysisChartCard>
    </div>
  </div>
</template>
