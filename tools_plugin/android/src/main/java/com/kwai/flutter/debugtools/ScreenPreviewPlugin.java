/*
 * Copyright 2021 Kwai, Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.kwai.flutter.debugtools;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.util.DisplayMetrics;
import android.util.Log;
import android.graphics.Point;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import com.kwai.flutter.debugtools.screen.ScreenCaptureService;
import com.kwai.flutter.debugtools.screen.ScreenPreviewRecorder;
import com.kwai.flutter.debugtools.screen.ScreenPreviewSender;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry;

public class ScreenPreviewPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {
    private static final String TAG = "ScreenPreviewPlugin";
    private Context context;
    private MethodChannel channel;
    private Activity activity;
    private MethodChannel.Result _startCallResult;
    //录制宽度, 高度会按比例计算
    private int mRecordWidth = 720;
    private int mRecordHeight = 0;
    private int mDensityDpi = 0;
    private String fileAbsolutePath = "";

    private ScreenCaptureService mScreenCaptureService;
    private int SCREEN_PREVIEW_REQUEST_CODE = 666;
    private ScreenPreviewRecorder mVideoRecorder;
    private ScreenPreviewSender mPreviewSender;

    public ScreenPreviewPlugin() {
    }

    public static void registerWith(Registrar registrar) {
        ScreenPreviewPlugin instance = new ScreenPreviewPlugin();
        instance.channel = new MethodChannel(registrar.messenger(), "kdebugtools/screen_preview");
        instance.context = registrar.context();
        instance.channel.setMethodCallHandler(instance);
        instance.activity = registrar.activity();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "kdebugtools/screen_preview");
        context = binding.getApplicationContext();
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
//        Log.d(TAG, "onMethodCall: " + call.method);
        switch (call.method) {
            case "state":
                boolean isServiceRunning = mScreenCaptureService != null;
                boolean recording = mVideoRecorder != null && mVideoRecorder.isEncodingStarted();
                boolean previewing = mPreviewSender != null && mPreviewSender.isRunning();
                Map<String, Object> data = new HashMap<>();
                data.put("recording", recording);
                data.put("previewing", previewing);
                callResult(result, 0, "success", data);
                break;
            case "startPreview":
                _startCallResult = result;
                startPreview();
                break;
            case "stopPreview":
                stopPreview(result);
                break;
            case "startRecordToFile":
                startRecordToFile(call, result);
                break;
            case "stopRecordToFile":
                stopRecordToFile(result);
                break;
            case "takeCapture":
                takeCapture(call, result);
                break;
            case "lastPreviewJpg":
                lastPreviewJpg(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == SCREEN_PREVIEW_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d(TAG, "permission granted");
                MediaProjectionManager projectionManager = (MediaProjectionManager) context.getSystemService(Context.MEDIA_PROJECTION_SERVICE);
                MediaProjection projection = projectionManager.getMediaProjection(resultCode, data);
                try {
                    startPreviewService(projection);
                    callResult(_startCallResult, 0, "success", null);
                    _startCallResult = null;
                } catch (Exception e) {
                    callResult(_startCallResult, -1, "start failed: " + e.getMessage(), null);
                    _startCallResult = null;
                }
                return true;
            } else {
                Log.d(TAG, "permission denied");
                callResult(_startCallResult, -1, "permission denied", null);
                _startCallResult = null;
            }
        }
        return false;
    }

    /**
     * 回调结果
     *
     * @param code       code
     * @param msg        message
     * @param resultData data
     */
    private void callResult(MethodChannel.Result result, int code, String msg, Map resultData) {
        if (result != null) {
            Map<String, Object> map = new HashMap<>();
            map.put("ts", System.currentTimeMillis());
            map.put("code", code);
            map.put("msg", msg);
            map.put("data", resultData);
            result.success(map);
        }
    }

    /**
     * 计算分辨率
     */
    private void calcResolution() {
        WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        DisplayMetrics metrics = new DisplayMetrics();
        windowManager.getDefaultDisplay().getMetrics(metrics);
        Point screenSize = new Point();
        windowManager.getDefaultDisplay().getRealSize(screenSize);
        double screenRatio = (screenSize.x * 1.0 / screenSize.y);
        mRecordHeight = (int) (mRecordWidth / screenRatio);
        mDensityDpi = metrics.densityDpi;
        Log.d(TAG, "params: sX:" + screenSize.x + ", sY:" + screenSize.y + " >>> dW:" + mRecordWidth + ", dH:" + mRecordHeight + ", densityDpi:" + mDensityDpi + ", ratio:" + screenRatio);

    }

    /**
     * 启动预览服务
     *
     * @param projection MediaProjection
     */
    private void startPreviewService(final MediaProjection projection) {
        if (mScreenCaptureService != null && mScreenCaptureService.isRunning()) {
//            throw new IllegalStateException("ScreenPreviewService is running");
            Log.w(TAG, "ScreenPreviewService is running");
            return;
        }
        calcResolution();

        mPreviewSender = new ScreenPreviewSender(channel);

        mScreenCaptureService = new ScreenCaptureService(mRecordWidth, mRecordHeight, mDensityDpi, projection);
        mScreenCaptureService.setStateCallback(new ScreenCaptureService.IStateCallback() {
            @Override
            public void onRelease() {
                if (mVideoRecorder != null) {
                    mVideoRecorder.stopEncoding();
                    mVideoRecorder = null;
                }
                if (mPreviewSender != null) {
                    mPreviewSender.quit();
                    mPreviewSender = null;
                }
            }
        });
        mScreenCaptureService.addScreenDataReceiver(mPreviewSender);
        mScreenCaptureService.start(activity);
        mPreviewSender.start();
    }


    /**
     * 开始预览
     */
    private void startPreview() {
        Log.d(TAG, "startPreview...");
        if (mScreenCaptureService != null && mScreenCaptureService.isRunning()) {
            callResult(_startCallResult, 0, "start failed, already started", null);
            _startCallResult = null;
            return;
        }
        requestPermission(SCREEN_PREVIEW_REQUEST_CODE);
    }

    /**
     * 停止预览
     */
    private void stopPreview(Result result) {
        Log.d(TAG, "stopPreview...");
        if (mScreenCaptureService != null && mScreenCaptureService.isRunning()) {
            mScreenCaptureService.quit();
            callResult(result, 0, "success", null);
        } else {
            callResult(result, -1, "stop failed: not previewing", null);
        }
        mScreenCaptureService = null;
    }

    /**
     * 返回最后一张preview的jpg
     */
    private void lastPreviewJpg(MethodCall call, Result result) {
        if (mPreviewSender == null || !mPreviewSender.isRunning()) {
            callResult(result, -1, "preview not started", null);
            return;
        }
        if (mPreviewSender.getLastFineJpg() == null) {
            callResult(result, -1, "last jpg not exist", null);
            return;
        }
        //直接返回bytes
        Bitmap bmp = mPreviewSender.getLastFineJpg();
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bmp.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
        byte[] b = byteArrayOutputStream.toByteArray();
        try {
            byteArrayOutputStream.flush();
            byteArrayOutputStream.close();
        } catch (IOException e) {
            Log.e(TAG, "close error", e);
        } finally {
            bmp.recycle();
        }
        result.success(b);
    }

    /**
     * 截屏到 png
     */
    private void takeCapture(MethodCall call, Result result) {
        Log.d(TAG, "takeCapture...");
        if (mScreenCaptureService == null || !mScreenCaptureService.isRunning()) {
            callResult(result, -1, "take capture failed, service not started", null);
            return;
        }
        try {
            fileAbsolutePath = call.argument("fileAbsolutePath");
            if (fileAbsolutePath == null) {
                throw new IllegalArgumentException("fileAbsolutePath not specified");
            }
            File f = new File(fileAbsolutePath);
            if (f.exists()) {
                throw new IOException("file: " + fileAbsolutePath + " exist");
            }
            f.getParentFile().mkdirs();
            if (!f.createNewFile()) {
                throw new IOException("can not write file: " + fileAbsolutePath);
            }
            Bitmap b = mScreenCaptureService.getLastCompressedBitmap();
            if (b == null) {
                throw new IOException("last bitmap not exist");
            }
            //保存为文件
            FileOutputStream fos = null;
            try {
                fos = new FileOutputStream(f);
                b.compress(Bitmap.CompressFormat.PNG, 100, fos);
            } catch (IOException e) {
                throw e;
            } finally {
                b.recycle();
                if (fos != null) {
                    fos.close();
                }
            }
            //返回路径
            Map<String, String> data = new HashMap<>();
            data.put("path", f.getAbsolutePath());
            callResult(result, 0, "success", data);
        } catch (Exception e) {
            Log.e(TAG, "take capture failed", e);
            callResult(result, -1, "take capture: " + e.getMessage(), null);
        }
    }

    /**
     * 开始录制到文件
     *
     * @param call 请求参数
     */
    private void startRecordToFile(MethodCall call, Result result) {
        Log.d(TAG, "startRecordToFile...");
        if (mVideoRecorder != null && mVideoRecorder.isEncodingStarted()) {
            callResult(result, -1, "start failed, already started", null);
            return;
        }
        try {
            if (mScreenCaptureService == null || !mScreenCaptureService.isRunning()) {
                throw new IllegalStateException("service not started");
            }
            fileAbsolutePath = call.argument("fileAbsolutePath");
            if (fileAbsolutePath == null) {
                throw new IllegalArgumentException("fileAbsolutePath not specified");
            }
            File f = new File(fileAbsolutePath);
            if (f.exists()) {
                throw new IOException("file: " + fileAbsolutePath + " exist");
            }
            f.getParentFile().mkdirs();
            if (!f.createNewFile()) {
                throw new IOException("can not write file: " + fileAbsolutePath);
            }
            mVideoRecorder = new ScreenPreviewRecorder(mRecordWidth, mRecordHeight, new ScreenPreviewRecorder.ICompleteCallback() {
                @Override
                public void onComplete(File outputFile) {
                    Log.d(TAG, "Recorder complete: " + outputFile.getAbsolutePath());
                }
            });
            mScreenCaptureService.addScreenDataReceiver(mVideoRecorder);
            mVideoRecorder.setOutputFile(f);
            //start
            mVideoRecorder.startEncoding();
            Map<String, String> data = new HashMap<>();
            data.put("path", f.getAbsolutePath());
            callResult(result, 0, "success", data);
        } catch (Exception e) {
            Log.e(TAG, "startRecordToFile failed", e);
            callResult(result, -1, "start failed: " + e.getMessage(), null);
        }
    }

    /**
     * 停止录制到文件
     */
    private void stopRecordToFile(Result result) {
        Log.d(TAG, "stopRecordToFile...");
        if (mVideoRecorder != null && mVideoRecorder.isEncodingStarted()) {
            mScreenCaptureService.removeScreenDataReceiver(mVideoRecorder);
            mVideoRecorder.stopEncoding();
            Map<String, String> data = new HashMap<>();
            data.put("path", mVideoRecorder.getOutputFile().getAbsolutePath());
            mVideoRecorder = null;
            callResult(result, 0, "success", data);
        } else {
            callResult(result, -1, "stop failed: not recording", null);
        }
    }

    /**
     * 请求权限
     */
    private void requestPermission(int requestCode) {
        Log.d(TAG, "request ScreenCapturePermission...");
        MediaProjectionManager projectionManager = (MediaProjectionManager) context.getSystemService(Context.MEDIA_PROJECTION_SERVICE);
        Intent permissionIntent = projectionManager.createScreenCaptureIntent();
        ActivityCompat.startActivityForResult(activity, permissionIntent, requestCode, null);
    }

}

