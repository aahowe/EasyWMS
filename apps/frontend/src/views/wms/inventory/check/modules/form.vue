<script lang="ts" setup>
import type { InventoryApi } from '#/api/wms/inventory';

import { computed, onMounted, reactive, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import { Button, InputNumber, message, Select, Table, Tag } from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { createInventoryCheck, updateInventoryCheck } from '#/api/wms/inventory';
import { $t } from '#/locales';

import { getProductOptions, useSchema } from '../data';

interface CheckItem {
  productId: number | null;
  productName: string;
  productCode: string;
  systemQuantity: number;
  actualQuantity: number;
  differenceQuantity: number;
}

const emit = defineEmits(['success']);
const formData = ref<InventoryApi.InventoryCheck>();
const items = reactive<CheckItem[]>([]);
const productOptions = ref<any[]>([]);

const getTitle = computed(() => {
  return formData.value?.id
    ? $t('ui.actionTitle.edit', [$t('wms.inventoryCheck.title')])
    : $t('ui.actionTitle.create', [$t('wms.inventoryCheck.title')]);
});

const [Form, formApi] = useVbenForm({
  layout: 'vertical',
  schema: useSchema(),
  showDefaultActions: false,
});

// 添加明细行
function addItem() {
  items.push({
    productId: null,
    productName: '',
    productCode: '',
    systemQuantity: 0,
    actualQuantity: 0,
    differenceQuantity: 0,
  });
}

// 删除明细行
function removeItem(index: number) {
  items.splice(index, 1);
}

// 产品选择变更
function onProductChange(value: number, index: number) {
  const option = productOptions.value.find((opt) => opt.value === value);
  if (option) {
    items[index].productId = value;
    items[index].productName = option.name;
    items[index].productCode = option.code;
    items[index].systemQuantity = option.stockQty;
    calculateDifference(index);
  }
}

// 计算差异
function calculateDifference(index: number) {
  const item = items[index];
  item.differenceQuantity = (item.actualQuantity || 0) - (item.systemQuantity || 0);
}

function resetForm() {
  formApi.resetForm();
  formApi.setValues(formData.value || {});
  items.length = 0;
  if (formData.value?.items) {
    items.push(
      ...formData.value.items.map((item) => ({
        productId: Number(item.productId),
        productName: item.productName || '',
        productCode: item.productCode || '',
        systemQuantity: item.systemQuantity,
        actualQuantity: item.actualQuantity,
        differenceQuantity: item.differenceQuantity,
      })),
    );
  }
}

// 加载产品选项
onMounted(async () => {
  productOptions.value = await getProductOptions();
});

const columns = [
  {
    title: '产品',
    dataIndex: 'productId',
    width: 180,
  },
  {
    title: '系统库存',
    dataIndex: 'systemQuantity',
    width: 90,
  },
  {
    title: '实际库存',
    dataIndex: 'actualQuantity',
    width: 100,
  },
  {
    title: '差异',
    dataIndex: 'differenceQuantity',
    width: 80,
  },
  {
    title: '操作',
    dataIndex: 'action',
    width: 70,
  },
];

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (valid) {
      if (items.length === 0) {
        message.warning('请至少添加一个盘点明细');
        return;
      }
      const hasInvalidItem = items.some((item) => !item.productId);
      if (hasInvalidItem) {
        message.warning('请完善盘点明细信息');
        return;
      }

      modalApi.lock();
      const data = await formApi.getValues();
      try {
        const submitData = {
          ...data,
          items: items.map((item) => ({
            productId: item.productId,
            systemQuantity: item.systemQuantity,
            actualQuantity: item.actualQuantity,
          })),
        };
        await (formData.value?.id
          ? updateInventoryCheck(formData.value.id, submitData)
          : createInventoryCheck(submitData));
        modalApi.close();
        emit('success');
      } finally {
        modalApi.lock(false);
      }
    }
  },
  onOpenChange(isOpen) {
    if (isOpen) {
      const data = modalApi.getData<InventoryApi.InventoryCheck>();
      if (data) {
        formData.value = data;
        formApi.setValues({
          checkNo: data.checkNo,
          status: data.status || 'checking',
          remark: data.remark,
        });
        items.length = 0;
        if (data.items) {
          items.push(
            ...data.items.map((item) => ({
              productId: Number(item.productId),
              productName: item.productName || '',
              productCode: item.productCode || '',
              systemQuantity: item.systemQuantity,
              actualQuantity: item.actualQuantity,
              differenceQuantity: item.differenceQuantity,
            })),
          );
        }
      } else {
        formData.value = undefined;
        formApi.resetForm();
        items.length = 0;
        addItem();
      }
    }
  },
});
</script>

<template>
  <Modal :title="getTitle" class="w-[750px]">
    <Form class="mx-4" />
    <div class="mx-4 mb-4">
      <div class="mb-2 flex items-center justify-between">
        <span class="font-medium">盘点明细</span>
        <Button type="primary" size="small" @click="addItem">添加</Button>
      </div>
      <Table
        :columns="columns"
        :data-source="items"
        :pagination="false"
        size="small"
        bordered
      >
        <template #bodyCell="{ column, record, index }">
          <template v-if="column.dataIndex === 'productId'">
            <Select
              v-model:value="record.productId"
              :options="productOptions"
              style="width: 100%"
              placeholder="选择产品"
              show-search
              :filter-option="
                (input: string, option: any) =>
                  option.label.toLowerCase().includes(input.toLowerCase())
              "
              @change="(val: number) => onProductChange(val, index)"
            />
          </template>
          <template v-else-if="column.dataIndex === 'systemQuantity'">
            <Tag color="blue">{{ record.systemQuantity }}</Tag>
          </template>
          <template v-else-if="column.dataIndex === 'actualQuantity'">
            <InputNumber
              v-model:value="record.actualQuantity"
              :min="0"
              :precision="0"
              style="width: 100%"
              @change="calculateDifference(index)"
            />
          </template>
          <template v-else-if="column.dataIndex === 'differenceQuantity'">
            <Tag
              :color="
                record.differenceQuantity === 0
                  ? 'green'
                  : record.differenceQuantity > 0
                    ? 'blue'
                    : 'red'
              "
            >
              {{ record.differenceQuantity > 0 ? '+' : ''
              }}{{ record.differenceQuantity }}
            </Tag>
          </template>
          <template v-else-if="column.dataIndex === 'action'">
            <Button
              type="link"
              danger
              size="small"
              :disabled="items.length <= 1"
              @click="removeItem(index)"
            >
              删除
            </Button>
          </template>
        </template>
      </Table>
    </div>
    <template #prepend-footer>
      <div class="flex-auto">
        <Button type="primary" danger @click="resetForm">
          {{ $t('common.reset') }}
        </Button>
      </div>
    </template>
  </Modal>
</template>
