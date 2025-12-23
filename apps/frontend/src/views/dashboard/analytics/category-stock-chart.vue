<script lang="ts" setup>
import type { EchartsUIType } from '@vben/plugins/echarts';

import { ref, watch } from 'vue';

import { EchartsUI, useEcharts } from '@vben/plugins/echarts';

import type { CategoryStock } from '#/api/dashboard';

const props = defineProps<{
  data: CategoryStock[];
  loading?: boolean;
}>();

const chartRef = ref<EchartsUIType>();
const { renderEcharts } = useEcharts(chartRef);

function renderChart() {
  if (props.data.length === 0) return;

  renderEcharts({
    tooltip: {
      trigger: 'item',
      formatter: '{b}: {c} ({d}%)',
    },
    legend: {
      orient: 'vertical',
      right: '5%',
      top: 'center',
    },
    series: [
      {
        name: '分类库存',
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['40%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2,
        },
        label: {
          show: false,
          position: 'center',
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 20,
            fontWeight: 'bold',
          },
        },
        labelLine: {
          show: false,
        },
        data: props.data.map((item) => ({
          name: item.name || '未分类',
          value: item.quantity,
        })),
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
