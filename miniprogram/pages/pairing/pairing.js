const pairingService = require('../../services/device_pairing.js');

Page({
  data: {
    isScanning: false,
    scanResult: null,
  },

  onScanQRCode() {
    wx.scanCode({
      success: async (res) => {
        this.setData({ isScanning: true });
        const result = await pairingService.scanDesktopQRCode(res.result);
        this.setData({ isScanning: false, scanResult: result });
      },
      fail: (err) => {
        wx.showToast({ title: '扫码失败', icon: 'none' });
      }
    });
  },

  onConfirmPairing() {
    // 获取UnionID并确认配对
    const unionId = wx.getStorageSync('unionId');
    pairingService.confirmPairing(unionId).then(result => {
      if (result.success) {
        wx.showToast({ title: '配对成功' });
        wx.navigateBack();
      } else {
        wx.showToast({ title: '配对失败', icon: 'none' });
      }
    });
  },
});