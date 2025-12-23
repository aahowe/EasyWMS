<script lang="ts" setup>
import type { EchartsUIType } from '@vben/plugins/echarts';

import { ref, watch } from 'vue';

import { EchartsUI, useEcharts } from '@vben/plugins/echarts';

import type { StockTrendItem } from '#/api/dashboard';

const props = defineProps<{
  data: StockTrendItem[];
  loading?: boolean;
}>();

const chartRef = ref<EchartsUIType>();
const { renderEcharts } = useEcharts(chartRef);

function renderChart() {
  if (props.data.length === 0) return;

  renderEcharts({
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow',
      },
    },
    legend: {
      data: ['入库', '出库'],
      bottom: 0,
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '15%',
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: props.data.map((item) => item.date.slice(5)),
    },
    yAxis: {
      type: 'value',
      name: '数量',
    },
    series: [
      {
        name: '入库',
        type: 'bar',
        data: props.data.map((item) => item.inbound),
        itemStyle: {
          color: '#10b981',
        },
      },
      {
        name: '出库',
        type: 'bar',
        data: props.data.map((item) => item.outbound),
        itemStyle: {
          color: '#f59e0b',
        },
      },
    ],
  });
}

watch(
  () => props.data,
  () => {
    renderChart();
  },
  { immediate: true },
);
</script>

<template>
  <div class="relative h-[300px] w-full">
    <div v-if="loading" class="absolute inset-0 flex items-center justify-center">
      <span class="text-gray-400">加载中...</span>
    </div>
    <div v-else-if="data.length === 0" class="absolute inset-0 flex items-center justify-center">
      <span class="text-gray-400">暂无数据</span>
    </div>
    <EchartsUI ref="chartRef" class="h-full w-full" />
  </div>
</template>
