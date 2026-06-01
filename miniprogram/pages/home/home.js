const pairingService = require('../../services/device_pairing.js');

Page({
  data: {
    deviceType: null,  // 'iphone' | 'ipad' | 'mac'
    showPairingModal: false,
    pairingQRCode: '',
  },

  onSelectDevice(e) {
    const type = e.currentTarget.dataset.type;
    this.setData({ deviceType: type });
    wx.navigateTo({ url: `/pages/guide/guide?type=${type}` });
  },

  onStartPairing() {
    // 生成配对二维码
    pairingService.generatePairingQRCode().then(qrContent => {
      this.setData({
        showPairingModal: true,
        pairingQRCode: qrContent,
      });
    });
  },

  onClosePairingModal() {
    this.setData({ showPairingModal: false });
  },
});