package com.hailiao.api.wukong;

/**
 * WuKongIM HTTP 调用结果占位（Phase 1）。
 */
public class WukongSendResult {

    private boolean success;
    private String detail;

    public static WukongSendResult skipped(String reason) {
        WukongSendResult r = new WukongSendResult();
        r.success = false;
        r.detail = reason;
        return r;
    }

    public static WukongSendResult ok(String detail) {
        WukongSendResult r = new WukongSendResult();
        r.success = true;
        r.detail = detail;
        return r;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getDetail() {
        return detail;
    }

    public void setDetail(String detail) {
        this.detail = detail;
    }
}
