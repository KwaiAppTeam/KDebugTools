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

import android.util.Log;

import java.util.LinkedList;
import java.util.List;

/**
 * 用于统计fps
 */
public class FpsHelper {
    private String name;
    private final List<Long> frameTs = new LinkedList<>();

    public FpsHelper(String name) {
        this.name = name;
    }

    public void addFrame() {
        frameTs.add(System.currentTimeMillis());
        clearOldFrame();
    }

    public void print() {
        clearOldFrame();
//        Log.d("FpsHelper", name + ": " + frameTs.size());
    }

    public int getFps() {
        clearOldFrame();
        return frameTs.size();
    }

    private void clearOldFrame() {
        for (; ; ) {
            //去除1s以前的数据
            if (frameTs.isEmpty() || System.currentTimeMillis() - frameTs.get(0) < 1000) {
                break;
            }
            frameTs.remove(0);
        }
    }
}
