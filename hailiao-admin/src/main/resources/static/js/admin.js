/**
 * 嗨聊后台管理系统 - 公共JavaScript工具库
 * @author 嗨聊开发团队
 * @version 1.0.0
 */

// ==================== 认证相关 ====================

/**
 * 获取存储的JWT Token
 * @returns {string|null} JWT Token或null
 */
function getToken() {
    return localStorage.getItem('adminToken');
}

/**
 * 检查用户是否已登录
 * 未登录则跳转到登录页面
 */
function checkAuth() {
    const token = getToken();
    if (!token) {
        window.location.href = '/login.html';
        return false;
    }
    return true;
}

/**
 * 退出登录
 * 清除Token并跳转到登录页面
 */
function logout() {
    localStorage.removeItem('adminToken');
    window.location.href = '/login.html';
}

// ==================== HTTP请求 ====================

/**
 * 发送带认证的GET请求
 * @param {string} url - 请求地址
 * @returns {Promise} 请求Promise
 */
function get(url) {
    return fetch(url, {
        headers: { 
            'Authorization': 'Bearer ' + getToken(),
            'Content-Type': 'application/json'
        }
    }).then(response => {
        if (response.status === 401 || response.status === 403) {
            logout();
            throw new Error('未授权');
        }
        return response.json();
    });
}

/**
 * 发送带认证的POST请求
 * @param {string} url - 请求地址
 * @param {object} data - 请求数据
 * @returns {Promise} 请求Promise
 */
function post(url, data = {}) {
    return fetch(url, {
        method: 'POST',
        headers: { 
            'Authorization': 'Bearer ' + getToken(),
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).then(response => {
        if (response.status === 401 || response.status === 403) {
            logout();
            throw new Error('未授权');
        }
        return response.json();
    });
}

/**
 * 发送带认证的PUT请求
 * @param {string} url - 请求地址
 * @param {object} data - 请求数据
 * @returns {Promise} 请求Promise
 */
function put(url, data = {}) {
    return fetch(url, {
        method: 'PUT',
        headers: { 
            'Authorization': 'Bearer ' + getToken(),
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).then(response => {
        if (response.status === 401 || response.status === 403) {
            logout();
            throw new Error('未授权');
        }
        return response.json();
    });
}

/**
 * 发送带认证的DELETE请求
 * @param {string} url - 请求地址
 * @returns {Promise} 请求Promise
 */
function del(url) {
    return fetch(url, {
        method: 'DELETE',
        headers: { 
            'Authorization': 'Bearer ' + getToken(),
            'Content-Type': 'application/json'
        }
    }).then(response => {
        if (response.status === 401 || response.status === 403) {
            logout();
            throw new Error('未授权');
        }
        return response.json();
    });
}

// ==================== 分页组件 ====================

/**
 * 分页管理类
 */
class Pagination {
    /**
     * 创建分页实例
     * @param {string} pageInfoId - 分页信息显示元素ID
     * @param {Function} loadCallback - 加载数据回调函数
     */
    constructor(pageInfoId, loadCallback) {
        this.currentPage = 0;
        this.totalPages = 1;
        this.pageInfoId = pageInfoId;
        this.loadCallback = loadCallback;
    }

    /**
     * 上一页
     */
    prev() {
        if (this.currentPage > 0) {
            this.currentPage--;
            this.loadCallback(this.currentPage);
        }
    }

    /**
     * 下一页
     */
    next() {
        if (this.currentPage < this.totalPages - 1) {
            this.currentPage++;
            this.loadCallback(this.currentPage);
        }
    }

    /**
     * 跳转到指定页
     * @param {number} page - 页码
     */
    goTo(page) {
        if (page >= 0 && page < this.totalPages) {
            this.currentPage = page;
            this.loadCallback(this.currentPage);
        }
    }

    /**
     * 更新分页信息
     * @param {number} totalPages - 总页数
     */
    update(totalPages) {
        this.totalPages = totalPages;
        document.getElementById(this.pageInfoId).textContent = 
            `第 ${this.currentPage + 1} 页 / 共 ${totalPages} 页`;
    }
}

// ==================== 表格组件 ====================

/**
 * 渲染表格数据
 * @param {string} tableId - 表格tbody元素ID
 * @param {Array} data - 表格数据
 * @param {Array} columns - 列配置
 * @param {Function} actionRenderer - 操作列渲染函数
 */
function renderTable(tableId, data, columns, actionRenderer) {
    const tbody = document.getElementById(tableId);
    tbody.innerHTML = data.map((row, index) => {
        let html = '<tr>';
        columns.forEach(col => {
            let value = row[col.field];
            if (col.formatter) {
                value = col.formatter(value, row);
            }
            html += `<td>${value}</td>`;
        });
        if (actionRenderer) {
            html += `<td class="action-btns">${actionRenderer(row)}</td>`;
        }
        html += '</tr>';
        return html;
    }).join('');
}

// ==================== 弹窗组件 ====================

/**
 * 显示Modal弹窗
 * @param {string} modalId - 弹窗元素ID
 */
function showModal(modalId) {
    document.getElementById(modalId).style.display = 'flex';
}

/**
 * 关闭Modal弹窗
 * @param {string} modalId - 弹窗元素ID
 */
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

// ==================== 消息提示 ====================

/**
 * 显示成功消息
 * @param {string} message - 消息内容
 */
function showSuccess(message) {
    alert(message); // 可以替换为更优雅的提示组件
}

/**
 * 显示错误消息
 * @param {string} message - 消息内容
 */
function showError(message) {
    alert(message); // 可以替换为更优雅的提示组件
}

/**
 * 显示确认对话框
 * @param {string} message - 确认消息
 * @returns {boolean} 用户是否确认
 */
function confirmAction(message) {
    return confirm(message);
}

// ==================== 工具函数 ====================

/**
 * 格式化日期时间
 * @param {string|Date} date - 日期
 * @returns {string} 格式化后的日期字符串
 */
function formatDate(date) {
    if (!date) return '-';
    return new Date(date).toLocaleString('zh-CN');
}

/**
 * 格式化金额
 * @param {number} amount - 金额
 * @returns {string} 格式化后的金额字符串
 */
function formatMoney(amount) {
    return '¥' + (amount || 0).toFixed(2);
}

/**
 * 获取状态标签HTML
 * @param {number} status - 状态码
 * @param {object} statusMap - 状态映射配置
 * @returns {string} 状态标签HTML
 */
function getStatusBadge(status, statusMap) {
    const config = statusMap[status] || { text: '未知', class: 'secondary' };
    return `<span class="status status-${config.class}">${config.text}</span>`;
}

// ==================== 表单验证 ====================

/**
 * 验证手机号
 * @param {string} phone - 手机号
 * @returns {boolean} 是否有效
 */
function isValidPhone(phone) {
    return /^1[3-9]\d{9}$/.test(phone);
}

/**
 * 验证邮箱
 * @param {string} email - 邮箱
 * @returns {boolean} 是否有效
 */
function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/**
 * 验证必填字段
 * @param {string} value - 字段值
 * @returns {boolean} 是否有效
 */
function isRequired(value) {
    return value && value.trim().length > 0;
}

// ==================== 初始化 ====================

/**
 * 页面初始化
 * 检查登录状态并设置全局事件
 */
document.addEventListener('DOMContentLoaded', function() {
    // 非登录页面检查认证
    if (!window.location.pathname.includes('login.html')) {
        checkAuth();
    }
});
