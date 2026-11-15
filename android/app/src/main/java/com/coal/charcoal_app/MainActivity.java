package com.coal.charcoal_app;

import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.coal.charcoal_app/device_utils";
    private static final String PREFS_NAME = "charcoal_prefs";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                SharedPreferences prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
                switch (call.method) {
                    case "getPrefBool": {
                        String key = call.argument("key");
                        boolean defVal = Boolean.TRUE.equals(call.argument("defaultValue"));
                        result.success(prefs.getBoolean(key, defVal));
                        break;
                    }
                    case "setPrefBool": {
                        String key = call.argument("key");
                        boolean val = Boolean.TRUE.equals(call.argument("value"));
                        prefs.edit().putBoolean(key, val).apply();
                        result.success(true);
                        break;
                    }
                    case "getPrefString": {
                        String key = call.argument("key");
                        result.success(prefs.getString(key, ""));
                        break;
                    }
                    case "setPrefString": {
                        String key = call.argument("key");
                        String val = call.argument("value");
                        prefs.edit().putString(key, val != null ? val : "").apply();
                        result.success(true);
                        break;
                    }
                    case "saveImageToGallery": {
                        byte[] bytes = call.argument("bytes");
                        String fileName = call.argument("fileName");
                        if (bytes == null || bytes.length == 0) {
                            result.error("INVALID_BYTES", "Image bytes are empty.", null);
                            break;
                        }
                        if (fileName == null || fileName.trim().isEmpty()) {
                            fileName = "CharCoal_QR_" + System.currentTimeMillis() + ".jpg";
                        }
                        try {
                            String savedPath = saveQrImage(bytes, fileName);
                            result.success(savedPath);
                        } catch (Exception e) {
                            result.error("SAVE_FAILED", e.getMessage(), null);
                        }
                        break;
                    }
                    default:
                        result.notImplemented();
                }
            });
    }

    private String saveQrImage(byte[] bytes, String fileName) throws Exception {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
            values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/CharCoal");
            values.put(MediaStore.Images.Media.IS_PENDING, 1);

            Uri uri = getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                throw new Exception("Could not create MediaStore entry.");
            }
            try (OutputStream out = getContentResolver().openOutputStream(uri)) {
                if (out == null) {
                    throw new Exception("Could not open output stream.");
                }
                out.write(bytes);
                out.flush();
            }
            values.clear();
            values.put(MediaStore.Images.Media.IS_PENDING, 0);
            getContentResolver().update(uri, values, null, null);
            return "Pictures/CharCoal/" + fileName;
        } else {
            File dir = new File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "CharCoal"
            );
            if (!dir.exists() && !dir.mkdirs()) {
                throw new Exception("Could not create Pictures/CharCoal folder.");
            }
            File file = new File(dir, fileName);
            try (FileOutputStream fos = new FileOutputStream(file)) {
                fos.write(bytes);
                fos.flush();
            }
            return file.getAbsolutePath();
        }
    }
}
