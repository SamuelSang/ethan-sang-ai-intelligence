const pairingService = require('../../services/device_pairing.js');

Page({
  data: {
    deviceType: '',
    currentStep: 0,
    inspectionItems: [
      // iPhone 26项检测项
      { id: 1, name: '屏幕划痕', category: '外观检查', status: 'pending' },
      { id: 2, name: '机身磕碰', category: '外观检查', status: 'pending' },
      { id: 3, name: '按键松动', category: '外观检查', status: 'pending' },
      { id: 4, name: '坏点检测', category: '屏幕检查', status: 'pending' },
      { id: 5, name: '亮点检测', category: '屏幕检查', status: 'pending' },
      { id: 6, name: '色准检测', category: '屏幕检查', status: 'pending' },
      { id: 7, name: '触摸响应', category: '屏幕检查', status: 'pending' },
      { id: 8, name: '电池健康度', category: '电池检查', status: 'pending' },
      { id: 9, name: '电池鼓包', category: '电池检查', status: 'pending' },
      { id: 10, name: '主摄对焦', category: '摄像头检查', status: 'pending' },
      { id: 11, name: '超广角', category: '摄像头检查', status: 'pending' },
      { id: 12, name: '闪光灯', category: '摄像头检查', status: 'pending' },
      { id: 13, name: '夜景模式', category: '摄像头检查', status: 'pending' },
      { id: 14, name: '录音检测', category: '麦克风检查', status: 'pending' },
      { id: 15, name: '听筒检测', category: '扬声器检查', status: 'pending' },
      { id: 16, name: '底部扬声器', category: '扬声器检查', status: 'pending' },
      { id: 17, name: 'Face ID/Touch ID', category: '传感器检查', status: 'pending' },
      { id: 18, name: 'GPS定位', category: '传感器检查', status: 'pending' },
      { id: 19, name: '陀螺仪', category: '传感器检查', status: 'pending' },
      { id: 20, name: '加速度计', category: '传感器检查', status: 'pending' },
      { id: 21, name: 'Wi-Fi', category: '网络连接', status: 'pending' },
      { id: 22, name: '蓝牙', category: '网络连接', status: 'pending' },
      { id: 23, name: '蜂窝网络', category: '网络连接', status: 'pending' },
      { id: 24, name: '充电接口', category: '充电接口', status: 'pending' },
      { id: 25, name: '序列号核对', category: '设备信息', status: 'pending' },
      { id: 26, name: 'IMEI核对', category: '设备信息', status: 'pending' },
    ],
    deviceInfoFromDesktop: null,
  },

  onLoad(options) {
    this.setData({ deviceType: options.type });

    // 监听电脑端回传的设备数据
    wx.eventCenter.on('deviceDataUpdated', (data) => {
      this.setData({ deviceInfoFromDesktop: data });
    });
  },

  onCheckItem(index, result) {
    const items = this.data.inspectionItems;
    items[index].status = result ? 'pass' : 'fail';
    this.setData({ inspectionItems: items });
  },

  onCompleteInspection() {
    const results = this.data.inspectionItems.map(item => ({
      id: item.id,
      status: item.status,
    }));

    const reportData = {
      deviceType: this.data.deviceType,
      manualChecks: results,
      hardwareData: this.data.deviceInfoFromDesktop,
      generatedAt: new Date().toISOString(),
    };

    wx.navigateTo({
      url: `/pages/report/report?data=${encodeURIComponent(JSON.stringify(reportData))}`,
    });
  },
});