const PAIRING_API_BASE = 'https://api.example.com';

class PairingService {
  constructor() {
    this.currentToken = null;
    this.pairingState = 'idle'; // idle, scanning, confirmed, failed
  }

  // 扫描电脑端二维码
  async scanDesktopQRCode(qrContent) {
    try {
      const data = JSON.parse(qrContent);

      if (data.action !== 'pair') {
        throw new Error('无效的二维码');
      }

      this.currentToken = data.token;

      // 调用后端验证token
      const response = await wx.request({
        url: `${PAIRING_API_BASE}/pairing/scan`,
        method: 'POST',
        data: {
          token: this.currentToken,
          desktopId: data.desktopId,
        },
      });

      if (response.statusCode === 200) {
        this.pairingState = 'scanning';
        return { success: true, desktopId: data.desktopId };
      } else {
        throw new Error('配对失败');
      }
    } catch (e) {
      this.pairingState = 'failed';
      return { success: false, error: e.message };
    }
  }

  // 确认配对授权
  async confirmPairing(unionId) {
    if (!this.currentToken) {
      return { success: false, error: '无有效token' };
    }

    try {
      const response = await wx.request({
        url: `${PAIRING_API_BASE}/pairing/confirm`,
        method: 'POST',
        data: {
          token: this.currentToken,
          unionId: unionId,
        },
      });

      if (response.statusCode === 200) {
        this.pairingState = 'confirmed';
        return { success: true };
      } else {
        this.pairingState = 'failed';
        return { success: false };
      }
    } catch (e) {
      this.pairingState = 'failed';
      return { success: false, error: e.message };
    }
  }

  // 接收电脑端回传的设备数据
  async receiveDeviceData(deviceData) {
    // 存储设备数据到本地
    wx.setStorageSync('pairedDeviceData', deviceData);

    // 触发页面更新
    wx.eventCenter.trigger('deviceDataUpdated', deviceData);

    return { success: true };
  }
}

module.exports = new PairingService();