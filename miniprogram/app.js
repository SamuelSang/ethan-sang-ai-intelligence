App({
  globalData: {
    isPremium: false,
    passport: null,
    pairedDeviceData: null,
  },

  onLaunch() {
    // 检查通行证状态
    this.checkPassportStatus();
  },

  async checkPassportStatus() {
    const passport = wx.getStorageSync('passport');
    if (passport && passport.isValid) {
      this.globalData.isPremium = true;
      this.globalData.passport = passport;
    }
  },
});