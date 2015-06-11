From 3bce70ca80c1a095d3c644c14e8224a012e43138 Mon Sep 17 00:00:00 2001
From: arter97 <qkrwngud825@gmail.com>
Date: Thu, 11 Jun 2015 17:20:10 +0900
Subject: [PATCH] msm: kgsl: check before setting governor specific data

Setting a wrong governor data causes whole GPU frequency scaling
to misbehave.

Fix this by checking beforehand.

Signed-off-by: arter97 <qkrwngud825@gmail.com>
---
 drivers/gpu/msm/kgsl_pwrscale.c | 42 ++++++++++++++++++++++-------------------
 1 file changed, 23 insertions(+), 19 deletions(-)

diff --git a/drivers/gpu/msm/kgsl_pwrscale.c b/drivers/gpu/msm/kgsl_pwrscale.c
index 46fd917..4af12c0 100644
--- a/drivers/gpu/msm/kgsl_pwrscale.c
+++ b/drivers/gpu/msm/kgsl_pwrscale.c
@@ -434,26 +434,30 @@ int kgsl_pwrscale_init(struct device *dev, const char *governor)
 
 	/* initialize any governor specific data here */
 	for (i = 0; i < profile->num_governor_data; i++) {
-		data = (struct devfreq_msm_adreno_tz_data *)
-			profile->governor_data[i].data;
-		/*
-		 * If there is a separate GX power rail, allow
-		 * independent modification to its voltage through
-		 * the bus bandwidth vote.
-		 */
-		if (pwr->bus_control) {
-			out = 0;
-			while (pwr->bus_ib[out]) {
-				pwr->bus_ib[out] =
-					pwr->bus_ib[out] >> 20;
-				out++;
+		if (strncmp("msm-adreno-tz",
+				profile->governor_data[i].name,
+				DEVFREQ_NAME_LEN) == 0) {
+			data = (struct devfreq_msm_adreno_tz_data *)
+				profile->governor_data[i].data;
+			/*
+			 * If there is a separate GX power rail, allow
+			 * independent modification to its voltage through
+			 * the bus bandwidth vote.
+			 */
+			if (pwr->bus_control) {
+				out = 0;
+				while (pwr->bus_ib[out]) {
+					pwr->bus_ib[out] =
+						pwr->bus_ib[out] >> 20;
+					out++;
+				}
+				data->bus.num = out;
+				data->bus.ib = &pwr->bus_ib[0];
+				data->bus.index = &pwr->bus_index[0];
+				printk("kgsl: num bus is %d\n", out);
+			} else {
+				data->bus.num = 0;
 			}
-			data->bus.num = out;
-			data->bus.ib = &pwr->bus_ib[0];
-			data->bus.index = &pwr->bus_index[0];
-			printk("kgsl: num bus is %d\n", out);
-		} else {
-			data->bus.num = 0;
 		}
 	}
 
-- 
2.1.1

