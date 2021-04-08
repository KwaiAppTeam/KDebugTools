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

package com.kwai.flutter.debugtools.screen;

import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.media.Image;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.MethodChannel;

/**
 * 将bitmap编码后发送给flutter
 */
public class ScreenPreviewSender implements ScreenCaptureService.IScreenDataReceiver {
    private static final String TAG = "ScreenPreviewSender";
    //最小帧率
    private static final int MIN_FPS = 2;
    //最大帧率
    private static final int MAX_FPS = 10;
    //最大延迟控制 超出丢弃
    private static final long MAX_DELAY = 300;
    //队列应该的最大长度
    private static final long MAX_QUEUE_SIZE = Math.round(1.0 * MAX_DELAY / 1000 * MAX_FPS);
    private MethodChannel channel;
    private BlockingQueue<FrameInfo> mFrameQueue;
    private Handler mainHandler = new Handler(Looper.getMainLooper());
    private AtomicBoolean mQuit = new AtomicBoolean(false);
    private FpsHelper mInputFps = new FpsHelper("SenderInput");
    private FpsHelper mSendFps = new FpsHelper("SenderOutput");
    private long preAcceptFrameTs = 0;
    private Bitmap lastJpg = null;
    private final byte[] lastJpgLock = new byte[0];

    public ScreenPreviewSender(MethodChannel channel) {
        this.channel = channel;
        mFrameQueue = new LinkedBlockingQueue<>();
    }

    /**
     * 开始处理
     */
    public final void start() {
        mQuit.set(false);
        new Thread() {
            @Override
            public void run() {
                try {
                    while (!mQuit.get()) {
                        FrameInfo frameInfo = null;
                        try {
                            frameInfo = mFrameQueue.poll(1, TimeUnit.SECONDS);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        if (!mQuit.get() && frameInfo != null) {
                            long delay = System.currentTimeMillis() - frameInfo.frameTs;
                            //最大延迟控制
                            if (MAX_DELAY < delay && !mFrameQueue.isEmpty()) {
                                //Log.w(TAG, "drop " + delay + " > MAX_DELAY");
                                frameInfo.bitmap.recycle();
                                continue;
                            }
                            //Log.d(TAG, "compressFrame, frame delay: " + delay);
                            JpgFrameData jpgFrameData = compressFrame(frameInfo);
                            sendPreviewDataToFlutter(jpgFrameData);
                            synchronized (lastJpgLock) {
                                if (lastJpg != null) {
                                    lastJpg.recycle();
                                }
                                lastJpg = frameInfo.bitmap;
                            }
                        }
                    }
                    //销毁最后一张
                    synchronized (lastJpgLock) {
                        if (lastJpg != null) {
                            lastJpg.recycle();
                            lastJpg = null;
                        }
                    }
                } finally {
                    mQuit.set(true);
                }
            }
        }.start();
    }

    public final void quit() {
        mQuit.set(true);
    }

    public boolean isRunning() {
        return !mQuit.get();
    }

    /**
     * 最后一张jpg图像
     *
     * @return
     */
    public Bitmap getLastFineJpg() {
        Bitmap result = null;
        synchronized (lastJpgLock) {
            if (lastJpg != null) {
                Matrix matrix = new Matrix();
                matrix.setScale(0.8f, 0.8f);
                //和之前压缩一样进行 缩放 但不压缩
                result = Bitmap.createBitmap(lastJpg, 0, 0, lastJpg.getWidth(), lastJpg.getHeight(), matrix, true);
            }
        }
        return result;
    }

    private JpgFrameData compressFrame(@NonNull FrameInfo frameInfo) {
        long start = SystemClock.uptimeMillis();
        Bitmap bitmap = frameInfo.bitmap;
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        Matrix matrix = new Matrix();
        matrix.setScale(0.8f, 0.8f);
        //缩放
        bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
        //todo 动态控制质量
//        int quality = (int) (1 - Math.min(1, 1.0 * mInputFps.getFps() / MAX_FPS)) * (MAX_FPS - MIN_FPS) + MIN_FPS;
        int quality = 30;
//        Log.d(TAG, "fps: "+mInputFps.getFps()+", quality: " + quality);
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, byteArrayOutputStream);

        byte[] b = byteArrayOutputStream.toByteArray();
        try {
            byteArrayOutputStream.flush();
            byteArrayOutputStream.close();
        } catch (IOException e) {
            Log.e(TAG, "close error", e);
        } finally {
            bitmap.recycle();
        }
        //Log.d(TAG, "encode cost " + (SystemClock.uptimeMillis() - start));
        return new JpgFrameData(frameInfo.frameTs, b);
    }

    private void sendPreviewDataToFlutter(JpgFrameData frameData) {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                mSendFps.addFrame();
                mSendFps.print();
                //Log.d(TAG, "sendFrame, delay: " + (System.currentTimeMillis() - frameData.ts) + "queue: " + mFrameQueue.size());
                Map<String, Object> map = new HashMap<>();
                //input time
                map.put("ts", frameData.ts);
                //send time
                map.put("sendts", System.currentTimeMillis());
                map.put("data", frameData.jpgData);
                channel.invokeMethod("onPreviewData", map);
            }
        });
    }

    @Override
    public void onImageAvailable(long ts, Image image) {
        //ignore
    }

    @Override
    public void onRawBitmap(long ts, int imgWidth, int imgHeight, Bitmap rawBitmap) {
        //ignore
    }

    @Override
    public void onCompressedBitmap(long ts, Bitmap bitmap) {
        long frame = SystemClock.uptimeMillis() - preAcceptFrameTs;
        if (frame < (1000.0 / MAX_FPS)) {
            //Log.w(TAG, "drop frame, ts: " + frame);
            return;
        }
        preAcceptFrameTs = SystemClock.uptimeMillis();
        mInputFps.addFrame();
        mInputFps.print();
        mFrameQueue.offer(new FrameInfo(ts, bitmap.copy(Bitmap.Config.ARGB_8888, true)));
    }


    static class JpgFrameData {
        long ts;
        byte[] jpgData;

        JpgFrameData(long ts, byte[] jpgData) {
            this.ts = ts;
            this.jpgData = jpgData;
        }
    }
}

