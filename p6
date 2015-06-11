From c0a48acef7a34c30cd3edc03e971bc1161efacbd Mon Sep 17 00:00:00 2001
From: Lucille Sylvester <lsylvest@codeaurora.org>
Date: Thu, 13 Nov 2014 15:52:41 -0700
Subject: [PATCH] msm: kgsl: Bump the GPU frequency for long blocks of
 processing

If there are several frames of full GPU utilization immediately
bump the frequency to turbo rather than waiting for the DCVS
algorithm to run.

Change-Id: I1215225f8903a8656e8ad92c6c82567b86665933
Signed-off-by: Lucille Sylvester <lsylvest@codeaurora.org>
---
 drivers/devfreq/governor_msm_adreno_tz.c | 24 +++++++++++++++++++++++-
 1 file changed, 23 insertions(+), 1 deletion(-)

diff --git a/drivers/devfreq/governor_msm_adreno_tz.c b/drivers/devfreq/governor_msm_adreno_tz.c
index fc8819a..4c3634d 100644
--- a/drivers/devfreq/governor_msm_adreno_tz.c
+++ b/drivers/devfreq/governor_msm_adreno_tz.c
@@ -39,6 +39,14 @@ static DEFINE_SPINLOCK(tz_lock);
 #define CAP			75
 
 /*
+ * Use BUSY_BIN to check for fully busy rendering
+ * intervals that may need early intervention when
+ * seen with LONG_FRAME lengths
+ */
+#define BUSY_BIN		95
+#define LONG_FRAME		25000
+
+/*
  * CEILING is 50msec, larger than any standard
  * frame length, but less than the idle timer.
  */
@@ -95,11 +103,13 @@ static int tz_get_target_freq(struct devfreq *devfreq, unsigned long *freq,
 	int act_level;
 	int norm_cycles;
 	int gpu_percent;
+	static int busy_bin, frame_flag;
 
 	if (priv->bus.num)
 		stats.private_data = &b;
 	else
 		stats.private_data = NULL;
+
 	result = devfreq->profile->get_dev_status(devfreq->dev.parent, &stats);
 	if (result) {
 		pr_err(TAG "get_status failed %d\n", result);
@@ -129,6 +139,15 @@ static int tz_get_target_freq(struct devfreq *devfreq, unsigned long *freq,
 		return 0;
 	}
 
+	if ((stats.busy_time * 100 / stats.total_time) > BUSY_BIN) {
+		busy_bin += stats.busy_time;
+		if (stats.total_time > LONG_FRAME)
+			frame_flag = 1;
+	} else {
+		busy_bin = 0;
+		frame_flag = 0;
+	}
+
 	level = devfreq_get_freq_level(devfreq, stats.current_frequency);
 
 	if (level < 0) {
@@ -140,8 +159,11 @@ static int tz_get_target_freq(struct devfreq *devfreq, unsigned long *freq,
 	 * If there is an extended block of busy processing,
 	 * increase frequency.  Otherwise run the normal algorithm.
 	 */
-	if (priv->bin.busy_time > CEILING) {
+	if (priv->bin.busy_time > CEILING ||
+		(busy_bin > CEILING && frame_flag)) {
 		val = -1 * level;
+		busy_bin = 0;
+		frame_flag = 0;
 	} else {
 		val = __secure_tz_entry3(TZ_UPDATE_ID,
 				level,
-- 
2.1.1

