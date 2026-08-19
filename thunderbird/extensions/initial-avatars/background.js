// 启动即注入；无网络、无存储权限需求。
(async () => {
  try {
    await messenger.avatarApi.start();
  } catch (e) {
    console.error("[Initial Avatars] start failed:", e);
  }
})();
