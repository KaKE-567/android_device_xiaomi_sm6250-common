# Common Device Tree for Xiaomi SM6250 Platform (LineageOS 18.1 / Android 11)

Common tree for Xiaomi devices powered by the **Qualcomm Snapdragon 720G (SM6250 / atoll)** platform.

---

## Included Features & Enhancements

1. **Snapdragon 720G EAS & Memory Tuning**:
   * **`init.qcom.post_boot.sh`**:
     * `watermark_scale_factor` tuned to `100` and `vfs_cache_pressure` to `100` to prevent synchronous direct page reclaim freezes during asset streaming in heavy games (BGMI, Genshin Impact).
     * Schedutil governor configured with `up_rate_limit_us 0` and `down_rate_limit_us 20000` to hold high frequencies across 16.6ms / 11.1ms frame boundaries.
     * `sched_conservative_pl` set to `0` to instantly scale CPU clocks on predicted load bursts.
     * Cpusets configured to grant foreground and real-time audio threads access to both Cortex-A76 Big cores (`foreground 0-7`, `system-background 0-5`).
   * **`configs/perf/perfboostsconfig.xml`**:
     * Complete native Qualcomm PerfHAL profiles enabled for `atoll`: Game Boost (`0x00001081` Type 4), App Launch, App Resume, Animation, Scroll, and Fling hints.

2. **Display & SurfaceFlinger Optimization**:
   * `debug.sf.latch_unsignaled=1` enabled in `system.prop` to eliminate fence synchronization dropouts and 1-frame micro-stutters.
   * `persist.sys.notch_killer=true` enabled for edge-to-edge immersive full-screen gaming.

3. **Leica Camera & Imaging**:
   * Integrated MIUI Leica camera suite and HAL permissions.

4. **Audio & Sensor System**:
   * FastMixer / low-latency audio heap configuration (`ro.af.client_heap_size_kbyte=7168`).
   * Direct Channel sensor access enabled for low-latency gyroscope and accelerometer polling.

5. **Aesthetics & Branding**:
   * Custom VortexOS boot animation and wallpapers.
   * Pixel feature permissions and Google Photos configuration.
