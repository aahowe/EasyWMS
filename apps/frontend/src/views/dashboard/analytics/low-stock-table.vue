<script lang="ts" setup>
import { Tag } from 'ant-design-vue';

import type { LowStockProduct } from '#/api/dashboard';

const props = withDefaults(
  defineProps<{
    data: LowStockProduct[];
    loading?: boolean;
  }>(),
  {
    data: () => [],
    loading: false,
  },
);

function getStockLevel(stockQty: number, alertThreshold: number) {
  const ratio = stockQty / alertThreshold;
  if (ratio < 0.3) return { color: 'red', text: '严重不足' };
  if (ratio < 0.6) return { color: 'orange', text: '库存偏低' };
  return { color: 'gold', text: '接近预警' };
}
</script>

<template>
  <div class="h-[300px] overflow-auto">
    <div v-if="props.loading" class="flex h-full items-center justify-center">
      <span class="text-gray-400">加载中...</span>
    </div>
    <div v-else-if="!props.data || props.data.length === 0" class="flex h-full items-center justify-center">
      <span class="text-green-500">暂无低库存产品，库存状态良好！</span>
    </div>
    <table v-else class="w-full text-sm">
      <thead class="bg-gray-50 dark:bg-gray-800">
        <tr>
          <th class="px-3 py-2 text-left">产品编码</th>
          <th class="px-3 py-2 text-left">产品名称</th>
          <th class="px-3 py-2 text-right">当前库存</th>
          <th class="px-3 py-2 text-right">预警阈值</th>
          <th class="px-3 py-2 text-center">状态</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="item in props.data"
          :key="item.id"
          class="border-b border-gray-100 dark:border-gray-700"
        >
          <td class="px-3 py-2">{{ item.skuCode }}</td>
          <td class="px-3 py-2">{{ item.name }}</td>
          <td class="px-3 py-2 text-right font-medium text-red-500">
            {{ item.stockQty }}
          </td>
          <td class="px-3 py-2 text-right">{{ item.alertThreshold }}</td>
          <td class="px-3 py-2 text-center">
            <Tag :color="getStockLevel(item.stockQty, item.alertThreshold).color">
              {{ getStockLevel(item.stockQty, item.alertThreshold).text }}
            </Tag>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

