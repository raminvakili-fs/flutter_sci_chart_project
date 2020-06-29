package com.example.flutterscichartproject.sci.views;

import android.content.Context;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

public class Marker extends LinearLayout {

    private TextView textView;

    public Marker(Context context) {
        super(context);
        setOrientation(VERTICAL);
        setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT));

        textView = new TextView(context);
        textView.setTextColor(0xFFFFFFFF);
        addView(textView);

        ImageView icon = new ImageView(context);
        icon.setImageResource(android.R.drawable.ic_dialog_alert);
        icon.setLayoutParams(new LinearLayout.LayoutParams(30, 30));
        addView(icon);

    }

    public void setText(String text) {
        textView.setText(text);
    }

}
