<script lang="ts" setup>
import type { ProcurementApi } from '#/api/wms/procurement';

import { computed, onMounted, reactive, ref } from 'vue';

import { useVbenModal } from '@vben/common-ui';

import {
  Button,
  InputNumber,
  message,
  Select,
  Space,
  Table,
} from 'ant-design-vue';

import { useVbenForm } from '#/adapter/form';
import { createProcurement, updateProcurement } from '#/api/wms/procurement';
import { $t } from '#/locales';

import { getProductOptions, useSchema } from '../data';

interface ProcurementItem {
  productId: number | null;
  productName: string;
  productCode: string;
  quantity: number;
  price: number;
  amount: number;
}

const emit = defineEmits(['success']);
const formData = ref<ProcurementApi.Procurement>();
const items = reactive<ProcurementItem[]>([]);
const productOptions = ref<any[]>([]);

const getTitle = computed(() => {
  return formData.value?.id
    ? $t('ui.actionTitle.edit', [$t('wms.procurement.title')])
    : $t('ui.actionTitle.create', [$t('wms.procurement.title')]);
});

const [Form, formApi] = useVbenForm({
  layout: 'vertical',
  schema: useSchema(),
  showDefaultActions: false,
});

// 计算总金额
const totalAmount = computed(() => {
  return items.reduce((sum, item) => sum + (item.amount || 0), 0);
});

// 添加明细行
function addItem() {
  items.push({
    productId: null,
    productName: '',
    productCode: '',
    quantity: 1,
    price: 0,
    amount: 0,
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
  }
}

// 数量或价格变更时重新计算金额
function calculateAmount(index: number) {
  const item = items[index];
  item.amount = (item.quantity || 0) * (item.price || 0);
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
        price: item.price,
        amount: item.amount,
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
    title: '单价',
    dataIndex: 'price',
    width: 100,
  },
  {
    title: '金额',
    dataIndex: 'amount',
    width: 100,
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
        message.warning('请至少添加一个采购明细');
        return;
      }
      const hasInvalidItem = items.some(
        (item) => !item.productId || item.quantity <= 0,
      );
      if (hasInvalidItem) {
        message.warning('请完善采购明细信息');
        return;
      }

      modalApi.lock();
      const data = await formApi.getValues();
      try {
        const submitData = {
          ...data,
          items: items.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            price: item.price,
          })),
        };
        await (formData.value?.id
          ? updateProcurement(formData.value.id, submitData)
          : createProcurement(submitData));
        modalApi.close();
        emit('success');
      } finally {
        modalApi.lock(false);
      }
    }
  },
  onOpenChange(isOpen) {
    if (isOpen) {
      const data = modalApi.getData<ProcurementApi.Procurement>();
      if (data) {
        formData.value = data;
        formApi.setValues({
          orderNo: data.orderNo,
          supplierId: data.supplierId ? Number(data.supplierId) : undefined,
          expectedDate: data.expectedDate,
          reason: (data as any).reason,
          status: data.status || 'PENDING',
        });
        items.length = 0;
        if (data.items) {
          items.push(
            ...data.items.map((item) => ({
              productId: Number(item.productId),
              productName: item.productName || '',
              productCode: item.productCode || '',
              quantity: item.quantity,
              price: item.price,
              amount: item.amount,
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
  <Modal :title="getTitle" class="w-[800px]">
    <Form class="mx-4" />
    <div class="mx-4 mb-4">
      <div class="mb-2 flex items-center justify-between">
        <span class="font-medium">采购明细</span>
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
          <template v-else-if="column.dataIndex === 'quantity'">
            <InputNumber
              v-model:value="record.quantity"
              :min="1"
              :precision="0"
              style="width: 100%"
              @change="calculateAmount(index)"
            />
          </template>
          <template v-else-if="column.dataIndex === 'price'">
            <InputNumber
              v-model:value="record.price"
              :min="0"
              :precision="2"
              style="width: 100%"
              @change="calculateAmount(index)"
            />
          </template>
          <template v-else-if="column.dataIndex === 'amount'">
            ¥{{ (record.amount || 0).toFixed(2) }}
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
        <span class="font-medium">合计金额：</span>
        <span class="text-lg text-red-500">¥{{ totalAmount.toFixed(2) }}</span>
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
