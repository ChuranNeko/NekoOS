package com.neko.settings;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

/**
 * Neko 设置主界面，展示模板内容并预留扩展点。
 */
public class NekoSettingsActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main); // 加载基础布局
        initUi();
    }

    private void initUi() {
        TextView summary = findViewById(R.id.summary); // 获取提示文本控件
        summary.append("

- 欢迎扩展 NekoOS 功能，例如调试开关或主题控制。");
        // TODO: add more overlays or prebuilt apps here
    }
}
