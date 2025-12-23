import { computed } from 'vue';

import { useAccessStore, useUserStore } from '@vben/stores';

/**
 * 权限控制Hook
 * 用于检查当前用户是否拥有指定的权限码或角色
 */
export function usePermission() {
  const accessStore = useAccessStore();
  const userStore = useUserStore();

  // 当前用户的权限码列表
  const accessCodes = computed(() => accessStore.accessCodes || []);

  // 当前用户的角色列表
  const userRoles = computed(() => userStore.userRoles || []);

  // 当前用户的角色（第一个）
  const currentRole = computed(() => userRoles.value[0] || '');

  /**
   * 检查是否拥有指定的权限码
   * @param codes 权限码列表，满足其中一个即可
   */
  function hasPermission(codes: string | string[]): boolean {
    const codeList = Array.isArray(codes) ? codes : [codes];
    return codeList.some((code) => accessCodes.value.includes(code));
  }

  /**
   * 检查是否拥有指定的角色
   * @param roles 角色列表，满足其中一个即可
   */
  function hasRole(roles: string | string[]): boolean {
    const roleList = Array.isArray(roles) ? roles : [roles];
    return roleList.some((role) => userRoles.value.includes(role));
  }

  /**
   * 检查是否是管理员
   */
  function isAdmin(): boolean {
    return hasRole('ADMIN');
  }

  /**
   * 检查是否是采购专员
   */
  function isBuyer(): boolean {
    return hasRole('BUYER');
  }

  /**
   * 检查是否是仓库管理员
   */
  function isWarehouseManager(): boolean {
    return hasRole('W_MGR');
  }

  /**
   * 检查是否是普通员工
   */
  function isStaff(): boolean {
    return hasRole('STAFF');
  }

  // ============ 具体业务权限判断 ============

  // 产品管理权限
  const canViewProduct = computed(() => hasPermission('PRODUCT_VIEW'));
  const canCreateProduct = computed(() => hasPermission('PRODUCT_CREATE'));
  const canEditProduct = computed(() => hasPermission('PRODUCT_EDIT'));
  const canDeleteProduct = computed(() => hasPermission('PRODUCT_DELETE'));

  // 采购管理权限
  const canViewProcurement = computed(() => hasPermission('PROCUREMENT_VIEW'));
  const canCreateProcurement = computed(() =>
    hasPermission('PROCUREMENT_CREATE'),
  );
  const canApproveProcurement = computed(() =>
    hasPermission('PROCUREMENT_APPROVE'),
  );
  const canOrderProcurement = computed(() =>
    hasPermission('PROCUREMENT_ORDER'),
  );

  // 入库管理权限
  const canViewInbound = computed(() => hasPermission('INBOUND_VIEW'));
  const canCreateInbound = computed(() => hasPermission('INBOUND_CREATE'));
  const canApproveInbound = computed(() => hasPermission('INBOUND_APPROVE'));

  // 出库管理权限
  const canViewOutbound = computed(() => hasPermission('OUTBOUND_VIEW'));
  const canCreateOutbound = computed(() => hasPermission('OUTBOUND_CREATE'));
  const canApproveOutbound = computed(() => hasPermission('OUTBOUND_APPROVE'));
  const canExecuteOutbound = computed(() => hasPermission('OUTBOUND_EXECUTE'));

  // 库存管理权限
  const canViewInventory = computed(() => hasPermission('INVENTORY_VIEW'));
  const canCheckInventory = computed(() => hasPermission('INVENTORY_CHECK'));
  const canAdjustInventory = computed(() => hasPermission('INVENTORY_ADJUST'));

  return {
    // 基础方法
    accessCodes,
    userRoles,
    currentRole,
    hasPermission,
    hasRole,
    isAdmin,
    isBuyer,
    isWarehouseManager,
    isStaff,

    // 产品权限
    canViewProduct,
    canCreateProduct,
    canEditProduct,
    canDeleteProduct,

    // 采购权限
    canViewProcurement,
    canCreateProcurement,
    canApproveProcurement,
    canOrderProcurement,

    // 入库权限
    canViewInbound,
    canCreateInbound,
    canApproveInbound,

    // 出库权限
    canViewOutbound,
    canCreateOutbound,
    canApproveOutbound,
    canExecuteOutbound,

    // 库存权限
    canViewInventory,
    canCheckInventory,
    canAdjustInventory,
  };
}

