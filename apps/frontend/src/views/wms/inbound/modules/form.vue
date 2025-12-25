<script lang="ts" setup>
import type { InboundApi } from '#/api/wms/inbound';

import { computed, onMounted, reactive, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import {
  Button,
  Input,
  InputNumber,
  message,
  Select,
  Table,
} from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { createInbound, updateInbound } from '#/api/wms/inbound';
import { $t } from '#/locales';

import { getProductOptions, useSchema } from '../data';

interface InboundItem {
  productId: null | number;
  productName: string;
  productCode: string;
  quantity: number;
  location: string;
}

const emit = defineEmits(['success']);
const formData = ref<InboundApi.Inbound>();
const items = reactive<InboundItem[]>([]);
const productOptions = ref<any[]>([]);

const getTitle = computed(() => {
  return formData.value?.id
    ? $t('ui.actionTitle.edit', [$t('wms.inbound.title')])
    : $t('ui.actionTitle.create', [$t('wms.inbound.title')]);
});

const [Form, formApi] = useVbenForm({
  layout: 'vertical',
  schema: useSchema(),
  showDefaultActions: false,
});

// 计算总数量
const totalQuantity = computed(() => {
  return items.reduce((sum, item) => sum + (item.quantity || 0), 0);
});

// 添加明细行
function addItem() {
  items.push({
    productId: null,
    productName: '',
    productCode: '',
    quantity: 1,
    location: '',
  });
}

// 删除明细行
function removeItem(index: number) {
  items.splice(index, 1);
}

// 产品选择变更
function onProductChange(value: number | undefined, index: number) {
  if (value === undefined) return;
  const option = productOptions.value.find((opt) => opt.value === value);
  const item = items[index];
  if (option && item) {
    item.productId = value;
    item.productName = option.name;
    item.productCode = option.code;
  }
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
        quantity: item.quantity,
        location: item.locationName || '',
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
    width: 200,
  },
  {
    title: '数量',
    dataIndex: 'quantity',
    width: 100,
  },
  {
    title: '库位',
    dataIndex: 'location',
    width: 120,
  },
  {
    title: '操作',
    dataIndex: 'action',
    width: 80,
  },
];

const [Modal, modalApi] = useVbenModal({
  async onConfirm() {
    const { valid } = await formApi.validate();
    if (valid) {
      if (items.length === 0) {
        message.warning('请至少添加一个入库明细');
        return;
      }
      const hasInvalidItem = items.some(
        (item) => !item.productId || item.quantity <= 0,
      );
      if (hasInvalidItem) {
        message.warning('请完善入库明细信息');
        return;
      }

      modalApi.lock();
      const data = await formApi.getValues();
      try {
        const submitData = {
          ...data,
          sourceId: data.sourceId || null,
          isTemporary: data.isTemporary || 0,
          items: items.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            location: item.location,
          })),
        };
        await (formData.value?.id
          ? updateInbound(formData.value.id, submitData)
          : createInbound(submitData));
        modalApi.close();
        emit('success');
      } finally {
        modalApi.lock(false);
      }
    }
  },
  onOpenChange(isOpen) {
    if (isOpen) {
      const data = modalApi.getData<InboundApi.Inbound>();
      if (data) {
        formData.value = data;
        formApi.setValues({
          orderNo: data.orderNo,
          sourceId: data.sourceId ? Number(data.sourceId) : undefined,
          isTemporary: data.isTemporary || 0,
          status: data.status || 'draft',
          remark: data.remark,
        });
        items.length = 0;
        if (data.items) {
          items.push(
            ...data.items.map((item) => ({
              productId: Number(item.productId),
              productName: item.productName || '',
              productCode: item.productCode || '',
              quantity: item.quantity,
              location: item.locationName || '',
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
        <span class="font-medium">入库明细</span>
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
              @change="(val: any) => onProductChange(val, index)"
            />
          </template>
          <template v-else-if="column.dataIndex === 'quantity'">
            <InputNumber
              v-model:value="record.quantity"
              :min="1"
              :precision="0"
              style="width: 100%"
            />
          </template>
          <template v-else-if="column.dataIndex === 'location'">
            <Input v-model:value="record.location" placeholder="库位" />
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
      <div class="mt-2 text-right">
        <span class="font-medium">合计数量：</span>
        <span class="text-lg text-blue-500">{{ totalQuantity }}</span>
      </div>
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
