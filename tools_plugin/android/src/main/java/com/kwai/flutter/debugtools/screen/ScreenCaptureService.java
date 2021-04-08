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

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.Image;
import android.media.ImageReader;
import android.media.projection.MediaProjection;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;
import android.view.Surface;


import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * 屏幕图像抓取
 */
public class ScreenCaptureService {
    private static final String TAG = "ScreenCaptureService";
    private int mWidth;
    private int mHeight;
    private int mDpi;
    private MediaProjection mMediaProjection;
    private Surface mSurface;
    private VirtualDisplay mVirtualDisplay;

    private ImageReader mImageReader;
    private HandlerThread mImageThread;
    private final List<IScreenDataReceiver> mScreenDataReceivers = new ArrayList<>();
    private IStateCallback mStateCallback;
    private FpsHelper mFpsHelper;
    private Bitmap mLastCompressedBitmap;

    public ScreenCaptureService(int width, int height, int dpi, MediaProjection mp) {
        mWidth = width;
        mHeight = height;
        mDpi = dpi;
        mMediaProjection = mp;
        mFpsHelper = new FpsHelper("ImageInput");
    }

    public void addScreenDataReceiver(IScreenDataReceiver receiver) {
        if (!mScreenDataReceivers.contains(receiver)) {
            mScreenDataReceivers.add(receiver);
        }
    }

    public void removeScreenDataReceiver(IScreenDataReceiver receiver) {
        mScreenDataReceivers.remove(receiver);
    }

    public void setStateCallback(IStateCallback callback) {
        mStateCallback = callback;
    }

    public final void quit() {
        release();
    }

    public final boolean isRunning() {
        return mImageThread != null && mImageThread.isAlive();
    }

    public Bitmap getLastCompressedBitmap() {
        if (mLastCompressedBitmap != null) {
            return mLastCompressedBitmap.copy(Bitmap.Config.ARGB_8888, true);
        }
        return null;
    }

    public void start(Context context) {
        //todo 需要一个前台service保活,但是需要引入权限android.Manifest.permission.FOREGROUND_SERVICE,考虑考虑
        new Thread() {
            @Override
            public void run() {
                mImageReader = ImageReader.newInstance(mWidth, mHeight, PixelFormat.RGBA_8888, 2);
                mSurface = mImageReader.getSurface();
                mImageThread = new HandlerThread(TAG + "-handler");
                mImageThread.start();
                Handler handler = new Handler(mImageThread.getLooper());
                mVirtualDisplay = mMediaProjection.createVirtualDisplay(TAG + "-display", mWidth, mHeight, mDpi,
                        DisplayManager.VIRTUAL_DISPLAY_FLAG_PUBLIC, mSurface, null, handler);
                Log.d(TAG, "created virtual display: " + mVirtualDisplay);
                mImageReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
                    @Override
                    public void onImageAvailable(ImageReader imageReader) {
                        try {
                            //获取最新图
                            Image img = imageReader.acquireLatestImage();
                            if (img != null) {
//                        Log.d(TAG, "onImageAvailable");
                                mFpsHelper.addFrame();
                                long ts = System.currentTimeMillis();
                                for (IScreenDataReceiver receiver : mScreenDataReceivers) {
                                    receiver.onImageAvailable(ts, img);
                                }

                                int width = img.getWidth();
                                int height = img.getHeight();
                                Image.Plane[] planes = img.getPlanes();
                                int pixelStride = planes[0].getPixelStride();
                                int rowStride = planes[0].getRowStride();
                                int rowPadding = rowStride - pixelStride * width;
                                //读取到rawBitmap 宽度右边会有一个padding
                                Bitmap rawBitmap = Bitmap.createBitmap(width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888);
                                rawBitmap.copyPixelsFromBuffer(planes[0].getBuffer());
                                //关闭img
                                img.close();

                                for (IScreenDataReceiver receiver : mScreenDataReceivers) {
                                    receiver.onRawBitmap(ts, width, height, rawBitmap);
                                }

                                //生成没有padding的图片
                                Bitmap compressedBitmap = Bitmap.createBitmap(rawBitmap, 0, 0, width, height);
                                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                                compressedBitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
                                //回收rawBitmap
                                rawBitmap.recycle();

                                for (IScreenDataReceiver receiver : mScreenDataReceivers) {
                                    receiver.onCompressedBitmap(ts, compressedBitmap);
                                }
                                if (mLastCompressedBitmap != null) {
                                    //回收compressedBitmap
                                    mLastCompressedBitmap.recycle();
                                }
                                //保留最后一帧
                                mLastCompressedBitmap = compressedBitmap;
                                //这边的处理基本上在20ms左右
                        //Log.d(TAG, "process image cost: " + (System.currentTimeMillis() - ts));
                                mFpsHelper.print();
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                }, handler);
            }
        }.start();
    }

    private void release() {
        if (mStateCallback != null) {
            mStateCallback.onRelease();
        }

        mScreenDataReceivers.clear();

        if (mImageReader != null) {
            mImageReader.close();
            mImageReader = null;
        }
        if (mVirtualDisplay != null) {
            mVirtualDisplay.release();
        }
        if (mMediaProjection != null) {
            mMediaProjection.stop();
        }
        if (mImageThread != null) {
            mImageThread.quit();
            mImageThread = null;
        }
        if (mLastCompressedBitmap != null && !mLastCompressedBitmap.isRecycled()) {
            //回收compressedBitmap
            mLastCompressedBitmap.recycle();
            mLastCompressedBitmap = null;
        }
    }


    interface IScreenDataReceiver {
        void onImageAvailable(long frameTs, Image image);

        void onRawBitmap(long frameTs, int imgWidth, int imgHeight, Bitmap rawBitmap);

        void onCompressedBitmap(long frameTs, Bitmap bitmap);
    }

    public interface IStateCallback {
        void onRelease();
    }

}
