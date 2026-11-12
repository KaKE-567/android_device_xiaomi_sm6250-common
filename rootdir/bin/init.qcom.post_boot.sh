#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

function configure_memory_parameters() {
    # Set Memory parameters.
    #
    # Set per_process_reclaim tuning parameters
    # All targets will use vmpressure range 50-70,
    # All targets will use 512 pages swap size.
    #
    # Set Low memory killer minfree parameters
    # 32 bit Non-Go, all memory configurations will use 15K series
    # 32 bit Go, all memory configurations will use uLMK + Memcg
    # 64 bit will use Google default LMK series.
    #
    # Set ALMK parameters (usually above the highest minfree values)
    # vmpressure_file_min threshold is always set slightly higher
    # than LMK minfree's last bin value for all targets. It is calculated as
    # vmpressure_file_min = (last bin - second last bin ) + last bin
    #
    # Set allocstall_threshold to 0 for all targets.
    #

    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

        # Read adj series and set adj threshold for PPR and ALMK.
        # This is required since adj values change from framework to framework.
        adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
        adj_1="${adj_series#*,}"
        set_almk_ppr_adj="${adj_1%%,*}"

        # PPR and ALMK should not act on HOME adj and below.
        # Normalized ADJ for HOME is 6. Hence multiply by 6
        # ADJ score represented as INT in LMK params, actual score can be in decimal
        # Hence add 6 considering a worst case of 0.9 conversion to INT (0.9*6).
        # For uLMK + Memcg, this will be set as 6 since adj is zero.
        set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
        echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift

        # Calculate vmpressure_file_min as below & set for 64 bit:
        # vmpressure_file_min = last_lmk_bin + (last_lmk_bin - last_but_one_lmk_bin)
            minfree_series=`cat /sys/module/lowmemorykiller/parameters/minfree`
            minfree_1="${minfree_series#*,}" ; rem_minfree_1="${minfree_1%%,*}"
            minfree_2="${minfree_1#*,}" ; rem_minfree_2="${minfree_2%%,*}"
            minfree_3="${minfree_2#*,}" ; rem_minfree_3="${minfree_3%%,*}"
            minfree_4="${minfree_3#*,}" ; rem_minfree_4="${minfree_4%%,*}"
            minfree_5="${minfree_4#*,}"

            vmpres_file_min=$((minfree_5 + (minfree_5 - rem_minfree_4)))
            echo $vmpres_file_min > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
            if [ $MemTotal -gt 7602176 ]; then
                echo "18432,23040,27648,45158,119414,168896" > /sys/module/lowmemorykiller/parameters/minfree
            elif [ $MemTotal -gt 5505024 ]; then
                echo "18432,23040,27648,38708,102356,144768" > /sys/module/lowmemorykiller/parameters/minfree
            else
                echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
            fi

        # Enable adaptive LMK for all targets &
        # use Google default LMK series for all 64-bit targets >=2GB.
        echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk

        # Enable oom_reaper
            echo 1 > /sys/module/lowmemorykiller/parameters/oom_reaper

            #Set PPR parameters for all other targets.
            echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj
            echo 0 > /sys/module/process_reclaim/parameters/enable_process_reclaim
            echo 50 > /sys/module/process_reclaim/parameters/pressure_min
            echo 70 > /sys/module/process_reclaim/parameters/pressure_max
            echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
            echo 512 > /sys/module/process_reclaim/parameters/per_swap_size

    # Set allocstall_threshold to 0 for all targets.
    # Set swappiness to 60 for all targets (optimal zRAM balance)
    echo 0 > /sys/module/vmpressure/parameters/allocstall_threshold
    echo 60 > /proc/sys/vm/swappiness

    # Async page reclaim headroom to prevent direct reclaim stalls
    echo 30 > /proc/sys/vm/watermark_scale_factor

    # Fast non-blocking dirty page writeback & vfs cache
    echo 10 > /proc/sys/vm/dirty_ratio
    echo 5 > /proc/sys/vm/dirty_background_ratio
    echo 3000 > /proc/sys/vm/dirty_expire_centisecs
    echo 50 > /proc/sys/vm/vfs_cache_pressure
    echo 0 > /proc/sys/vm/page-cluster

    # UFS I/O read-ahead and request queue for fast game asset streaming
    for block in /sys/block/sd* /sys/block/dm-*
    do
        if [ -f "$block/queue/read_ahead_kb" ]; then
            echo 512 > $block/queue/read_ahead_kb
        fi
        if [ -f "$block/queue/nr_requests" ]; then
            echo 128 > $block/queue/nr_requests
        fi
    done

}

#Apply settings for atoll

    # Core control parameters - Disable hotplugging to keep all 8 cores online
    echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
    echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/enable
    echo 6 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
    echo 2 > /sys/devices/system/cpu/cpu6/core_ctl/min_cpus

    # Setting b.L scheduler parameters - Instant migration to Big Kryo cores
    echo 45 > /proc/sys/kernel/sched_downmigrate
    echo 55 > /proc/sys/kernel/sched_upmigrate
    echo 65 > /proc/sys/kernel/sched_group_downmigrate
    echo 75 > /proc/sys/kernel/sched_group_upmigrate
    echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

    # Colocation v3 & Instant Big Core Placement (Zero Stutter When Enemies Near)
    echo 1248000 > /proc/sys/kernel/sched_little_cluster_coloc_fmin_khz
    echo 0 > /proc/sys/kernel/sched_min_task_util_for_boost
    echo 0 > /proc/sys/kernel/sched_min_task_util_for_colocation
    echo 1 > /proc/sys/kernel/sched_boost

    # Configure governor settings for Little cluster (Silver Kryo 465 @ 1.8 GHz max)
    echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us
    echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us
    echo 1804800 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_freq
    echo 50 > /sys/devices/system/cpu/cpu0/cpufreq/schedutil/hispeed_load
    echo 576000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

    # Configure governor settings for Big cluster (Gold Kryo 465 @ 2.32 GHz max)
    echo "schedutil" > /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/up_rate_limit_us
    echo 20000 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/down_rate_limit_us
    echo 2323200 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_freq
    echo 50 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_load
    echo 652800 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_min_freq

    # Heavy task load boost priority
    echo 15 > /sys/devices/system/cpu/cpu6/sched_load_boost
    echo 15 > /sys/devices/system/cpu/cpu7/sched_load_boost

    # Disable conservative power limitation
    echo 0 > /proc/sys/kernel/sched_conservative_pl

    # CPU Boost & Touch input boost
    echo "0:1516800 6:1804800" > /sys/module/cpu_boost/parameters/input_boost_freq
    echo 150 > /sys/module/cpu_boost/parameters/input_boost_ms
    echo 15 > /sys/module/cpu_boost/parameters/dynamic_stune_boost
    echo "0:0 1:0 2:0 3:0 4:1804800 5:0 6:0 7:2323200" > /sys/module/cpu_boost/parameters/powerkey_input_boost_freq
    echo 400 > /sys/module/cpu_boost/parameters/powerkey_input_boost_ms

    # Set Memory parameters
    configure_memory_parameters

    # Enable bus-dcvs
    for device in /sys/devices/platform/soc
    do
        for cpubw in $device/*cpu-cpu-llcc-bw/devfreq/*cpu-cpu-llcc-bw
        do
            echo "bw_hwmon" > $cpubw/governor
            echo 20 > $cpubw/polling_interval
            echo "2288 4577 7110 9155 12298 14236" > $cpubw/bw_hwmon/mbps_zones
            echo 4 > $cpubw/bw_hwmon/sample_ms
            echo 68 > $cpubw/bw_hwmon/io_percent
            echo 20 > $cpubw/bw_hwmon/hist_memory
            echo 10 > $cpubw/bw_hwmon/hyst_length
            echo 40 > $cpubw/bw_hwmon/down_thres
            echo 500 > $cpubw/bw_hwmon/guard_band_mbps
            echo 250 > $cpubw/bw_hwmon/up_scale
            echo 1600 > $cpubw/bw_hwmon/idle_mbps
        done

        for llccbw in $device/*cpu-llcc-ddr-bw/devfreq/*cpu-llcc-ddr-bw
        do
            echo "bw_hwmon" > $llccbw/governor
            echo 20 > $llccbw/polling_interval
            echo "1144 1720 2086 2929 3879 5931 6881 8137" > $llccbw/bw_hwmon/mbps_zones
            echo 4 > $llccbw/bw_hwmon/sample_ms
            echo 68 > $llccbw/bw_hwmon/io_percent
            echo 20 > $llccbw/bw_hwmon/hist_memory
            echo 10 > $llccbw/bw_hwmon/hyst_length
            echo 40 > $llccbw/bw_hwmon/down_thres
            echo 600 > $llccbw/bw_hwmon/guard_band_mbps
            echo 250 > $llccbw/bw_hwmon/up_scale
            echo 1600 > $llccbw/bw_hwmon/idle_mbps
        done

        for npubw in $device/*npu*-npu-ddr-bw/devfreq/*npu*-npu-ddr-bw
        do
            echo 1 > /sys/devices/virtual/npu/msm_npu/pwr
            echo "bw_hwmon" > $npubw/governor
            echo 40 > $npubw/polling_interval
            echo "1144 1720 2086 2929 3879 5931 6881 8137" > $npubw/bw_hwmon/mbps_zones
            echo 4 > $npubw/bw_hwmon/sample_ms
            echo 80 > $npubw/bw_hwmon/io_percent
            echo 20 > $npubw/bw_hwmon/hist_memory
            echo 10 > $npubw/bw_hwmon/hyst_length
            echo 30 > $npubw/bw_hwmon/down_thres
            echo 0 > $npubw/bw_hwmon/guard_band_mbps
            echo 250 > $npubw/bw_hwmon/up_scale
            echo 0 > $npubw/bw_hwmon/idle_mbps
            echo 0 > /sys/devices/virtual/npu/msm_npu/pwr
        done

        #Enable mem_latency governor for L3, LLCC, and DDR scaling
        for memlat in $device/*cpu*-lat/devfreq/*cpu*-lat
        do
            echo "mem_latency" > $memlat/governor
            echo 10 > $memlat/polling_interval
            echo 400 > $memlat/mem_latency/ratio_ceil
        done

        #Enable cdspl3 governor for L3 cdsp nodes
        for l3cdsp in $device/*cdsp-cdsp-l3-lat/devfreq/*cdsp-cdsp-l3-lat
        do
            echo "cdspl3" > $l3cdsp/governor
        done

        #Gold L3 ratio ceil
        echo 4000 > /sys/class/devfreq/soc:qcom,cpu6-cpu-l3-lat/mem_latency/ratio_ceil

        #Enable compute governor for gold latfloor
        for latfloor in $device/*cpu*-ddr-latfloor*/devfreq/*cpu-ddr-latfloor*
        do
            echo "compute" > $latfloor/governor
            echo 10 > $latfloor/polling_interval
        done

    done

    # cpuset parameters
    echo 0-2         > /dev/cpuset/background/cpus
    echo 0-3         > /dev/cpuset/system-background/cpus
    echo 0-2,4-7 > /dev/cpuset/foreground/cpus
    echo 0-7         > /dev/cpuset/top-app/cpus

    # Keep WALT frequency aggregation and Big core priority enabled for esports baseline
    echo 1 > /proc/sys/kernel/sched_boost

    # Turn on sleep modes
    echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

    # === Zedex Extreme Gaming Engine Tweaks ===
    # 1. Adreno 618 GPU Tuning
    echo 0 > /sys/class/kgsl/kgsl-3d0/throttling 2>/dev/null || true
    echo 80 > /sys/class/kgsl/kgsl-3d0/idle_timer 2>/dev/null || true
    echo 3 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel 2>/dev/null || true

    # 2. UFS 2.1 Storage & I/O 2048KB Read-Ahead (Zero Texture Streaming Drops)
    for queue in /sys/block/sd*/queue/read_ahead_kb /sys/block/mmcblk*/queue/read_ahead_kb /sys/block/dm-*/queue/read_ahead_kb
    do
        echo 2048 > $queue 2>/dev/null || true
    done
    for requests in /sys/block/sd*/queue/nr_requests /sys/block/mmcblk*/queue/nr_requests /sys/block/dm-*/queue/nr_requests
    do
        echo 512 > $requests 2>/dev/null || true
    done
    for iostats in /sys/block/sd*/queue/iostats /sys/block/mmcblk*/queue/iostats
    do
        echo 0 > $iostats 2>/dev/null || true
    done

    # 3. Virtual Memory & In-Memory Game Cache Tuning
    echo 50 > /proc/sys/vm/vfs_cache_pressure
    echo 10 > /proc/sys/vm/dirty_ratio
    echo 5 > /proc/sys/vm/dirty_background_ratio
    echo 500 > /proc/sys/vm/dirty_expire_centisecs
    echo 500 > /proc/sys/vm/dirty_writeback_centisecs
    echo 0 > /proc/sys/kernel/sched_schedstats

    # 4. Touch & CPU Input Boost (Pinpoint Sniping Response)
    echo "0:1804800 6:2323200" > /sys/module/cpu_boost/parameters/input_boost_freq 2>/dev/null || true
    echo 60 > /sys/module/cpu_boost/parameters/input_boost_ms 2>/dev/null || true
    echo 1 > /sys/module/cpu_boost/parameters/dynamic_stune_boost 2>/dev/null || true

    # 5. Low-Ping TCP Protocol Optimization
    echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || true
    echo 16384 > /proc/sys/net/ipv4/tcp_notsent_lowat 2>/dev/null || true
    echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null || true
    echo 1 > /proc/sys/net/ipv4/tcp_sack 2>/dev/null || true
    echo 1 > /proc/sys/net/ipv4/tcp_window_scaling 2>/dev/null || true

    # 6. Sysfs Permissions for Settings & SystemUI Direct Profile Controls
    chmod 0666 /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq 2>/dev/null || true
    chmod 0666 /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq 2>/dev/null || true
    chmod 0666 /dev/stune/top-app/schedtune.boost 2>/dev/null || true
    chmod 0666 /sys/class/thermal/thermal_message/sconfig 2>/dev/null || true

    # 7. Fast Charging Engine (33W QC 4.0+ Unlocked)
    for fcc in /sys/class/power_supply/battery/constant_charge_current_max /sys/class/power_supply/main/constant_charge_current_max
    do
        chmod 0666 $fcc 2>/dev/null || true
        echo 6000000 > $fcc 2>/dev/null || true
    done
    for fastcharge in /sys/class/power_supply/battery/fastcharge_mode /sys/class/power_supply/battery/qc4_mode
    do
        chmod 0666 $fastcharge 2>/dev/null || true
        echo 1 > $fastcharge 2>/dev/null || true
    done

# Post-setup services
        setprop vendor.post_boot.parsed 1

# Let kernel know our image version/variant/crm_version
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
