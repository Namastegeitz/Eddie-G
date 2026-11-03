package com.eddieg.aliensudoku;

import android.os.Bundle;
import androidx.activity.EdgeToEdge;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        // Draw behind the status/navigation bars; the web layer pads itself
        // with the safe-area insets Capacitor provides (SystemBars insetsHandling = css).
        EdgeToEdge.enable(this);
        super.onCreate(savedInstanceState);
    }
}
