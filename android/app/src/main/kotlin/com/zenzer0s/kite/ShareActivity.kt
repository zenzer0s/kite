package com.zenzer0s.kite

class ShareActivity : MainActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        intent.putExtra("background_mode", "transparent")
        super.onCreate(savedInstanceState)
    }

    override fun getInitialRoute(): String {
        return "/share_handler"
    }

    override fun onResume() {
        super.onResume()
        window.clearFlags(
            android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        )
    }
}
