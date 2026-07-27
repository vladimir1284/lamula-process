
/******************************************************************

    vdeal's module containing functions related to VAD analysis.

******************************************************************/

/* 
 * RCS info
 * $Author: cbryan $
 * $Locker:  $
 * $Date: 2024/10/01 19:51:27 $
 * $Id: vdeal_vad.c,v 1.2 2024/10/01 19:51:27 cbryan Exp $
 * $Revision: 1.2 $
 * $State: Exp $
 */  

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include <infr.h>
#include "vdeal.h"

typedef struct {	/* single VAD struct */
    float u;		/* u component (horizontal) - CF2 / cos (elev) */
    float v;		/* v component (horizontal) - CF3 / cos (elev) */
    float rms;		/* RMS */
    unsigned int dtm;	/* time of data collection; 0 for invalid record. */
    float alt;		/* altitude in meters */
    float range;	/* range in meters */
    int vol_num;
    short cut_num;
    short elev;		/* elevation in .1 degrees */
} Vad_t;

typedef struct {	/* Result from Vad_analysis */
    float CF1;		/* Fourier coefficient - C0 */
    float CF2;		/* Fourier coefficient - Re (C1) */
    float CF3;		/* Fourier coefficient - Im (C1) */
    float rms;		/* RMS */
    float rms1;		/* RMS in first phase */
    float speed;	/* radial wind speed */
    float dir;		/* wind direction - direction wind coming */
} Vad_result_t;

/* Note that u, v, speed and rms in this module are in data unit - not in
   m/s - if not otherwise specified */

#define ERE 7708910. /* NEXRAD SPS effective radius of earth (SRS 6/5 model),
			in meters, 6371 * 1.21 */
#define HARF_BEAMWIDTH (.5)	/* half of the radar beam width */

int VDV_use_ext_wind = 1;
extern int Test_mode;

#define VAD_EXTW_VERI_VALID_TIME (3600 * 3)
		/* VAD and EXTW verification effective time in seconds */
#define EXTW_VALID_TIME (3600 * 3)	/* EXTW valid time in seconds */

int VDV_free_atmo_l = 4000;	/* %040319 low altitude (m/s) of free almosphere */
int VDV_free_atmo_h = 9000;	/* high altitude (m/s) of free almosphere */

#define MAX_N_VADS 256
static int N_vads = 0;		/* number of VADS */
static int Latest_vad = -2;	/* vads index of the latest element */
static Vad_t Vads[MAX_N_VADS];	/* VAD arrays */

#define DIST_AR_SIZE 90		/* storm distance array size */
typedef struct {		/* storm distance struct */
    unsigned int dtm;		/* time of data */
    int dist[DIST_AR_SIZE];	/* storm distance vs azi, in meters */
    int vol_num;
} S_d_t;

static S_d_t Sds;		/* min storm distance of previous volume */
static S_d_t Csds;		/* storm distance of curent volume */

static int Vad_age = 1200;	/* VAD sample age - 20 minutes */

static int N_vsas = 0;
static int Non_uniform_yc = -1;	/* center y of nonuniform detection */

#define BAD_AZI_V (1000.f)		/* value for bad azimuth */
static unsigned int Extw_time = 0;	/* current external wind time */
static int Extw_verified = -2;	/* EXTW verification flag: -1 bad; 1 good; 
				   0 not verified; -2 no FW wind; */
static unsigned int Extw_vt = 0;/* XTW verification time */
static int Vad_verified = 0;	/* VAD verification flag: -1 bad; 1 good; */
static unsigned int Vad_vt = 0; /* VAD verification time */
static float Extw_dir = BAD_AZI_V;	/* current external wind direction */

static int Vad_analysis (short *vr, short *azi, int n_vr, Vad_result_t *out);
static void C_mul (double ratio, double r1, double i1, double r2, double i2,
					double *rr, double *ri);
static int Calculate_speed (double CF2, double CF3, double *dwp, double *spd);
static int Check_vad (Vdeal_t *vdv, Vad_result_t *vad, int max, int rst);
static void Get_data_buffer (int size, short **vrs, short **azis);
static int Get_averaged_data (Vdeal_t *vdv, int rst, int nr, 
			short *vrs, short *azis, int thr, int *maxp);
static int Process_data (Vdeal_t *vdv, int cnt, int azi_span,
					short *vrs, short *azis);
static int Two_phase_vad (Vdeal_t *vdv, int rst, int nr, Vad_result_t *vad);
static int Get_next_vad_range (Vdeal_t *vdv, int st_ind, int width);
static int Get_vad_wind (Vdeal_t *vdv, double alt, double range, int both_side,
					double *speed, double *azip);
static double Determinant3 (double x11, double x12, double x13, double x21,
	double x22, double x23, double x31, double x32, double x33);
static double Get_delta_h (double h);
static int Get_ext_wind (Vdeal_t *vdv, double dalt,
				double *spd, double *dir, unsigned int *tm);
static int Get_interpolate_wind (int n_samples, short *smp_inds, 
				double talt, double *u, double *v);
static int Fitting2d (int n, double *x, double *y, double *v, double *ap, 
						double *bp, double *cp);
static int Get_ra_interp_wind (int cnt, short *smps,
			double alt, double range, double *up, double *vp);
static void V_sign_analysis (Vdeal_t *vdv, Vad_result_t *vad, int vad_ind,
						int st_r, int nr);
static int Search_segs (short *buf, int yz, int thr, void *vsegs);
static int Computes_zc_segs (Vdeal_t *vdv, int st_r, int nr, 
				double thr, void *vsegs, short *vbuf);
static void Vs_full_cut_analysis (Vdeal_t *vdv);
static int Zc_by_correlation (Vdeal_t *vdv, short *svs, short *dvs, int zc);
static void Correct_vad_via_zc (Vdeal_t *vdv, int nu_st);
static int Set_vertical_shear_flag (Vdeal_t *vdv);
static int Sample_too_far (double sa, double alt, double *ar);
static int Wind_differ (Vdeal_t *vdv, double dir, double spd, 
						double dir1, double spd1);


/*d static void Print_vad_sample (char *lable, Vad_t *vt) {
    double u, v, dir, spd;
    u = vt->u;
    v = vt->v;
    Calculate_speed (u, v, &dir, &spd);
    MISC_log ("%s h %5.0f  spd %.1f azi %.1f rms %.1f  ele %3d rg %.0f   cut %d vol %d\n", lable, vt->alt, spd, dir / deg2rad, vt->rms, vt->elev, vt->range, vt->cut_num, vt->vol_num);
}

int VDV_print_samples (Vdeal_t *vdv, double a1, double a2) {
    int i, cnt;
    cnt = 0;
    for (i = 0; i < N_vads; i++) {
	int ind;
	Vad_t *vad;

	ind = (Latest_vad - i + MAX_N_VADS) % MAX_N_VADS;
	vad = Vads + ind;
	if (vad->dtm == 0)
	    continue;
	if ((double)vad->alt >= a1 && (double)vad->alt <= a2)
	    Print_vad_sample ("@VASD ", vad);
	cnt++;
    }
    MISC_log ("@VDV_print_samples %5.1f to %5.1f - total %d N %d F %d\n", a1, a2, cnt, N_vads, Latest_vad);
    return (0);
}
*/

/*****************************************************************************

    Altitude-to-range and range-to-altitude conversion functions.

*****************************************************************************/

double VDV_range_to_alt (Vdeal_t *vdv, double R) {
    double e = vdv->elev;
    return (sqrt ((double)R * R + ERE * ERE + 
			2. * R * ERE * sin (e * deg2rad)) - ERE);
}

double VDV_alt_to_range (Vdeal_t *vdv, double alt) {
    double asn = sin ((double)vdv->elev * deg2rad) * ERE;
    return (sqrt (asn * asn + alt * alt + 2. * alt * ERE) - asn);
}

/***************************************************************************

    Returns, with spdp and azip, the projection on the elevation angle
    of EW at location "xs"-th bin and returns its projection on the
    elevation angle. Returns 1 if external wind is used, or 2 if limited
    VAD extraction is used, or 0 if the wind is get otherwise, or -1 if 
    no EW data available.

***************************************************************************/

int VDV_get_wind (Vdeal_t *vdv, int xs, double *spdp, double *azip) {
    double drg, dalt, dalt_thresh, spd, dir;
    int ret_v;

    drg = (double)xs * vdv->g_size;
    dalt = VDV_range_to_alt (vdv, drg);

    if(vdv->elev > 1.5){
        dalt_thresh = 7000.;
    }
    else{
        dalt_thresh = 10500.;
    }

    ret_v = 0;
    if (!VDV_use_ext_wind || (vdv->data_type & DT_NO_EXTWIND)) {
			/* extern wind is not used if any VAD exists */
	if (Get_vad_wind (vdv, dalt, drg, 2, &spd, &dir) >= 0)
	    ret_v = 2;
	else if (Get_vad_wind (vdv, dalt, drg, 0, &spd, &dir) < 0)
	    return (-1);
    }
    else if ((vdv->data_type & DT_WEAK_DATA_NEAR_RADAR) &&
	      xs < 100 && Get_ext_wind (vdv, dalt, &spd, &dir, NULL) >= 0) {
	ret_v = 1;
    }
    else {		/* extern wind is used if VAD is not close */
	if (dalt >= dalt_thresh && !(vdv->data_type & DT_NONUNIFORM) &&
	    Get_vad_wind (vdv, dalt, drg, 1, &spd, &dir) < 0 &&
	    Get_ext_wind (vdv, dalt, &spd, &dir, NULL) >= 0 ) {
	    ret_v = 1;
	    if (xs < vdv->ext_win_range)
		vdv->ext_win_range = xs;
	}
	else if (Get_vad_wind (vdv, dalt, drg, 2, &spd, &dir) < 0) {
	    if (Get_ext_wind (vdv, dalt, &spd, &dir, NULL) >= 0)
		ret_v = 1;
	    else if (Get_vad_wind (vdv, dalt, drg, 0, &spd, &dir) < 0)
		return (-1);
	}
	else
	    ret_v = 2;
    }

    spd = spd * cos ((double)vdv->elev * deg2rad) * ERE / (ERE + dalt);
    *azip = dir;
    *spdp = spd;

    return (ret_v);
}

/***************************************************************************

    Returns the radial wind correction due to vertical shear and beam width
    effect at ew grid [xi, yi].

***************************************************************************/

int VDV_get_bw_vs_correction (Vdeal_t *vdv, int xi, int yi) {
    Ew_struct_t *ew;
    double elev;
    unsigned char *efs;
    int cor_w, cor_r;

    if (Sds.dtm == 0)
	return (0);
    ew = &(vdv->ew);
    efs = ew->efs + yi * ew->n_rgs;
//    if (!(efs[xi] & EF_STORM))
//	return (0);
    for (cor_r = 0; cor_r < ew->n_rgs; cor_r++) {
	if (efs[cor_r] & EF_STORM)
	    break;
    }
    if (cor_r >= ew->n_rgs || xi < cor_r)
	return (0);

    elev = vdv->elev;
    if (elev < .5)
	elev = .5;
    {
	double b, c, ere;
	ere = ERE / (ew->rz * vdv->g_size);
	c = cor_r * cor_r + 2. * cor_r * ere * sin ((elev + HARF_BEAMWIDTH) * deg2rad);
	b = 2. * ere * sin ((elev - HARF_BEAMWIDTH) * deg2rad);
	cor_w = Myround (.5 * (sqrt (b * b + 4. * c) - b) - cor_r);
    }
    if (cor_w < 0.5 || xi >= cor_r + cor_w)
	return (0);

    {			/* calculate bw correction */
	double cose, dist, azi;
	int sdi, corr;
	cose = cos (elev * deg2rad);
	dist = xi * ew->rz * cose * vdv->g_size;
	azi = yi * ew->az + ew->az * .5;
	sdi = Myround (azi * DIST_AR_SIZE / 360.) % DIST_AR_SIZE;
	if (Sds.dist[sdi] < 0 || Sds.dist[sdi] + ew->rz * vdv->g_size >= dist)
	    return (0);

	corr = Myround ((cor_w + cor_r - xi) * .5);
	return (corr);
   }    

    return (0);
}

/***************************************************************************

    Returns maximum vertical shear.

***************************************************************************/

static int Set_vertical_shear_flag (Vdeal_t *vdv) {
    int i;
    double ele, cose, sine, dirp, dirdiff, tsdiff, mindf, maxdf, max_inc;
    double vss[MAX_EW_NRS], rss[MAX_EW_NRS], no_data;
//extern int dbg;

    no_data = 1024 * 1024;
    double maxvs = 0.;
    vdv->data_type &= ~DT_VH_VS;
    vdv->data_type &= ~DT_VH_VDS;
    ele = vdv->elev * deg2rad;
    cose = cos (ele);
    sine = sin (ele);
    dirp = -1000.;
    dirdiff = 0.;
    tsdiff = mindf = maxdf = max_inc = 0.;
    for (i = 0; i < vdv->ew.n_rgs; i++) {	/* compute vertical shear */
	double rng, a, s, u, v, svh, uu, uv, du, dv, cs, csp;

	vdv->ew.rfs[i] &= ~(RF_2SIDE_VAD | RF_HIGH_VS | RF_LOW_VS | RF_HIGH_WIND);
	vss[i] = rss[i] = no_data;	/* vertical shear and radial speed */
	rng = ((double)i * vdv->ew.rz + vdv->ew.rz * .5) * vdv->g_size;
	a = VDV_range_to_alt (vdv, rng);
	svh = (rng * ERE * cose * 1. * deg2rad + 
			(rng + ERE * sine) * vdv->g_size) / (a + ERE);
			/* sampling volume height (1 degree beam width) */

	if (Get_vad_wind (vdv, a, -1., 1, &u, &v) < 0)
	    continue;

	vdv->ew.rfs[i] |= RF_2SIDE_VAD;
	if (Get_vad_wind (vdv, a + .5 * svh, -1., 1, &uu, &uv) < 0 ||
	    Get_vad_wind (vdv, a - .5 * svh, -1., 1, &du, &dv) < 0)
	    continue;

	if (sqrt (uu * uu + uv * uv) > 35. * vdv->data_scale)
	    vdv->ew.rfs[i] |= RF_HIGH_WIND;

	s = sqrt (u * u + v * v);
	if (s <= 1.)
	    csp = 0.;
	else
	    csp = ((uu - du) * u + (uv - dv) * v) / s;	/* project to (u, v) */
	if (csp < 0.)
	    csp = -csp;
	cs = sqrt ((uu - du) * (uu - du) + (uv - dv) * (uv - dv));

	if (!(u == 0. && v == 0.)) {
	    double dir = atan2 (v, u) * rad2deg;
	    if (dirp < -360.)
		dirp = dir;
	    else {
		double diff, sdiff;
		diff = dir - dirp;
		sdiff = diff;
		while (diff < 0.)
		    diff += 360.;
		while (diff >= 360.)
		    diff -= 360.;
		if (diff > 180.)
		    diff = 360. - diff;
		dirdiff += diff;
		dirp = dir;
		if (rng >= 400. * vdv->g_size && rng <= 900. * vdv->g_size) {
		    if (diff > max_inc)
			max_inc = diff;
		    if (sdiff > 180.)
			sdiff = 360. - sdiff;
		    if (sdiff < -180.)
			sdiff = 360. + sdiff;
		    tsdiff += sdiff;
		    if (tsdiff < mindf)
			mindf = tsdiff;
		    if (tsdiff > maxdf)
			maxdf = tsdiff;
//printf ("    i %d  sdiff %.1f  tsdiff %.1f  mindf %.1f  maxdf %.1f dir %.1f  diff  %.1f\n", i, sdiff, tsdiff, mindf, maxdf, dir, diff);
		}
	    }
	}
//printf ("    i %d   a %.1f  rng %d\n", i, a, (int)(rng/vdv->g_size));

//MISC_log ("  i %d,  R %.0f,  alt %.0f, (%.3f %.3f %.1f),  svh %.0f\n", i, rng / vdv->g_size, a, cs, csp, dirdiff, svh);
	if (cs > maxvs)
	    maxvs = cs;
	vss[i] = csp * .5 + cs * .5;
	rss[i] = s * cose;
    }
//printf ("      mindf  %.1f  maxdf %.1f  max_inc %.1f\n", mindf, maxdf, max_inc);

    for (i = 0; i < vdv->ew.n_rgs; i++) {	/* set vertical shear flag */
	double vs, rs;
	vs = vss[i];
	rs = rss[i];
	if (vs == no_data) {	/* interpolation */
	    int il, iu, k;
	    double vsl, vsu, rsl, rsu;
	    il = iu = -1;
	    vsl = vsu = rsl = rsu = no_data;
	    for (k = i - 1; k >= 0; k--) {
		if (vss[k] != no_data) {
		    vsl = vss[k];
		    rsl = rss[k];
		    il = k;
		    break;
		}
	    }
	    for (k = i + 1; k < vdv->ew.n_rgs; k++) {
		if (vss[k] != no_data) {
		    vsu = vss[k];
		    rsu = rss[k];
		    iu = k;
		    break;
		}
	    }
	    if (il >= 0 && iu >= 0) {
		vs = vsl + (vsu - vsl) * (i - il) / (iu - il);
		rs = rsl + (rsu - rsl) * (i - il) / (iu - il);
	    }
	    else if (il >= 0) {
		vs = vsl;
		rs = rsl;
	    }
	    else if (iu >= 0) {
		vs = vsu;
		rs = rsu;
	    }
	}
	if (vs == no_data)
	    continue;
	if (dirdiff < 45.)
	    continue;
	if (vs >= 22.5 * vdv->data_scale || rs >= 75. * vdv->data_scale)
	    vdv->ew.rfs[i] |= (RF_HIGH_VS | RF_LOW_VS);
	else if (vs >= 15. * vdv->data_scale || rs >= 62.5 * vdv->data_scale)
	    vdv->ew.rfs[i] |= RF_HIGH_VS;
	else if (vs >= 7.5 * vdv->data_scale || rs >= 50. * vdv->data_scale)
	    vdv->ew.rfs[i] |= RF_LOW_VS;
    }

    if (maxvs > vdv->nyq && dirdiff >= 90.)
	vdv->data_type |= DT_VH_VS;
    if (maxdf - mindf > 90. || max_inc > 30.)
	vdv->data_type |= DT_VH_VDS;

    vdv->data_type &= ~(DT_HVS_HW);
    {
	Ew_struct_t *ew = &(vdv->ew);
	int vhscnt, hwcnt, vhsbits;
	hwcnt = vhscnt = 0;
	vhsbits = RF_LOW_VS | RF_HIGH_VS;
	for (int i = 0; i < ew->n_rgs; i++) {
	    if ((ew->rfs[i] & vhsbits) == vhsbits)	/* VHS range */
		vhscnt++;
	    if (ew->rfs[i] & RF_HIGH_WIND)	/* HW range */
		hwcnt++;
	}
	if (vhscnt >= ew->n_azs / 3 && hwcnt >= 2)
	    vdv->data_type |= DT_HVS_HW;
    }

    int hshw = 0;
    for (i = 0; i < vdv->ew.n_rgs; i++) {
	if (i * vdv->ew.rz > PP_get_first_trip_range ())
	    break;
	if (vdv->ew.rfs[i] & RF_HIGH_WIND)
	    hshw = 1;
	if (vdv->ew.rfs[i] & RF_HIGH_VS)
	    hshw = 1;
    }
    vdv->data_type &= ~DT_NO_VS_HW;
    if (hshw == 0)
	vdv->data_type |= DT_NO_VS_HW;

    return (0);
}

/********************************************************************

    Saves the storm distance info.

*********************************************************************/

void VDV_save_storm_distance (Vdeal_t *vdv) {
    int i, cr_dtm, cr_vol, max_r, csds_vol;
    Ew_struct_t *ew;

    cr_dtm = vdv->dtm;
    cr_vol = vdv->vol_num;
    csds_vol = Csds.vol_num;
    if (Csds.dtm == 0 || cr_dtm < Csds.dtm || cr_dtm > Csds.dtm + 300 ||
	cr_vol < csds_vol || cr_vol > csds_vol + 1) { /* new session */
//MISC_log ("  NEW session:  Csds.dtm %d  cr_dtm %d   csds_vol %d cr_vol %d\n", Csds.dtm, cr_dtm, csds_vol, cr_vol);
	Csds.dtm = 0;
	Sds.dtm = 0;		/* invalid Sds */
    }
    else if (cr_vol == csds_vol + 1) {	/* new volume */
	Sds = Csds;
//for (i = 0; i < DIST_AR_SIZE; i++)
//MISC_log ("   i %d  dist %d\n", i, Sds.dist[i]);
	Csds.dtm = 0;
    }

    if (Csds.dtm == 0) {
	for (i = 0; i < DIST_AR_SIZE; i++) {
	    Csds.dist[i] = -1;
	    if (Sds.dtm == 0)
		Sds.dist[i] = -1;
	}
	Csds.vol_num = 0;
    }
    Csds.dtm = cr_dtm;
    Csds.vol_num = cr_vol;

    ew = &(vdv->ew);
    max_r = VDV_alt_to_range (vdv, 6000.) / (vdv->g_size * ew->rz);
    for (i = 0; i < DIST_AR_SIZE; i++) {
	int x, y;
	unsigned char *efs;

	y = Myround (i * 360. / (DIST_AR_SIZE * ew->az)) % ew->n_azs;
	efs = ew->efs + y * ew->n_rgs;
	for (x = 0; x < ew->n_rgs; x++) {
	    if (x > max_r)
		break;
	    if (efs[x] & EF_STORM)
		break;
	}
	if (efs[x] & EF_STORM) {
	    int k;
	    int dist = x * ew->rz * cos (vdv->elev * deg2rad) * vdv->g_size;
	    for (k = -1; k <= 1; k++) {
		int ind = (i + k + DIST_AR_SIZE) % DIST_AR_SIZE;
		if (dist < Csds.dist[ind] || Csds.dist[ind] < 0)
		    Csds.dist[ind] = dist;
	    }
	}
    }
}

/***************************************************************************

    Averages "nr" range gates, stating with range index "rst", on each 
    radial from vdv->out. The result is returned with "vrs". The 
    corresponding azimuths are returned with "azis". Returns the number
    of azimuths that have data. If thr > 0, vrs contains the targeted
    values of data. Only data that have difference < thr is used. The
    elements of vrs must be corresponding to those returned with the same
    vdv data and the same rst and nr and thr = 0. vdv->dmap is used to
    exclude bad data.

***************************************************************************/

static int Get_averaged_data (Vdeal_t *vdv, int rst, int nr, 
			short *vrs, short *azis, int thr, int *maxp) {
    short vrsd;
    int doff, n_gcc, near_0, yz, stride, cnt, dcnt, y, max;
    unsigned char bits, *m;
    char *gcc;

    yz = vdv->yz;
    bits = DMAP_BH | DMAP_BE | DMAP_FILL;
    stride = vdv->xz;
    doff = vdv->data_off;
    n_gcc = CD_get_gcc_likely (&gcc);
    near_0 = vdv->data_scale * 3 + .5;
    cnt = dcnt = max = 0;
    vrsd = 0;
    for (y = 0; y < yz; y++) {
	int c, dc, v, i;
	short *p;

	p = vdv->out + (y * stride + rst);
	m = vdv->dmap + (y * stride + rst);
	c = dc = 0;
	v = 0;
	if (thr > 0)
	    vrsd = doff + vrs[dcnt];
	for (i = 0; i < nr; i++) {
	    short d = p[i];
	    if (d == SNO_DATA || (m[i] & bits))
		continue;
	    if (rst + i < n_gcc && gcc[rst + i]) {
		int df = d - doff;
		if (df < 0)
		    df = -df;
		if (df <= near_0)	/* likely a GCC gates */
		    continue;
	    }

	    dc++;
	    if (thr > 0) {
		int diff = d - vrsd;
		if (diff < 0)
		    diff = -diff;
		if (diff > thr)
		    continue;
	    }
	    v += d;
	    c++;
	}
	if (c > 0) {
	    int a;
	    vrs[cnt] = Myround ((double)v / c) - doff;
	    a = vrs[cnt];
	    if (a < 0)
		a = -a;
	    if (a > max)
		max = a;
	    azis[cnt] = vdv->ew_azi[y];
	    cnt++;
	}
	if (dc > 0)
	    dcnt++;
    }
    if (maxp != NULL)
	*maxp = max;
    return (cnt);
}

/***************************************************************************

    Performs basic quallity check on "vad". Returns 0 if check fails. 
    Returns 1 if OK. Returns 2 if fails but it is very long range and rms 
    is not too large. When speed > 5 m/s, the max RMS increases with speed.

***************************************************************************/

static int Check_vad (Vdeal_t *vdv, Vad_result_t *vad, int max, int rst) {
    float t, thr;
    int ret;

    /* if only data near zero is available - must avoid over extrapolation */
    if (vdv->data_type & DT_NONUNIFORM) {  /* slop based VAD can be worse */
	if (vad->speed > max * 1.2f)
	    return (0);
	else if (vad->speed > max)
	    vad->speed = max;
    }
    else {
	if (vad->speed > max * 1.5f)
	    return (0);
	else if (vad->speed > max * 1.2f)
	    vad->speed = max * 1.2f;
    }

    t = 3.f * vdv->data_scale;	/* 3 m/s */
    thr = ((vad->speed - 5.f * vdv->data_scale) * .25f) + t;
    if (thr < t)
	thr = t;
    ret = 1;
    if (vad->rms > thr) {
//MISC_log (" $ 5   %f  %f   %d\n", vad->rms, thr, rst);
	if (rst >= 900 && vad->rms <= thr * 1.5f)
	    ret = 2;
	else
	    return (0);
    }
    t = vad->CF1;
    if (t < 0)
	t = -t;
    if (t > vad->speed * .5f)
	return (0);
    if (vad->speed > 100 * vdv->data_scale)	/* 100 m/s */
	return (0);
    return (ret);
}
/***************************************************************************

    Processes the data of "cnt" radial velocities "vrs" at azimuthes of 
    "azis". The data must span at least "azi_span" and half of them must be
    not close to zero speed. Returns the size of the processed "vrs" and 
    "azis".

***************************************************************************/

static int Process_data (Vdeal_t *vdv, int cnt, int azi_span,
					short *vrs, short *azis) {
    int thr, nonzero_cnt, max_gap, total_scan_angle, i;

    if (cnt < (int)((double)azi_span / vdv->gate_width))
	return (0);

    thr = 4 * vdv->data_scale;	/* 4 m/s threshold */
    max_gap = total_scan_angle = 0;
    nonzero_cnt = 0;
    for (i = 0; i < cnt - 1; i++) {
	int cr, next, inc, v;

	cr = azis[i];
	next = azis[i + 1];
	inc = next - cr;
	if (inc < -15)		/* 1.5 degrees - maximum azi back movement */
	    inc += 3600;
	if (total_scan_angle + inc >= 3600)
	    break;
	total_scan_angle += inc;
	if (inc > max_gap)
	    max_gap = inc;
	v = vrs[i];
	if (v < 0)
	    v = -v;
	if (v >= thr)
	    nonzero_cnt++;
    }
    if (nonzero_cnt < (int)((double)azi_span / (2. * vdv->gate_width)))
	return (0);

    if (3600 - total_scan_angle > max_gap)
	max_gap = 3600 - total_scan_angle;

    if (max_gap > 1800) {
	int na, az;

	az = vdv->yz;		/* array size of vsr and azis */
	for (i = 0; i < cnt; i++) {
	    if (cnt + i >= az)
		break;
	    vrs[cnt + i] = -vrs[i];
	    na = azis[i] + 1800;
	    if (na > 3600)
		na -= 3600;
	    azis[cnt + i] = na;
	}
	cnt += i;
    }

    return (cnt);
}

/*************************************************************************

    Checks if this is an cut that repeats a previous cut in the voluume
    with the same elevation. Returns 1 if it is or 0 otherwise.

*************************************************************************/

int VDV_is_dup_elevation (Vdeal_t *vdv) {
    #define N_PRCSDE_ELEVS 8
    static int Prcsde_cr_vol_num = 0, N_prcsde_elevs = 0, Prcsde_skip = 0;
    static float Prcsde_elevs[N_PRCSDE_ELEVS];
    static int Prcsde_cr_cut = -1;

    if (vdv->vol_num != Prcsde_cr_vol_num) {	/* new vol starts */
	N_prcsde_elevs = 0;
	Prcsde_cr_vol_num = vdv->vol_num;
	Prcsde_cr_cut = -1;
    }
    if (vdv->cut_num != Prcsde_cr_cut) {	/* new cut starts */
	int i;
	Prcsde_cr_cut = vdv->cut_num;
	Prcsde_skip = 0;
	for (i = 0; i < N_prcsde_elevs; i++) {
	    double diff = vdv->elev - Prcsde_elevs[i];
	    if (diff < 0.)
		diff = -diff;
	    if (diff < .2) {
		MISC_log ("Duplicated elevation\n");
		Prcsde_skip = 1;
	    }
	}
	if (!Prcsde_skip && N_prcsde_elevs < N_PRCSDE_ELEVS) {
	    Prcsde_elevs[N_prcsde_elevs] = vdv->elev;
	    N_prcsde_elevs++;
	}
    }
    if (Prcsde_skip)
	return (1);
    return (0);
}

/*************************************************************************

    Sets DT_VAD_NONUNIF when long range high RMS VAD is detected.

*************************************************************************/

static void Set_vad_nonunif (Vdeal_t *vdv, int st_i, float rms) {
    static int hrms_st, hrms_end, last_st;

    if (st_i >= 0 || st_i == -2) {
	if (st_i >= 0)
	    last_st = st_i;	/* last vad available st_i */
	if (st_i == -2 || rms >= 8.f) {	/* non uniform wind */
	    if (hrms_st < 0)
		hrms_st = st_i;
	    hrms_end = st_i;
	}
	else 
	    hrms_st = hrms_end = -1;	/* good vad */
    }
    else if (st_i == -1) {
	hrms_st = hrms_end = -1;
	last_st = 0;
    }
    else if (st_i == -3) {	/* set the flag */
//printf (" %d %d %d\n", hrms_st, hrms_end, last_st);
	vdv->data_type &= ~DT_VAD_NONUNIF;
	if (hrms_end > 600 && hrms_end >= last_st && hrms_end - hrms_st >= 50)
//{
	    vdv->data_type |= DT_VAD_NONUNIF;
//printf ("DT_VAD_NONUNIF set\n");
//}
    }
}

/***************************************************************************

    Performs VAD analysis on vdv->out and puts the results in Vads. If tmp_rec
    is -1 or 1, the next call will override records generated in this call.
    If tmp_rec < 0, a full cut analysis is performed. If tmp_rec = 2, the
    latest records becomes permanent. If tmp_rec = 0, the latest records are
    discarded.

***************************************************************************/

int VDV_vad_analysis (Vdeal_t *vdv, int tmp_rec) {
    static int prev_latest = -2, prev_n_vads = 0;
    double cselev, min_h, rst, elev;
    int log_vad;

    if (Latest_vad == -2) {	/* initializes the buffer so we can compare saved history data. No effect on redult. */
	memset (Vads, 0, sizeof (Vads));
	Latest_vad = -1;
    }

    if (tmp_rec == 2) {
	int cnt, i;
	prev_latest = -2;
//printf ("tmp_rec %d   N_vads %d  Latest_vad %d\n", tmp_rec, N_vads, Latest_vad);
	cnt = 0;	/* discard old samples in terms of vol num */
	for (i = 0; i < N_vads; i++) {
	    int ind = (Latest_vad - N_vads + 1 + i + MAX_N_VADS) % MAX_N_VADS;
	    Vad_t *vad = Vads + ind;
//MISC_log ("      rec v %d   cv %d\n", vad->vol_num, vdv->vol_num);
	    if (vad->vol_num + 2 > vdv->vol_num)
		break;
	    cnt++;
	}
//MISC_log ("      N_vads reduce by %d\n", cnt);
	N_vads -= cnt;
	return (0);
    }
    if (tmp_rec == 0) {
	if (prev_latest >= -1) {
	    int inc = Latest_vad - prev_latest;
	    if (inc < 0)
		inc += MAX_N_VADS;
	    Latest_vad = prev_latest;
	    N_vads = prev_n_vads;
	    if (N_vads + inc > MAX_N_VADS)	/* new rec override old rec */
		N_vads = MAX_N_VADS - inc;
	}
	prev_latest = -2;
//printf ("tmp_rec %d   N_vads %d  Latest_vad %d\n", tmp_rec, N_vads, Latest_vad);
	return (0);
    }

    elev = vdv->elev;
    if (vdv->elev < .3f)
	vdv->elev = .3f;

    log_vad = 0;
//    if (tmp_rec < 0 && Test_mode)
//	log_vad = 1;
//extern int dbg;
//if (dbg) log_vad = 1;

    if (prev_latest >= -1) {
	int inc = Latest_vad - prev_latest;
	if (inc < 0)
	    inc += MAX_N_VADS;
	Latest_vad = prev_latest;
	N_vads = prev_n_vads;
	if (N_vads + inc > MAX_N_VADS)	/* new rec override old rec */
	    N_vads = MAX_N_VADS - inc;
    }
    prev_n_vads = N_vads;
    prev_latest = Latest_vad;
//printf ("tmp_rec %d   N_vads %d  Latest_vad %d\n", tmp_rec, N_vads, Latest_vad);

    Ew_struct_t *ew = &(vdv->ew);
    for (int i = 0; i < ew->n_rgs; i++) {
	ew->rfs[i] &= ~RF_VAD_FAILED;
    }

    N_vsas = 0;
    cselev = cos ((double)vdv->elev * deg2rad);
    min_h = 200.;		/* data below this is not used */
    rst = VDV_alt_to_range (vdv, min_h);
    Set_vad_nonunif (vdv, -1, 0.f);
    while (1) {
	Vad_result_t vad;
	int st_ind, next, w, ret, st_i;
	Vad_t *cr_vad;
	char buf[256];
	double h, t;
//extern int dbg;

	h = VDV_range_to_alt (vdv, rst);
	w = (VDV_alt_to_range (vdv, h + Get_delta_h (h)) - rst) / vdv->g_size;
	st_ind = rst / vdv->g_size;
	st_i = Get_next_vad_range (vdv, st_ind, w);
	if (st_i == -2) {	/* not data between st_ind and st_ind + w */
	    rst = (st_ind + w) * vdv->g_size;
	    continue;
	}
	if (st_i < 0)
	    break;

	rst = st_i * vdv->g_size;
	h = VDV_range_to_alt (vdv, rst);
	w = (VDV_alt_to_range (vdv, h + Get_delta_h (h)) - rst) / vdv->g_size;
	if (st_i + w > vdv->xz)
	    w = vdv->xz - st_i;
	rst = (st_i + w * 2 / 3 + 1) * vdv->g_size;	/* partial overlap */
	ret = Two_phase_vad (vdv, st_i, w, &vad);
	if (ret < 0) {
	    int r = st_i;
	    while (r < st_i + w) {
		ew->rfs[r / ew->rz] |= RF_VAD_FAILED;
		r += ew->rz;
	    }
	}
	if (ret == -1) {
	    if (log_vad)
		MISC_log ("VAD: (R %d w %d) failed\n", st_i, w);
//if (dbg) MISC_log ("VAD: (R %d w %d) failed\n", st_i, w);
	    continue;
	}
	if (log_vad) {
	    double r = (st_i + w / 2) * vdv->g_size;
	    sprintf (buf, "R %4d w %3d e %4.1f h %5.0f az %5.1f sp %5.1f rms %.1f %.1f",
		st_i, w, vdv->elev, VDV_range_to_alt (vdv, r),
			vad.dir, vad.speed, vad.rms, vad.rms1);
	    if (ret == -2)
		MISC_log ("BV2: %s\n", buf);
	    else if (ret == -3)
		MISC_log ("BV3: %s\n", buf);
	    else
		MISC_log ("VAD: %s\n", buf);
	}
	if (ret == -2) {
	    Set_vad_nonunif (vdv, st_i, 100.f);
	    continue;
	}

	next = (Latest_vad + 1) % MAX_N_VADS;
	if (tmp_rec < 0)
	    V_sign_analysis (vdv, &vad, next, st_i, w);

	cr_vad = Vads + next;
	cr_vad->rms = vad.rms;
	cr_vad->dtm = vdv->dtm;
	if (ret == -3)		/* invalidate this record - for fca only */
	    cr_vad->dtm = 0;
	cr_vad->range = (st_i + w / 2) * vdv->g_size;
	cr_vad->alt = VDV_range_to_alt (vdv, (double)cr_vad->range);
	t = (ERE + cr_vad->alt) / (cselev * ERE);
	cr_vad->u = vad.CF2 * t;
	cr_vad->v = vad.CF3 * t;
	cr_vad->vol_num = vdv->vol_num;
	cr_vad->cut_num = vdv->cut_num;
	cr_vad->elev = vdv->elev * 10. + .5;
//if (dbg) Print_vad_sample ("  VADS", cr_vad);

	if (N_vads < MAX_N_VADS)
	    N_vads++;

	Set_vad_nonunif (vdv, st_i, vad.rms);
	Latest_vad = next;
    }
    Set_vad_nonunif (vdv, -3, 0.f);

    Set_vertical_shear_flag (vdv);
    if (tmp_rec < 0)
	Vs_full_cut_analysis (vdv);

    if (log_vad) {
	int i;
	for (i = 1; i < 40; i++) {
	    char buf[256];
	    int a;
	    double speed, azi, ls, la;
	    if (i <= 6)
		a = i * 500;
	    else
		a = (i - 3) * 1000;
	    if (a > 14000)
		break;

	    if (Get_vad_wind (vdv, (double)a, 0., 0, &speed, &azi) < 0) {
		if (a < 3000)
		    sprintf (buf, "    Alt %d:  EW not available", a);
	    }
	    else
		sprintf (buf, "    Alt %5d:  spd %.1f  azi %.1f",
							a, speed, azi);
	    if (Get_vad_wind (vdv, (double)a, 200000., 0, &ls, &la) >= 0 &&
		(speed != ls || azi != la))
		sprintf (buf + strlen (buf), "    R200K spd %.1f  azi %.1f",
							ls, la);
	    MISC_log ("%s\n", buf);
	}
    }
    vdv->elev = elev;

    return (0);
}

/***************************************************************************

    Searches for the next section of range for VAD analysis started at
    range "st_ind". "width" is the section width. Returns the begining
    range of the section on success, -1 on failure or -2 if the begining
    range is beyond st_ind + width. To qualify for a section, two third
    of the ranges in the section must have available data covering at
    lease 60 degrees (less if DBZ is high); Data gaps must be small; The
    first range must be data available.

***************************************************************************/

static int Get_next_vad_range (Vdeal_t *vdv, int st_ind, int width) {
    int r, cnt, gcnt, gapcnt, min_n_data, maxgap;
    short *hz_cnt;

    hz_cnt = PP_get_hz_cnt ();
    min_n_data = Myround (60. / vdv->gate_width);
    r = st_ind - 1;
    cnt = 0;
    gcnt = 0;
    gapcnt = 0;
    maxgap = width / 10;
    if (maxgap < 2)
	maxgap = 2;
    while (1) {
	int c, y;
	short *sp;

	r++;
	if (r > st_ind + 5 * width / 2)
	    return (-2);
	if (r >= vdv->xz)
	    return (-1);
	sp = vdv->out + r;
	c = 0;
	for (y = 0; y < vdv->yz; y++) {
	    if (*sp != SNO_DATA)
		c++;
	    sp += vdv->xz;
	}
	if (hz_cnt != NULL && hz_cnt[r] < c)
	    c += hz_cnt[r];
	else
	    c = c * 2;
	if (c >= min_n_data) {
	    gcnt++;
	    if (gapcnt > 0)
		gapcnt--;
	}
	else {
	    gapcnt += 2;
	    if (gapcnt > maxgap * 2) {	/* large gap is not allowed */
		if (gcnt * 3 > width * 2)
		    return (r - cnt + 1);
		gcnt = cnt = gapcnt = 0;
	}
	}
	if (gcnt > 0)
	    cnt++;
	if (cnt >= width) {
	    return (r - cnt + 1);
	}
    }
}

/***************************************************************************

    Performes VAD analysis on vdv->out of nr range gates starting with range
    "nst". The result is returned with the last 4 arguments. The speed it
    horizontal (assuming no vertical wind). It returns 0 on success or -1 
    on failure.

***************************************************************************/

int VDV_basic_vad (Vdeal_t *vdv, int rst, int nr, double *c0,
				double *spd, double *dir, double *rms) {
    Vad_result_t vad;
    int n_vr, n_vad, max;
    short *vrs, *azis;
    double cselev, alt, t;

    Get_data_buffer (vdv->yz, &vrs, &azis);
    n_vr = Get_averaged_data (vdv, rst, nr, vrs, azis, 0, &max);
    n_vad = Process_data (vdv, n_vr, 30, vrs, azis);
    if (n_vad == 0)
	return (-1);

    if (Vad_analysis (vrs, azis, n_vad, &vad) < 0) {
//    if (Two_phase_vad (vdv, rst, nr, &vad) < 0) {
	MISC_log ("    Vad_analysis failed\n");
	return (-1);
    }

    cselev = cos ((double)vdv->elev * deg2rad);
    alt = VDV_range_to_alt (vdv, (rst + nr / 2) * vdv->g_size);
    t = (ERE + alt) / (cselev * ERE);
    *c0 = vad.CF1;
    *spd = vad.speed * t;
    *dir = vad.dir;
    *rms = vad.rms;
    return (0);
}

/***************************************************************************

    Compares two winds (spd, dir) and (spd1, dir1) and returns 0 if the two 
    winds are close for verifying VAD and external wind purpose, or 1 
    otherwise. Two winds are considered as close if their difference in 
    the (u, v) coordinate system is small or the difference between the
    their directions is small.

***************************************************************************/

static int Wind_differ (Vdeal_t *vdv, double dir, double spd, 
						double dir1, double spd1) {
    double u, v, u1, v1, sdf, df;

//MISC_log ("  spd %5.0f dir %5.0f     spedd %5.0f dir %5.0f\n", spd, dir, spd1,dir1);
    u = spd * cos ((90. - dir) * deg2rad);
    v = spd * sin ((90. - dir) * deg2rad);
    u1 = spd1 * cos ((90. - dir1) * deg2rad);
    v1 = spd1 * sin ((90. - dir1) * deg2rad);
    sdf = sqrt ((u - u1) * (u - u1) + (v - v1) * (v - v1));
//MISC_log ("  spd uv df %5.0f\n", sdf);
    if (sdf <= 5. * vdv->data_scale)	/* 5 m/s */
	return (0);
    df = dir - dir1;
    while (df > 180.)
	df -= 360;
    while (df < -180.)
	df += 360;
//MISC_log ("  ext dir df %5.0f\n", df);
    if (df < 0.)
	df = -df;
    if (df <= 60.)			/* 60 degrees */
	return (0);
    return (1);
}

/***************************************************************************

    Varifies the free atmosphere wind (FAW) of VAD and the external wind
    is consistent with (speed horizontal, dir). If VAD is not, all VAD
    samples of the FAWs are removed. The new wind is added to VAD. If
    the external wind is not, it is marked as not usable until it is
    updated. Returns 1 if some wind is modified, 0 otherwise.

***************************************************************************/

int VDV_modify_FAW (Vdeal_t *vdv, double speed, double dir, 
					double min_alt, double max_alt) {
    int i, next, vad_bad, ext_bad, ext_cnt, prev_extw_v;
    double au, av;

//printf ("min_alt %5.0f, max_alt %5.0f\n", min_alt, max_alt);
    prev_extw_v = Extw_verified;
    vad_bad = 0;
    if (Extw_verified == -1)
	Extw_verified = 0;	/* allow Get_ext_wind to return value */
    for (i = VDV_free_atmo_l + 500; i <= VDV_free_atmo_h; i += 1000) {
	double alt, sd, dr;
	int ret;

	alt = i;
	if (alt < min_alt || alt > max_alt)
	    continue;
	ret = Get_vad_wind (vdv, alt, 1000., 2, &sd, &dr);
	if (ret < 0)
	    continue;
	if (Wind_differ (vdv, dr, sd, dir, speed))
	    vad_bad = 1;
    }
//    if (vdv->low_prf) vad_bad = 0;  // my final version
    vad_bad = 0;  //040319 baseline B19

    ext_bad = -1;
    ext_cnt = 0;
    au = av = 0.;
    for (i = VDV_free_atmo_l + 500; i <= VDV_free_atmo_h; i += 1000) {
	double alt, sd, dr, alfa;
	int ret;

	alt = i;
	if (alt < min_alt || alt > max_alt)
	    continue;
	ret = Get_ext_wind (vdv, alt, &sd, &dr, NULL);
	if (ret < 0)
	    continue;
//MISC_log ("  alt %d    ext wind spd %5.0f  dir %5.0f\n", i, sd, dr);
	alfa = (90. - dr) * deg2rad;
	au += sd * cos (alfa);
	av += sd * sin (alfa);
	ext_cnt++;
    }
    if (ext_cnt > 0) {
	double dr, sd;

	au /= ext_cnt;
	av /= ext_cnt;
	sd = sqrt (au * au + av * av);
	dr = 90. - atan2 (av, au) * rad2deg;
	if (Wind_differ (vdv, dr, sd, dir, speed))
	    ext_bad = 1;
	if (ext_bad < 0)
	    ext_bad = 0;
    }

    if (vad_bad) {
	Vad_t *vad;
	double alfa;

//MISC_log ("Modifying free atmo VAD  spd %5.0f  dir %5.0f\n", speed, dir);
	/* remove all FA wind VAD records */
//MISC_log ("    Before N_vads %d Latest_vad %d\n", N_vads, Latest_vad);
	VDV_vad_analysis (vdv, 0);
//MISC_log ("    After N_vads %d Latest_vad %d\n", N_vads, Latest_vad);
	for (i = 0; i < N_vads; i++) {
	    int ind;
	    ind = (Latest_vad - i + MAX_N_VADS) % MAX_N_VADS;
	    vad = Vads + ind;
	    if (vad->alt > (float)VDV_free_atmo_l - 1000)
//{
//double dir, spd;
//Calculate_speed ((double)vad->u, (double)vad->v, &dir, &spd);
//MISC_log ("        Discard VAD alt %5.0f  dir %5.0f  speed %5.0f\n", vad->alt, dir * rad2deg, spd); 
		vad->dtm = 0;
//}
	}
    
	/* add the new FA wind VAD record */
	next = (Latest_vad + 1) % MAX_N_VADS;
	vad = Vads + next;
	vad->rms = 1.f;
	vad->dtm = vdv->dtm;
	vad->range = VDV_alt_to_range (vdv, VDV_free_atmo_l + 500.);
	vad->alt = VDV_free_atmo_l + 500.;
	alfa = (180. - dir) * deg2rad;
	vad->u = speed * cos (alfa);
	vad->v = speed * sin (alfa);
	vad->vol_num = vdv->vol_num;
	vad->cut_num = vdv->cut_num;
	vad->elev = vdv->elev * 10. + .5;
	if (N_vads < MAX_N_VADS)
	    N_vads++;
	Latest_vad = next;
/*d
MISC_log ("Varification:\n");
for (i = 3500; i <= 9500; i += 1000) {
    double alt, sd, dr;
    int ret;

    alt = i;
    ret = Get_vad_wind (vdv, alt, 1000., 2, &sd, &dr);
    if (ret < 0)
	continue;
    MISC_log ("alt %d     spd %5.0f  dir %5.0f\n", i, sd, dr);
}
for (i = 0; i < N_vads; i++) {
    int ind;
    double dir, spd;
    ind = (Latest_vad - i + MAX_N_VADS) % MAX_N_VADS;
    vad = Vads + ind;
    if (vad->dtm == 0)
    continue;
    Calculate_speed ((double)vad->u, (double)vad->v, &dir, &spd);
//    MISC_log ("        VAD ind %d alt %5.0f  dir %5.0f  speed %5.0f  V %d C %d\n", ind, vad->alt, dir * rad2deg, spd, vad->vol_num, vad->cut_num); 
}
*/
    }

    if (Vad_verified != 1)
	MISC_log ("VAD wind is set to good by verification\n");
    Vad_verified = 1;
    Vad_vt = vdv->dtm;

    if (ext_bad == 1) {
	if (prev_extw_v != -1)
	    MISC_log ("External wind is set to bad by verification\n");
	Extw_verified = -1;
	Extw_vt = vdv->dtm;
//MISC_log ("$  External wind is set to bad by verification\n");
    }
    else if (ext_bad == 0) {
	if (prev_extw_v != 1)
	    MISC_log ("External wind is set to good by verification\n");
	Extw_verified = 1;
	Extw_vt = vdv->dtm;
//MISC_log ("$  External wind is set to good by verification\n");
    }
    else {		/* ext_bad == -1 */
	MISC_log ("External wind not verified - unavailable or no FW wind\n");
    }

    if (vad_bad || (Extw_verified == -1 && prev_extw_v != -1) || 
			(Extw_verified >= 0 && prev_extw_v == -1))
	return (1);
    return (0);
}

/**************************************************************************

    Checks and updates Vad_verified. If the Vad_verified is not good, all
    VAD samples of high altitude is discarded.

**************************************************************************/

int VDV_check_and_update_vads (Vdeal_t *vdv) {
    static int msg_printed_cut = -1;
    int i;

    if (Vad_verified != 0 &&
	(vdv->dtm < Vad_vt || vdv->dtm >= Vad_vt + VAD_EXTW_VERI_VALID_TIME)) {
	MISC_log ("VAD good verification expired\n");
	Vad_verified = 0;
    }

    if (vdv->cut_num != msg_printed_cut) {
	char buf[256];
	msg_printed_cut = vdv->cut_num;
//printf ("  Extw_time %u  vdv->dtm %u   Extw_verified %d Vad_verified %d\n", Extw_time, vdv->dtm, Extw_verified, Vad_verified);
	buf[0] = '\0';
	if (Extw_time == 0)
	    strcpy (buf, "External wind not available");
	else if (Extw_time > 0 &&
		(vdv->dtm < Extw_time - EXTW_VALID_TIME || 
				vdv->dtm > Extw_time + EXTW_VALID_TIME))
	    strcpy (buf, "External wind timed out");
	else if (Extw_verified == -1)
	    strcpy (buf, "External wind verified as bad");
	else if (Extw_verified == -2)
	    strcpy (buf, "External wind has no free atmosp wind");
	else if (Extw_verified == 1)
	    strcpy (buf, "External wind verified as good");
	else 
	    strcpy (buf, "External wind available");
	if (Vad_verified)
	    strcpy (buf + strlen (buf), "; VAD verified as good");
	if (buf[0] != '\0')
	    MISC_log ("%s\n", buf);
    }

    if (Vad_verified == 1 || (vdv->data_type & DT_NEAR_RADAR_STORM))
	return (0);
    if (Extw_verified != 1)
	return (0);

    MISC_log ("Removing FA VAD - External wind is verified as good and VAD is not verified\n");
    for (i = 0; i < N_vads; i++) {
	int ind;
	ind = (Latest_vad - i + MAX_N_VADS) % MAX_N_VADS;
	Vad_t *vad = Vads + ind;
	if (vad->alt >= VDV_free_atmo_l - 500.)
	    vad->dtm = 0;
    }
    return (0);
}

/***************************************************************************

    Performs two-phase VAD analysis on vdv->out. "nr" range gates,
    stating with range index "rst", are used. In the second phase, data 
    differing from that the estimated in first phase by at least 
    (df_thr * rms) are discarded. The result is returned with "vad". 
    Returns 0 on success, -1 if failed in first phase, -2 if failed in second
    phase, -3 if the sample is good for full_cut_analysis but not for VAD.

***************************************************************************/

static int Two_phase_vad (Vdeal_t *vdv, int rst, int nr, Vad_result_t *vad) {
    int n_vr, n_vad, max, ret;
    short *vrs, *azis;

    Get_data_buffer (vdv->yz, &vrs, &azis);
    n_vr = Get_averaged_data (vdv, rst, nr, vrs, azis, 0, &max);
    n_vad = Process_data (vdv, n_vr, 30, vrs, azis);
    if (n_vad == 0)
	return (-1);
    if (Vad_analysis (vrs, azis, n_vad, vad) < 0) {
	MISC_log ("    Vad_analysis failed\n");
	return (-1);
    }
    vad->rms1 = vad->rms;

    n_vr = Get_averaged_data (vdv, rst, nr, vrs, azis, 
				(int)(1.f * vad->rms), NULL);
    n_vad = Process_data (vdv, n_vr, 30, vrs, azis);
    if (n_vad == 0)
	return (-2);
    if (Vad_analysis (vrs, azis, n_vad, vad) < 0) {
	MISC_log ("    Vad_analysis failed\n");
	return (-2);
    }
    ret = Check_vad (vdv, vad, max, rst);
    if (ret == 2)
	return (-3);
    else if (ret == 0)
	return (-2);

    return (0);
}

/***************************************************************************

    Performs VAD analysis on array of radial velocities "vr", at "azi" (in 
    .1 degrees), of n_vr points. The results are put in "out". Upon return
    data in "vr" is replaced by estimated radial velocity. Returns 0 on
    success of -1 on failure.

***************************************************************************/

static int Vad_analysis (short *vr, short *azi, int n_vr, Vad_result_t *out) {
    double ator, Q0r, Q1r, Q1i, Q2r, Q2i, Q3r, Q4r, Q5r, Q3i, Q4i, Q5i;
    double q4a, t, qq1r, qq1i, rr, ii, qq_int, int_cr, int_ci, CF3, CF2, CF1;
    double dw, speed, rms;
    int i;

    if (n_vr <= 0)
	return (-1);

    ator = .1 * deg2rad;
    Q3r = Q3i = 0.;
    Q4r = Q4i = 0.;
    Q5r = Q5i = 0.;
    Q0r = 0.;
    for (i = 0; i < n_vr; i++) {
	double a, v, sa, ca, sa2, ca2;

	v = (double)vr[i];
	a = (double)azi[i] * ator;
	sa = sin (a);
	ca = cos (a);
	sa2 = sin (a * 2.);
	ca2 = cos (a * 2.);
	Q3r += ca * v;
	Q3i += sa * v;
	Q4r += ca;
	Q4i += sa;
	Q5r += ca2;
	Q5i += sa2;
	Q0r += v;
    }
    Q0r = Q0r / n_vr;
    Q3r = Q3r / n_vr;
    Q3i = -Q3i / n_vr;
    Q4r = Q4r / (n_vr * 2);
    Q4i = Q4i / (n_vr * 2);
    Q5r = Q5r / (n_vr * 2);
    Q5i = -Q5i / (n_vr * 2);

    q4a = Q4r * Q4r + Q4i * Q4i;
    t = q4a - .25;		/* no enough v points */
    if (t < 0.)
	t = -t;
    if (t <= 1.e-20) {
	MISC_log ("(q4a - .25) too small\n");
	return (-1);
    }
    qq1r = Q4r / (q4a - .25);
    qq1i = -Q4i / (q4a - .25);

    C_mul (1. / (2. * q4a), Q5r, Q5i, Q4r, Q4i, &rr, &ii);
    rr = Q4r - rr;
    ii = -Q4i - ii;
    C_mul (1., rr, ii, qq1r, qq1i, &Q2r, &Q2i);

    C_mul (1. / (2. * q4a), Q3r, Q3i, Q4r, Q4i, &rr, &ii);
    rr = Q0r - rr;
    ii = 0. - ii;
    C_mul (1., rr, ii, qq1r, qq1i, &Q1r, &Q1i);

    qq_int = 1. - (Q2r * Q2r + Q2i * Q2i);
    t = qq_int;
    if (t < 0.)
	t = -t;
    if (t <= 1.e-20) {
	MISC_log ("qq_int too small\n");
	return (-1);
    }
    qq_int = 1. / qq_int;
 
    C_mul (1., Q2r, Q2i, Q1r, -Q1i, &rr, &ii);
    int_cr = (Q1r - rr) * qq_int;
    int_ci = (Q1i - ii) * qq_int;

    CF3 = int_ci;
    CF2 = int_cr;
    C_mul (1., int_cr, int_ci, Q4r, Q4i, &rr, &ii);
    CF1 = Q0r - 2 * rr;

    /* wind direction - Wind comes towards radar from azimuth dw */
    /* speed and RMS (both in data, vr, units) */
    Calculate_speed (CF2, CF3, &dw, &speed);
    rms = 0.;
    for (i = 0; i < n_vr; i++) {
	double a, v, erv;

	v = (double)vr[i];
	a = (double)azi[i] * ator;
	erv = -cos (a - dw) * speed + CF1;
	t = erv - v;
	rms += t * t;
	vr[i] = Myround (erv);
    }
    rms = sqrt (rms / n_vr);
    out->CF1 = CF1;
    out->CF2 = CF2;
    out->CF3 = CF3;
    out->rms = rms;
    out->speed = speed;
    out->dir = dw * rad2deg;

    return (0);
}

/***************************************************************************

    Complex multiplication.

***************************************************************************/

static void C_mul (double ratio, double r1, double i1, double r2, double i2,
					double *rr, double *ri) {
    *rr = (r1 * r2 - i1 * i2) * ratio;
    *ri = (r1 * i2 + i1 * r2) * ratio;
}

/***************************************************************************

    Calcultes direction and speed of radial velocity from CF2 and CF3.

***************************************************************************/

static int Calculate_speed (double CF2, double CF3, double *dwp, double *spd) {
    double dw;

    if (CF3 == 0. && CF2 == 0.)
	dw = 0.;
    else
	dw = pi - atan2 (CF3, CF2);
    if (dw < 0.)
	dw += 2. * pi;
    if (dw > 2. * pi)
	dw -= 2. * pi;
    *spd = sqrt (CF2 * CF2 + CF3 * CF3);
    *dwp = dw;
    return (0);
}

/**************************************************************************

    vdeal uses file to carry info for task restarting and testing. When 
    there are multiple instances of vdeal running at the same time, each
    instance must has a different file name lable so a different file can 
    be used.

**************************************************************************/

static char *Instance_label = "";

void VDV_set_instance_label (char *label) {
    Instance_label = label;
}

static char *Get_hist_file_name (int ops, char *fname, int fname_sz) {
    if (ops == -1) {
	if (VDR_get_image_label () == NULL) {
	    MISC_log ("Can not get data file time stamp\n");
	    return (NULL);
	}
	else
	    sprintf (fname, "%s_history.%s.data", 
			"image", VDR_get_image_label ());
    }
    else if (ops) {
	if (MISC_get_work_dir (fname, fname_sz) < 0 ||
	    strlen (fname) > fname_sz - 32) {
	    MISC_log ("MISC_get_work_dir failed - no VAD history saved\n");
	    return (NULL);
	}
	sprintf (fname + strlen (fname), "/%s_vdeal.history", Instance_label);
    }
    else {
	if (VDR_get_image_label () == NULL) {
	    MISC_log ("Can not get data file time stamp\n");
	    return (NULL);
	}
	else {
	    sprintf (fname, "%s_history.%s.data", 
			Instance_label, VDR_get_image_label ());
	}
    }
    return (fname);
}

/***************************************************************************

    Saves VAD data for task restart in operatinal use (non-test mode) or for
    debugging in test mode.

***************************************************************************/

int VDV_write_history (Vdeal_t *vdv, int ops) {
    char fname[256];
    FILE *fl;
    int cr_dtm, cr_cn, cr_vn, sz;
    char *ew_b_adr;

    if (Get_hist_file_name (ops, fname, 256) == NULL)
	return (0);

    if (ops == 0) {
	struct stat statbuf;
	char buf[252];
	memcpy (buf, fname, 252);
	buf[251] = '\0';
	sprintf (fname, "d/%s", buf);	/* insert dir d */
	MISC_mkdir ("./d");
	if (stat ((const char *)fname, &statbuf) == 0)	/* file exists */
	    MISC_log ("File (%s) exists - overwrite\n", fname);
    }

    if (ops < 0)
	ops = 0;
    if ((fl = fopen (fname, "w")) == NULL) {
	MISC_log ("Can not create vad file (%s)\n", fname);
	if (ops)
	    return (0);
	exit (1);
    }

    cr_dtm = vdv->dtm;
    cr_cn = vdv->cut_num;
    sz = 0;
    if (!ops && (sz = VDR_get_ext_wind (0, -3 , 
				(double *)&ew_b_adr, NULL, NULL)) > 0)
	cr_cn |= 0x10000;
    cr_vn = vdv->vol_num;
    if (fwrite (&N_vads, sizeof (int), 1, fl) != 1 ||
	fwrite (&Latest_vad, sizeof (int), 1, fl) != 1 ||
	fwrite (&cr_dtm, sizeof (int), 1, fl) != 1 ||
	fwrite (&cr_cn, sizeof (int), 1, fl) != 1 ||
	fwrite (&cr_vn, sizeof (int), 1, fl) != 1 ||
	fwrite (&Extw_verified, sizeof (int), 1, fl) != 1 ||
	fwrite (&Extw_vt, sizeof (int), 1, fl) != 1 ||
	fwrite (&Vad_verified, sizeof (int), 1, fl) != 1 ||
	fwrite (&Vad_vt, sizeof (int), 1, fl) != 1 ||
	fwrite (&Extw_time, sizeof (int), 1, fl) != 1 ||
	fwrite (&Extw_dir, sizeof (float), 1, fl) != 1 ||
	fwrite (Vads, sizeof (Vad_t), MAX_N_VADS, fl) != MAX_N_VADS) {
	MISC_log ("Error writing vad\n");
	if (ops) {
	    fclose (fl);	// to satisfy cppcheck. more places in the next
	    return (0);
	}
	exit (1);
    }
    if (!ops) {
	if (fwrite (&Csds, sizeof (S_d_t), 1, fl) != 1 ||
	    fwrite (&Sds, sizeof (S_d_t), 1, fl) != 1) {
	    MISC_log ("Error writing SDS\n");
	    exit (1);
	}
	if (sz > 0 && fwrite (ew_b_adr, 1, sz, fl) != sz) {
	    MISC_log ("Error writing ext ew\n");
	    exit (1);
	}
//if (sz > 0) MISC_log ("ext ew saved %d\n", sz);
    }
    CD_save_gcc (vdv, fl, fname);
    EE_save_data (vdv, fl, fname, ops);
    PP_save_data (vdv, fl, fname);
    fflush (fl);
    fclose (fl);
    return (0);
}

/***************************************************************************

    Reads previously saved VAD data for task restart in operatinal use
    (non-test mode) or for debugging in image mode.

***************************************************************************/

int VDV_read_history (Vdeal_t *vdv, int ops) {
    char fname[256];
    FILE *fl;
    int cr_dtm, cr_cn, cr_vn, latest_vad, n_vads;

    if (Get_hist_file_name (ops, fname, 256) == NULL)
	return (0);

    if ((fl = fopen (fname, "r")) == NULL) {
	MISC_log ("fopen %s failed - No data file read\n", fname);
	return (0);
    }

    if (fread (&n_vads, sizeof (int), 1, fl) != 1 ||
	fread (&latest_vad, sizeof (int), 1, fl) != 1 ||
	fread (&cr_dtm, sizeof (int), 1, fl) != 1 ||
	fread (&cr_cn, sizeof (int), 1, fl) != 1 ||
	fread (&cr_vn, sizeof (int), 1, fl) != 1 ||
	fread (&Extw_verified, sizeof (int), 1, fl) != 1 ||
	fread (&Extw_vt, sizeof (int), 1, fl) != 1 ||
	fread (&Vad_verified, sizeof (int), 1, fl) != 1 ||
	fread (&Vad_vt, sizeof (int), 1, fl) != 1 ||
	fread (&Extw_time, sizeof (int), 1, fl) != 1 ||
	fread (&Extw_dir, sizeof (float), 1, fl) != 1 ||
	fread (Vads, sizeof (Vad_t), MAX_N_VADS, fl) != MAX_N_VADS) {
	MISC_log ("Error read vad file %s\n", fname);
	if (ops) {
	    fclose (fl);
	    return (0);
	}
	exit (1);
    }
    n_vads &= 0xffff;	/* to read old hist file */
    if (n_vads > MAX_N_VADS || latest_vad < -1 || latest_vad >= MAX_N_VADS) {
	MISC_log ("Unexpected VAD data size (%d %d)\n", n_vads, latest_vad);
	if (ops) {
	    fclose (fl);
	    return (0);
	}
	exit (1);
    }

    if (!ops) {
	if (fread (&Csds, sizeof (S_d_t), 1, fl) != 1 ||
	    fread (&Sds, sizeof (S_d_t), 1, fl) != 1) {
	    MISC_log ("Error read Sds from file %s\n", fname);
	    if (ops) {
		fclose (fl);
		return (0);
	    }
	    exit (1);
	}
	if (cr_cn & 0x10000) {
	    char *ew_b_adr;
	    int sz = VDR_get_ext_wind (0, -3, NULL, NULL, NULL);
	    ew_b_adr = MISC_malloc (sz);
	    if (fread (ew_b_adr, 1, sz, fl) != sz) {
		MISC_log ("Error read ext ew from file %s\n", fname);
		if (ops) {
		    fclose (fl);
		    return (0);
		}
		exit (1);
	    }
	    VDR_get_ext_wind (0, -4, (double *)ew_b_adr, NULL, NULL);
	    MISC_log ("ext ew read %d bytes\n", sz);
//MISC_log ("ext ew read - but not used for testing\n");
//free (ew_b_adr);
	}
    }

    N_vads = n_vads;
    Latest_vad = latest_vad;
    vdv->vol_num = cr_vn;
    if (!ops) {
	vdv->dtm = cr_dtm;
	vdv->cut_num = cr_cn & 0xffff;
    }
    CD_read_gcc (vdv, fl, fname);
    EE_read_data (vdv, fl, fname, ops);
    PP_read_data (vdv, fl, fname);

    fclose (fl);
    return (1);
}

/***************************************************************************

    Returns data buffers vrs and azis for vad analysis. These buffers must
    be of at least size shorts.

***************************************************************************/

static void Get_data_buffer (int size, short **vrs, short **azis) {
    static short *buf = NULL;

    buf = (short *)STR_reset ((char *)buf, 2 * size * sizeof (short));
    *vrs = buf;
    *azis = buf + size;
}

/*d static int Print_samples (Vad_t *vt) {
    double u, v, dir, spd;
    u = vt->u;
    v = vt->v;
    Calculate_speed (u, v, &dir, &spd);
    MISC_log ("    Sample: alt %.1f, spd %.1f, azi %.1f\n", vt->alt, spd, dir / deg2rad);
} */

/**************************************************************************

    Computes interpolation wibd on "n_samples" VAD samples stored in
    "smp_inds" at altitude "talt". The result is put in "u" and "v". We
    use linear interpolation to remove outliers.

**************************************************************************/

static int Get_interpolate_wind (int n_samples, short *smp_inds, 
				double talt, double *u, double *v) {
    double min, max, alt[MAX_N_VADS], y[MAX_N_VADS], b, c;
    double rms, max_rms2, rms2[MAX_N_VADS], diff, r;
    int i, cnt;

    if (n_samples <= 0)
	return (-1);

    for (i = 0; i < n_samples; i++) {
	Vad_t *vad = Vads + smp_inds[i];
	alt[i] = vad->alt;
	y[i] = vad->u;
//Print_samples (vad);
    }
    VDB_linear_fit (n_samples, alt, y, &b, &c);
    for (i = 0; i < n_samples; i++) {
	diff = b * alt[i] + c - y[i];
	rms2[i] = diff * diff;
    }

    for (i = 0; i < n_samples; i++) {
	Vad_t *vad = Vads + smp_inds[i];
	y[i] = vad->v;
    }
    VDB_linear_fit (n_samples, alt, y, &b, &c);
    rms = 0.;
    for (i = 0; i < n_samples; i++) {
	diff = b * alt[i] + c - y[i];
	rms2[i] += diff * diff;
	rms += rms2[i];
    }
    if (n_samples <= 10)	/* rm less outliers when n_samples is small */
	r = 2.0;
    else 
	r = 1.5;
    max_rms2 = r * r * (rms / n_samples);	/* (r * STD) ** 2 */

    min = 1.e10;
    max = -min;
    cnt = 0;
    for (i = 0; i < n_samples; i++) {
	Vad_t *vad = Vads + smp_inds[i];
	if (rms2[i] > max_rms2)	{		/* remove outlier */
//MISC_log ("Outlier removed (rms2 %.1f, max %.1f): i %d, alt %.0f\n", rms2[i], max_rms2, i, alt[i]);
	    continue;
	}
	alt[cnt] = vad->alt;
	y[cnt] = vad->u;
	if (alt[cnt] > max)
	    max = alt[cnt];
	if (alt[cnt] < min)
	    min = alt[cnt];
	cnt++;
    }
    VDB_linear_fit (cnt, alt, y, &b, &c);

    if (talt > max)
	talt = max;
    if (talt < min)
	talt = min;
    *u = b * talt + c;

    cnt = 0;
    for (i = 0; i < n_samples; i++) {
	Vad_t *vad = Vads + smp_inds[i];
	if (rms2[i] > max_rms2)			/* remove outlier */
	    continue;
	y[cnt] = vad->v;
	cnt++;
    }
    VDB_linear_fit (cnt, alt, y, &b, &c);

    *v = b * talt + c;
    return (0);
}

/**************************************************************************

    Checks if a wind sample (VAD or Extern wind) of altitude "sa" is too
    far to be useful for target altitude "alt". Returns 1 if too far or
    0 otherwise. "ar" returns the sample available range. We allow large
    altitude range in free atmosphere (above where the wind changes
    slowly.

**************************************************************************/

static int Sample_too_far (double sa, double alt, double *ar) {
    double fa_alt, t, r;

    fa_alt = VDV_free_atmo_l + 500;	/* lower end of the free atmos */
    t = sa;
    if (sa < 0.)
	t = 0;
    if (t > fa_alt)
	t = fa_alt;
    r = 350. + t * 800. / fa_alt;	/* available altitude range */
    if (ar != NULL)
	*ar = r;
    if (sa < alt) {
	if (sa < fa_alt - r && sa < alt - r)	/* sample too low */
	    return (1);
    }
    else {
	if (alt < fa_alt && sa > alt + r)	/* sample too high */
	    return (1);
    }
    return (0);
}

/**************************************************************************

    Check Vads for stored data prior to current volume. Set data_type
    flag for no history if none is found, or remove the no history flag
    if history is found.

**************************************************************************/
void VDV_check_data_history (Vdeal_t *vdv) {
    int cr_dtm, cr_vol, cnt, i;

    cr_dtm = vdv->dtm;
    cr_vol = vdv->vol_num;
    cnt = 0;
    for (i = 0; i < N_vads; i++) {
	Vad_t *vad;

	int ind = (Latest_vad - i + MAX_N_VADS) % MAX_N_VADS;
	vad = Vads + ind;
	if (vad->dtm == 0 || 
		vad->dtm > cr_dtm || vad->dtm + Vad_age < cr_dtm || 
		vad->vol_num < cr_vol - 1 || vad->vol_num == cr_vol)
	    continue;
	cnt++;
    }
    if (cnt == 0) {
	vdv->data_type |= DT_NO_HIST;
	if (vdv->cut_num == 0)	/* reset nonuniform_vol when new case starts */
	    vdv->nonuniform_vol = 0;
    }
    else
	vdv->data_type &= ~DT_NO_HIST;
}

/***************************************************************************

    Calculates and returns the VAD-based wind estimate at altitude "alt" and
    range "range". Returns 0 on sucess or -1 if the estimate is not available.
    if "range" < 0, u and v, instead of speed and direction, are rtruned.
    If both_side is 1, VAD samples from both side must be available. If
    both_side is 2, the available altitude range check is applied to vad
    samples.

***************************************************************************/

#define MAX_N_ELEVS 64

static int Get_vad_wind (Vdeal_t *vdv, double alt, double range, int both_side,
					double *speed, double *azip) {
    double u, v, dir, spd, r_min, u_min, l_max;
    short smps[MAX_N_VADS], uels[MAX_N_ELEVS];
    int cr_dtm, cr_vol, cr_cut, cnt, n_uels, i, rcnt, ucnt;
//extern int dbg;
//int dbg1;

//dbg1 = 0;
//if (dbg && alt > 3000. && alt < 6000.) dbg1 = 1;
/*d if (alt == 12000. || alt == 500.) {
MISC_log ("Get_vad_wind  range %f\n", range);
dbg = 1;
} */
//if (dbg1) MISC_log ("call Get_vad_wind both_side %d alt %4.1f vol %d\n", both_side, alt, vdv->vol_num);
    r_min = VDV_alt_to_range (vdv, 4000.);	/* 4000 m altitude */
    if (r_min < 100000.)
	r_min = 100000.;	/* min value for far range (in meters) */
    cr_dtm = vdv->dtm;
    cr_vol = vdv->vol_num;
    cr_cut = vdv->cut_num;
    cnt = n_uels = rcnt = ucnt = 0;
    for (i = 0; i < N_vads; i++) {
	int ind, k, cut, ci, vn, lowind, upind;
	double up, low;
	Vad_t *vad;

	ind = (Latest_vad - i + MAX_N_VADS) % MAX_N_VADS;
	vad = Vads + ind;
//Print_vad_sample ("  VADS", vad);
	if (vad->dtm == 0)	/* discarded record */
	    continue;
	if (vad->dtm > cr_dtm || vad->dtm + Vad_age < cr_dtm || 
					vad->vol_num < cr_vol - 1)
	    break;		/* invalid sample */

	if ((vdv->data_type & DT_NONUNIFORM) && vdv->phase == 2 && 
						vad->cut_num != cr_cut)
	    continue;		/* we do not use VAD from other cuts */
	for (k = 0; k < n_uels; k++) {
	    int diff = vad->elev - uels[k];
	    if (diff < 0)
		diff = -diff;
	    if (diff <= 3)
		break;
	}
	if (k < n_uels)		/* the same elev has been used */
	    continue;
	if (n_uels <= MAX_N_ELEVS) {
	    uels[n_uels] = vad->elev;
	    n_uels++;
	}

	cut = vad->cut_num;
	vn = vad->vol_num;
	ci = i;
	upind = lowind = -1;
	up = 1.e10;
	low = -up;
//if (dbg1) MISC_log ("    search vol %d cut %d  - i %d\n", vn, cut, i);
	while (ci < N_vads) {	/* search two samples in the cut */
	    double a;
	    ind = (Latest_vad - ci + MAX_N_VADS) % MAX_N_VADS;
	    vad = Vads + ind;
	    if (vad->dtm == 0) {
		ci++;
		continue;
	    }
	    if (vad->cut_num != cut || vad->vol_num != vn)
		break;
	    a = vad->alt;
	    if (a >= alt && a < up) {
		upind = ind;
		up = a;
	    }
	    if (a < alt && a > low) {
		lowind = ind;
		low = a;
	    }
	    ci++;
	}
	if (lowind >= 0) {
	    smps[cnt] = lowind;
//if (dbg1) Print_vad_sample ("$ VADS low  ", Vads + smps[cnt]);
	    cnt++;
	}
	if (upind >= 0) {
	    smps[cnt] = upind;
//if (dbg1) Print_vad_sample ("$ VADS up   ", Vads + smps[cnt]);
	    cnt++;
	    ucnt++;
	}
	i = ci - 1;
    }
    if (cnt <= 0)
	return (-1);
    if (both_side == 1 && (ucnt * 5 < cnt || (cnt - ucnt)  * 5 < cnt))
	return (-1);

    u_min = 1.e10;		/* prepare for removing far samples */
    l_max = -u_min;
    for (i = 0; i < cnt; i++) {
	double a = Vads[smps[i]].alt;
	if (a < alt && a > l_max)
	    l_max = a;
	if (a >= alt && a < u_min)
	    u_min = a;
    }
//if (dbg1) MISC_log ("%d samples   up %f  low %f\n", cnt, u_min, l_max);

    {				/* remove samples that are too far */
	int c = 0;
	for (i = 0; i < cnt; i++) {
	    int sample_too_far;
	    double a, r;

	    a = Vads[smps[i]].alt;
	    sample_too_far = Sample_too_far (a, alt, &r);
	    if (both_side == 2) {	/* discard any far away samples */
		if (sample_too_far)
		    continue;
	    }
	    else {	/* discard those too far away beyond available ones */
		if (a < alt && a < l_max - r)  	/* sample too low */
		    continue;
		if (a >= alt && a > u_min + r)	/* sample too high */
		    continue;
	    }
	    smps[c] = smps[i];
	    c++;
	}
//if (dbg) MISC_log ("                      cnt %d -> %d\n", cnt, c);
	cnt = c;
	if (cnt == 0)
	    return (-1);
    }

    Get_interpolate_wind (cnt, smps, alt, &u, &v);
    if (range < 0.) {
	*speed = u;
	*azip = v;
	return (1);
    }
    Calculate_speed (u, v, &dir, &spd);
//if (dbg1) MISC_log ("dir %f   spd %f\n", dir * rad2deg, spd);

    if (range >= r_min) {		/* try to use the long range VADs */

	int c = 0;
	for (i = 0; i < cnt; i++) {	/* discard short range samples */
	    if (Vads[smps[i]].range < r_min)
		continue;
	    smps[c] = smps[i];
	    c++;
	}
	if (c > 1 && Get_ra_interp_wind (c, smps, alt, range, &u, &v) == 0) {
	    double d, s, dd, sd;

	    Calculate_speed (u, v, &d, &s);
	    dd = (d - dir) * rad2deg;	/* quality control */
	    while (dd > 180.)
		dd -= 360.;
	    while (dd < -180.)
		dd += 360.;
	    if (dd < 0.)
		dd = -dd;
	    sd = s - spd;
	    if (sd < 0.)
		sd = -sd;
	    if (dd <= 20. && (sd < spd * .2 || sd < 10.)) {
		spd = s;		/* use long range VAD */
		dir = d;
	    }
	}
    }

    *speed = spd;
    *azip = dir * rad2deg;
    return (1);
}

/***************************************************************************

    Computes the estimated VAD value at "range" and "alt" using linear
    VAD interpolation on the domain of (alt, range) of "cnt" samples of
    indeces "smps". The results are returned with "up" and "vp". Returns
    0 on sucess or -1 if the estimate is not available. If the 2d
    interpolation is not possible, 1d interpolation on altitude is used.

***************************************************************************/

static int Get_ra_interp_wind (int cnt, short *smps,
			double alt, double range, double *up, double *vp) {
    double mina, maxa, maxru, maxrl, minru, minrl, ua, ub, uc, va, vb, vc;
    double u[MAX_N_VADS], v[MAX_N_VADS], rg[MAX_N_VADS], al[MAX_N_VADS];
    int i, maxrui, maxrli, maxai, minai, minrui, minrli;

    mina = minru = minrl = 1.e10;
    maxa = maxru = maxrl = -1.e10;
    maxrui = maxrli = minrui = minrli = maxai = minai = -1;
    for (i = 0; i < cnt; i++) {
	Vad_t *vad = Vads + smps[i];
	u[i] = vad->u;
	v[i] = vad->v;
	al[i] = vad->alt;
	rg[i] = vad->range;
	if (al[i] < mina) {
	    mina = al[i];
	    minai = smps[i];
	}
	if (al[i] > maxa) {
	    maxa = al[i];
	    maxai = smps[i];
	}
	if (vad->alt >= alt) {
	    if (vad->range > maxru) {
		maxru = vad->range;
		maxrui = smps[i];
	    }
	    if (vad->range < minru) {
		minru = vad->range;
		minrui = smps[i];
	    }
	}
	else {
	    if (vad->range > maxrl) {
		maxrl = vad->range;
		maxrli = smps[i];
	    }
	    if (vad->range < minrl) {
		minrl = vad->range;
		minrli = smps[i];
	    }
	}
    }

    /* make sure (alt, range) is within the region covered by samples */
    if (maxrui < 0) {	/* all sampls are below the target altitude */
	Vad_t *vad = Vads + maxai;	/* use that of the highest altitude */
	if (minrli >= 0 && range < (double)Vads[minrli].range)
	    return (-1);	/* minrli >= 0 is to satisfy cppcheck */
	alt = vad->alt;
	range = vad->range;
    }
    else if (maxrli < 0) {	/* all sampls are above the target altitude */
	Vad_t *vad = Vads + minai;	/* use that of the lowest altitude */
	if (range < (double)Vads[minrui].range)
	    return (-1);
	alt = vad->alt;
	range = vad->range;
    }
    else {
	Vad_t *vadu, *vadl;
	double r;
	vadu = Vads + minrui;
	vadl = Vads + minrli;
	r = vadl->range + (vadu->range - vadl->range) * (alt - vadl->alt) /
				(vadu->alt - vadl->alt);
	if (range < vadu->range && range < vadl->range)
	    return (-1);
	if (range < r)
	    range = r;
	vadu = Vads + maxrui;
	vadl = Vads + maxrli;
	r = vadl->range + (vadu->range - vadl->range) * (alt - vadl->alt) /
				(vadu->alt - vadl->alt);
	if (range > r)
	    range = r;
    }

    if (cnt <= 2) {
	Get_interpolate_wind (cnt, smps, alt, up, vp);
	return (0);
    }

    if (Fitting2d (cnt, rg, al, u, &ua, &ub, &uc) < 0 ||
	Fitting2d (cnt, rg, al, v, &va, &vb, &vc) < 0) {
	Get_interpolate_wind (cnt, smps, alt, up, vp);
	return (0);
    }

    *up = ua * range + ub * alt + uc;
    *vp = va * range + vb * alt + vc;
    return (0);
}

/***************************************************************************

    Calculates and returns the external wind estimate at altitude "dalt".
    Returns 0 on sucess or -1 if the estimate is not available.

***************************************************************************/

static int Get_ext_wind (Vdeal_t *vdv, double dalt,
				double *spd, double *dir, unsigned int *tm) {
    double au, al, ad, ad1, spd1, dir1, large;
    int alt;
    unsigned int ewtm;

    ewtm = 0;
    large = 1.e20;		/* a value greater than any altitude */
    alt = Myround (dalt);
    au = VDR_get_ext_wind (alt, 0, spd, dir, &ewtm);
//printf ("  ewtm %u vdv->dtm %u\n", ewtm, vdv->dtm); exit (0);
    if (ewtm == 0 || ewtm > vdv->dtm + 3600 || ewtm + 7200 < vdv->dtm) {
	Extw_time = 0;
	Extw_verified = -2;
	return (-1);	/* ext wind not available */
    }
    if (au < 0 || Sample_too_far (au, dalt, NULL))
	ad = large;
    else
	ad = alt - au;
    if (ad < 0.)
	ad = -ad;
    al = VDR_get_ext_wind (alt, 1, &spd1, &dir1, NULL);
    if (al < 0 || Sample_too_far (al, dalt, NULL))
	ad1 = large;
    else
	ad1 = alt - al;
    if (ad1 < 0.)
	ad1 = -ad1;
    if (ad1 < ad) {		/* use the nearest */
	*spd = spd1;
	*dir = dir1;
	ad = ad1;
    }
    if (tm != NULL)
	*tm = ewtm;
    if (ewtm != Extw_time) {  /* a new external wind received */
	int al;
	double s, d, df;

	al = VDR_get_ext_wind ((VDV_free_atmo_l + VDV_free_atmo_h) / 2,
						0, &s, &d, NULL);
	if (al >= VDV_free_atmo_l) {	/* FW wind found */
	    int pre_ev = Extw_verified;
	    if (Extw_verified == 1 && Extw_dir != BAD_AZI_V) {
		df = d - Extw_dir;
		while (df > 180.)
		    df -= 360.;
		while (df < -180.)
		    df += 360.;
		if (df < 0.)
		    df = -df;
		if (df > 60.)
		    Extw_verified = 0;
		MISC_log ("New external wind received (df %.0f verif %d -> %d)\n", 
					df, pre_ev, Extw_verified);
	    }
	    else {		/* cannot or no need to verify */
		Extw_verified = 0;
		MISC_log ("New external wind received - verified to 0\n");
	    }
	}
	else {			/* no FW wind found in the new data */
	    d = BAD_AZI_V;
	    Extw_verified = -2;
	    MISC_log ("New external wind received - no FA wind\n");
	}
	Extw_time = ewtm;
	Extw_dir = d;
    }

    if ((Extw_verified == 1 || Extw_verified == -1) && 
	(vdv->dtm < Extw_vt || 
			vdv->dtm >= Extw_vt + VAD_EXTW_VERI_VALID_TIME)) {
	MISC_log ("External wind verification expired %d->0\n", Extw_verified);
	Extw_verified = 0;	/* verification expired or playback rewind */
    }

    /* check if the external wind is valid */
    if (ewtm == 0 || Extw_verified < 0 || 
	(Extw_time > 0 && (vdv->dtm < Extw_time - EXTW_VALID_TIME || 
				vdv->dtm > Extw_time + EXTW_VALID_TIME)))
	return (-1);

    *spd *= (double)vdv->data_scale;
    if (ad < large * .99)
	return (0);

    return (-1);
}

/***************************************************************************

    Calculates determinant of 3x3 matrix

***************************************************************************/
static double Determinant3 (double x11, double x12, double x13, double x21,
	double x22, double x23, double x31, double x32, double x33) {
    return (x11 * x22 * x33 + x12 * x23 * x31 + x21 * x32 * x13 -
	x13 * x22 * x31 - x12 * x21 * x33 - x11 * x23 * x32);
}
/***************************************************************************

    Fit the 2d line

***************************************************************************/

static int Fitting2d (int n, double *x, double *y, double *v, double *ap, 
						double *bp, double *cp) {
    double sxx, sxy, syy, sx, sy, sv, sxv, syv, x0;
    double d, a, b, c, ad;
    int i;

    if (n == 0)
	return (-1);

    sxx = sxy = syy = sx = sy = sv = sxv = syv = 0.;
    for (i = 0; i < n; i++) {
	double xx, yy, vv;

	xx = x[i];
	yy = y[i];
	vv = v[i];
	sxx += xx * xx;
	syy += yy * yy;
	sxy += xx * yy;
	sx += xx;
	sy += yy;
	sxv += xx * vv;
	syv += yy * vv;
	sv += vv;
    }
    x0 = (double)n;
    d = Determinant3 (sxx, sxy, sx, sxy, syy, sy, sx, sy, x0);
    ad = d;
    if (ad < 0.)
	ad = -ad;
    if (ad < 1.e-20) {
	*ap = 0.;
	return (-1);
    }
    d = 1. / d;
    a = Determinant3 (sxv, sxy, sx, syv, syy, sy, sv, sy, x0);
    b = Determinant3 (sxx, sxv, sx, sxy, syv, sy, sx, sv, x0);
    c = Determinant3 (sxx, sxy, sxv, sxy, syy, syv, sx, sy, sv);
    *ap = a * d;
    *bp = b * d;
    *cp = c * d;
    return (0);
}
/***************************************************************************

    Calculate delta h (h/5) - cannot be less than 200

***************************************************************************/

static double Get_delta_h (double h) {
	
    double delta_h = h * .2;
    if (delta_h < 200.)
	delta_h = 200.;
    return (delta_h);
}


/***************** V sign analysis ***************************/

typedef struct {
    int st, end, cnt, p, z1, z2;
} Segs_t;

typedef struct {	/* velocity sign analysis record */
    int rs, nr, vad_ind;
    int zc1, zc2;	/* zc1 - ZC after negative v segment */
    int gvsa;		/* vsa goodness: 0 - bad; 1 - weak; 2 - good */
    int vcnt;		/* count of significant v gates */
    int czc;
    float rms, spd, dir;
    short *vs;		/* The avaraged data (v) array */
} Vsa_t;

static Vsa_t *Vsas = NULL;
// static int N_vsas = 0;
static short Vndata = 0x7fff;	/* value for no data of V in V sign analysis */
static int Vscale = 10;		/* V scale factor in V sign analysis */
static int Is_non_uniform_likely (Vdeal_t *vdv, Vsa_t *vsa, int long_rg);

/***************************************************************************

    Performs a full cut analysis of VSA records. The Vsas records are 
    discarded after the function is called. Currently, this function 
    identifies the non-uniform (hurrican) wind. It sets a per-volume flag
    which is reset when a new volume starts in save_storm_distance. The 
    non-uniform range (can be 0) is set if the volume is non-uniform.
    We use Csds for the flag so we do not start a new history version.

***************************************************************************/

static void Vs_full_cut_analysis (Vdeal_t *vdv) {
    int n_rgs, rz, i, nu_st, cnt, last_vad_r, last_vad_alt, bvcnt, nu_range;
    char bvad[MAX_EW_NRS];
    Ew_struct_t *ew;
    int long_rg, v_long_rg;

    if (CD_get_hlw_ranges (vdv, NULL, NULL, -1) ||	/* hlw detected */
	PP_is_front_deteted ()) {		/* front deteccted */
 	N_vsas = 0;				/* remove all VSA records */
	return;
    }

    ew = &(vdv->ew);
    n_rgs = ew->n_rgs;
    rz = ew->rz;
    for (i = 0; i < n_rgs; i++)
	bvad[i] = -1;

    if (N_vsas == 0)
	return;
    long_rg = 700;
    v_long_rg = 900;
    last_vad_r = Vsas[N_vsas - 1].rs + Vsas[N_vsas - 1].nr;
    last_vad_alt = Vads[Vsas[N_vsas - 1].vad_ind].alt;
    bvcnt = 0;	/* bad vsa cnt */
    nu_range = 0;
    for (i = 0; i < N_vsas; i++) {
	float thr;
	int hrms, k, factor;

	Vsa_t *vsa = Vsas + i;
	thr = .16;
	factor = 3;
	if (vsa->rs >= long_rg) {
	    thr = .14;
	    factor = 4;
	    if (vsa->rs >= v_long_rg)
		factor = 6;
	}
	if (vsa->gvsa == 1)
	    thr = .1f;
	hrms = vsa->spd > 20.f && vsa->rms / vsa->spd > thr;
//MISC_log ("i %d   thr %f   vsa->rms / vsa->spd %f  hrms %d  gvsa %d  rs %d  zc1 %d\n", i, thr, vsa->rms / vsa->spd, hrms, vsa->gvsa, vsa->rs, vsa->zc1);
	for (k = 0; k < n_rgs; k++) {
	    int c = k * rz + rz / 2;
	    if (c < vsa->rs || c >= vsa->rs + vsa->nr)
		continue;
	    if (vsa->gvsa == 0) {
		bvad[k] = 2;
	    }
	    else if (hrms && vsa->vcnt * factor >= vdv->yz)
		bvad[k] = 1;		/* plenty of data, RMS still high */
	    else
		bvad[k] = 0;
//	    if (bvad[k] != 2)
//		ew->rfs[k] |= RF_GVSA;
	}

	if (vsa->rs > last_vad_r / 4 &&
				!(ew->rfs[vsa->rs / rz] & RF_CLEAR_AIR)) {
	    if (vsa->gvsa == 0 && i < N_vsas - 1)
		bvcnt++;		/* the last VSA is excluded */
	    if (hrms && vsa->vcnt * factor >= vdv->yz &&
			vsa->gvsa == 2 && 
			Is_non_uniform_likely (vdv, vsa, vsa->rs >= long_rg))
		nu_range += vsa->nr;
	}

/*d	if (vsa->gvsa == 1 && 		discard high RMS VAD 
			vsa->spd > 20.f && vsa->rms / vsa->spd > .1f)
	    Vads[vsa->vad_ind].dtm = 0;	*/
    }

//MISC_log ("    BAD vsa bvcnt %d  nu_range %d\n", bvcnt, nu_range);
    if (last_vad_alt >= 4500 && bvcnt == 0 && nu_range >= 120)
	vdv->nonuniform_vol = vdv->vol_num;
    if (vdv->nonuniform_vol == 0) {
//MISC_log ("  rm all VSA   %d %d %d\n", last_vad_alt, bvcnt, nu_range);
 	N_vsas = 0;				/* remove all VSA records */
	return;
    }

    nu_st = -1;		/* non-uniform wind start */
    cnt = 0;		/* bad vad cnt */
    for (i = last_vad_r / (3 * rz); i < n_rgs; i++) {
	int min_cnt;
	if (bvad[i] < 0) {
	    int k;
	    for (k = i ; k >= 0; k--) {
		if (bvad[k] >= 0)
		    break;
	    }
	    if (i - k > 2 && i * rz < long_rg)
//{
//MISC_log (" data availability is low in range %d  %d\n", i - k, i * rz);
		continue;	/* data availability is low in range */
//}
	}
	if (bvad[i] == 1)
	    cnt++;
	else if (bvad[i] == 0) {
	    if (cnt > 0)
		cnt--;
	}
	else if (bvad[i] == 2)
	    cnt = 0;
//MISC_log (" cnt %d  last_vad_ind %d  nu_st %d\n", cnt, last_vad_r / rz, nu_st);
	min_cnt = 6;
	if (i * rz >= long_rg)
	    min_cnt = 4;
	if (i * rz >= v_long_rg)
	    min_cnt = 2;
	if (cnt >= min_cnt) {
	    nu_st = i - 3;	/* non-uniform start range */
	    break;
	}
    }
//if (Test_mode && !vdv->realtime && nu_st>= 0) MISC_log ("    non-uniform cnt %d  nu_st %d\n", cnt, nu_st);

    if (nu_st >= 0) {
	int k;
	for (k = nu_st; k < n_rgs; k++) {
	    int y;
	    ew->rfs[k] |= RF_NONUNIFORM;
	    for (y = 0; y < ew->n_azs; y++)	/* let ewm LI to cover hurrican
					center where z may be missing */
		ew->efs[y * n_rgs + k] |= EF_STORM;
	}
	Correct_vad_via_zc (vdv, nu_st * ew->rz);
	vdv->data_type |= DT_NONUNIFORM;  /* set non-uniform data cut */
    }

    if (vdv->data_type & DT_NONUNIFORM) {
	Non_uniform_yc = -1;	/* set up this value */
	cnt = 0;/* this function coule be improved by discarding outliers */
	int df_sum = 0;
	int max_df = 0;
	for (i = 0; i < N_vsas; i++) {
	    int adf, df;
	    if (Vsas[i].zc1 < 0)
		continue;
	    if (Non_uniform_yc < 0) {
		Non_uniform_yc = Vsas[i].zc1;
		continue;
	    }
	    adf = VDA_y_diff (vdv, Vsas[i].zc1, Non_uniform_yc, &df);
	    df_sum += df * adf;
	    if (adf > max_df)
		max_df = adf;
	    cnt++;
//printf ("zc1 %d %d   df  %d  df_sum %d\n", Vsas[i].zc1, Non_uniform_yc, df * adf, df_sum);
	}
	if (max_df > 100 || cnt < 5)
	    Non_uniform_yc = -1;
	else {
	    Non_uniform_yc += df_sum / cnt;
	    Non_uniform_yc = (Non_uniform_yc + vdv->yz) % vdv->yz;
	}
//printf ("max_df %d  cnt %d   %d  %d\n", max_df, cnt, df_sum / cnt, Non_uniform_yc);
    }
//    N_vsas = 0;
}

/*****************************************************************************

    Checks if vsa is likely to be a non-uniform wind. This checks the zero
    crossing near near the hurrican center (assumed to be counter clock 
    rotatind): Data well available, high shear near and good linear fit.
    It works well for low evevation cuts.

*****************************************************************************/

#define TMP_DIM 512
static int Is_non_uniform_likely (Vdeal_t *vdv, Vsa_t *vsa, int long_rg) {
    double az[TMP_DIM], v[TMP_DIM], a, b, s2, dwp, spd, factor;
    int w, zc, yz, i, c, r;
    short *vs;

    if (vsa->zc1 < 0)
	return (0);
    zc = vsa->zc1;
    r = vsa->rs;
    yz = vdv->yz;
    w = Myround (40000. / ((double)r * deg2rad * 
			vdv->g_size * vdv->gate_width));  /* 40 km one side */
    if (w * 3 > yz)
	return (0);
    vs = vsa->vs;
    c = 0;
    for (i = -w; i <= w; i++) {
	short d = vs[(zc + i + yz) % yz];
	if (d == Vndata)
	    continue;
	az[c] = i;
	v[c] = d;
	c++;
	if (c >= TMP_DIM)
	    break;
    }
//MISC_log ("     c %d  w %d r %d\n", c, w, r);
    if (c * 2 < w)
	return (0);
    VDB_linear_fit (c, az, v, &a, &b);
    if (a < 0.)
	a = -a;

    factor = 3.;
    if (long_rg)
	factor = 2.;
    Calculate_speed (Vads[vsa->vad_ind].u, Vads[vsa->vad_ind].v, &dwp, &spd);
//MISC_log ("          a %f,  %f\n", a, factor * pi * spd * Vscale / (.5 * yz));
    if (a < factor * pi * spd * Vscale / (.5 * yz))
	return (0);	/* slope is smaller than 3 times uniform wind */

    c = 0;
    s2 = 0.;
    for (i = -w; i <= w; i++) {
	double dif;
	short d = vs[(zc + i + yz) % yz];
	if (d == Vndata)
	    continue;
	dif = a * i + b - d;
	s2 += dif * dif;
	c++;
	if (c >= TMP_DIM)
	    break;
    }
//MISC_log ("                             s2 %f / %f\n", 8. * sqrt (s2 / c) / Vscale, spd);
    if (8. * sqrt (s2 / c) / Vscale > spd)
	return (0);		/* quality of fit is not good */

    return (1);
}

/***************************************************************************

    Corrects VAD using zc info. Correlation based zc is used if possible.
    If zc is not found, the vad is discarded. This is currently seen 
    necessary for hurrican cases. We assume the rotation is always counter-
    clock. A version of the code removes this assumption is in
    vdeal_old_code.c. That code is weaker - it may not be able to currectly
    determine which zc to use. In hurrican case, this funcion is more robust.

    Corr-estd-zc here may hit the segment data (a function for such
    check is in vdeal_old_code.c). I don't have a check. It may be fine
    because data is good and zc is used only for vad correction. I do
    not put corr zc in to Vsas. Another approach may be using immediate
    previous vsa and corr-estd-zc for correlation (Extends one step a
    time. It seemd to work well in one case. I do not have sufficient
    cases for comparison). The corr will be better. We may still need to
    make sure we do not go too far from an original zc.

****************************************************************************/

static void Correct_vad_via_zc (Vdeal_t *vdv, int st_r) {
    int i, cnt;

    cnt = 0;
    for (i = 0; i < N_vsas; i++) {
	int czc;
	double zcazi, alfa;
	Vsas[i].czc = -1;
	if (Vsas[i].rs < st_r)
	    continue;
	czc = Vsas[i].zc1;
	if (czc < 0) {
	    int k, szc;
	    int sind = -1;		/* source vsa for correlation */
	    szc = 0;
	    for (k = i - 1; k >= 0; k--) {
		if (Vsas[k].gvsa == 0)
		    break;
		if ((Vsas[i].rs - Vsas[k].rs) * 3 > Vsas[i].rs)
		    break;		/* too far from the corrent r */
		szc = Vsas[k].zc1;
		if (szc >= 0) {
		    sind = k;
		    break;
		}
	    }
	    if (sind >= 0) {
		czc = Zc_by_correlation (vdv, Vsas[sind].vs, 
				    Vsas[i].vs, szc);
		if (Test_mode) 
		    MISC_log ("        cor zc %d at %d using vsa at %d (%d)\n",
				czc, Vsas[i].rs, Vsas[sind].rs, szc);
	    }
	}
	Vsas[i].czc = czc;
	if (czc < 0) {			/* discard this vad */
	    Vads[Vsas[i].vad_ind].dtm = 0;
	    continue;
	}

	zcazi = vdv->ew_azi[czc % vdv->yz] * .1 - 90.;
//	if (Test_mode)
//	    MISC_log ("    ZC corrected vad azi %.0f (at %d czc %d) from %.0f\n", zcazi, Vsas[i].rs, czc, Vsas[i].dir);
	Vsas[i].dir = zcazi;
	alfa = (180. - zcazi) * deg2rad;
	Vads[Vsas[i].vad_ind].u = Vsas[i].spd * cos (alfa);
	Vads[Vsas[i].vad_ind].v = Vsas[i].spd * sin (alfa);
	cnt++;
    }
//    if (cnt == 0 && CD_is_hurricane_detected (vdv, NULL) == 2)
//			/* if no correction is possible, remove nonuniform */
//	vdv->data_type &= ~DT_NONUNIFORM;
}

/***************************************************************************

    Finds and returns the non-uniform data range.

***************************************************************************/
int VDV_nonuniform_range (Vdeal_t *vdv) {
    int i;

    if (!(vdv->data_type & DT_NONUNIFORM))
	return (10000);		/* no nonuniform detected return large range */
    Ew_struct_t *ew = &(vdv->ew);
    unsigned short *rfs = ew->rfs;
    for (i = 0; i < ew->n_rgs; i++) {
	if (rfs[i] & RF_NONUNIFORM)
	    break;
    }
    if (i < ew->n_rgs)
	return (i * ew->rz);
    return (10000);
}
/***************************************************************************

    Retrieves the radial center of the non-uniform (high shear) area.

***************************************************************************/

int VDV_get_nonuniform_yc (Vdeal_t *vdv, int *yc) {

    if (Non_uniform_yc < 0)
	return (0);
    *yc = Non_uniform_yc;
    return (1);
}

/***************************************************************************

    Determines if region is near a long-range hurricane center. It 
    uses Vsas info to do the job. It returns 1 on success or 0 otherwise.
    This is the B20 version which works with the sign daliasing using the
    Vsas info.

***************************************************************************/

int VDV_is_in_long_range_eye (Vdeal_t *vdv, Region_t *region) {
    int x, y, min, rmin, rmax, i;
//extern int dbg;

    x = region->xs + region->xz / 2;
    if (!(vdv->data_type & DT_NONUNIFORM) ||	/* not nouniform data */
	region->xs < 800 ||			/* long range only */
	region->yz * 50 > x || region->xz > 200)	/* region too large */
	return (0);
    y = (region->ys + region->yz / 2) % vdv->yz;
//if (dbg) MISC_log ("   ##   %d  %d   yz %d xz %d \n", x, y, region->yz, region->xz);

    min = rmin = 100000;
    rmax = 0;
    for (i = 0; i < N_vsas; i++) {
	int rdf;
	if (Vsas[i].czc < 0)
	    continue;
//if (dbg) MISC_log ("    i %d   czc %d  rs %d  diff %f     x %d   y %d\n", i, Vsas[i].czc, Vsas[i].rs, VDA_angle_diff (vdv->ew_azi[y] * .1f, vdv->ew_azi[Vsas[i].czc] * .1f), x, y);
	if (Vsas[i].rs < rmin)
	    rmin = Vsas[i].rs;
	if (Vsas[i].rs > rmax)
	    rmax = Vsas[i].rs;
	if (Vsas[i].rs >= x)
	    continue;
	if (VDA_angle_diff (vdv->ew_azi[y] * .1f, 
			vdv->ew_azi[Vsas[i].czc] * .1f) * x > 12.f * 1000.f)
	    continue;			/* > 12 degrees from zero v */
	rdf = region->xs - Vsas[i].rs;
	if (rdf < min)
	    min = rdf;
    }
//if (dbg) MISC_log ("         min %d     rmax - rmin %d\n", min, rmax - rmin);
    if (rmin > 600 && rmax - rmin < 250 &&	/* likely half eye */
	min > 0 && min < 250)			/* likely in half eye */
	return (1);
    return (0);
}

/***************************************************************************

    Conducts zero-crossing analysis for data of nr ranges started at st_r. 

***************************************************************************/

static void V_sign_analysis (Vdeal_t *vdv, Vad_result_t *vad, int vad_ind,
							int st_r, int nr) {
    static int Vsa_bz = 0;
    int n_segs, i, vcnt;
    Segs_t segs[3];
    Vsa_t *vsa;

    if (N_vsas >= Vsa_bz) {	/* extend the buffer */
	int inc = 100;
	Vsa_bz += inc;
	Vsas = (Vsa_t *)STR_grow (Vsas, Vsa_bz * sizeof (Vsa_t));
	memset (Vsas + Vsa_bz - inc, 0, inc * sizeof (Vsa_t));
    }

    vsa = Vsas + N_vsas;
    vsa->vs = (short *)STR_reset (vsa->vs, vdv->yz * sizeof (short));
    n_segs = Computes_zc_segs (vdv, st_r, nr, vdv->data_scale * 3.,
							segs, vsa->vs);
    if (n_segs == 0)
	return;

    N_vsas++;
    vsa->rs = st_r;
    vsa->nr = nr;
    vsa->zc1 = vsa->zc2 = -1;
    vsa->rms = vad->rms1;
    vsa->spd = vad->speed;
    vsa->dir = vad->dir;
    vsa->vad_ind = vad_ind;
    vsa->vcnt = 0;
    if (n_segs >= 3) {
	vsa->gvsa = 0;
	return;
    }

    vcnt = 0;
    for (i = 0; i < n_segs; i++) {
	int width = segs[i].end - segs[i].st + 1;
	if (width < 0)
	     width += vdv->yz;
	if (width > Myround (240. / vdv->gate_width)) {
	    vsa->gvsa = 0;
	    return;
	}
	vcnt += segs[i].cnt;
    }
    vsa->vcnt = vcnt;

    if (n_segs == 1) {
	if (segs->p > 0) {
	    vsa->zc1 = segs->z2;
	    vsa->zc2 = segs->z1;
	}
	else {
	    vsa->zc1 = segs->z1;
	    vsa->zc2 = segs->z2;
	}
	vsa->gvsa = 1;
    }
    if (n_segs == 2) {
	if (segs[0].p < 0) {
	    vsa->zc1 = segs[0].z1;
	    vsa->zc2 = segs[1].z1;
	}
	else {
	    vsa->zc1 = segs[1].z1;
	    vsa->zc2 = segs[0].z1;
	}
	if ((segs[0].cnt > 5 * segs[1].cnt) || (segs[1].cnt > 5 * segs[0].cnt))
	    vsa->gvsa = 1;
	else
	    vsa->gvsa = 2;
    }
}

/***************************************************************************

    Computes v sign segments from vdv->out for zc analysis. The data used is
    nr ranges started from "st_r". Returns the number of segments. If at least
    3 segments were found, 3 is returned and the segs may not be fully filled.

***************************************************************************/

static int Computes_zc_segs (Vdeal_t *vdv, int st_r, int nr, 
				double thr, void *vsegs, short *vbuf) {
    short *b1, *b2;
    int doff, ub, lb, yz, stride, y, v, n_segs, i;
    Segs_t *segs = (Segs_t *)vsegs;

    Get_data_buffer (vdv->yz, &b1, &b2);
    yz = vdv->yz;
    stride = vdv->xz;
    doff = vdv->data_off;
    ub = Myround (thr * Vscale);
    lb = Myround (thr * .5 * Vscale);
    for (y = 0; y < yz; y++) {		/* compute range avarage of the data */
	int c;
	short *p;

	p = vdv->out + (y * stride + st_r);
	c = 0;
	v = 0;
	for (i = 0; i < nr; i++) {
	    short d = p[i];
	    if (d == SNO_DATA)
		continue;
	    v += d - doff;
	    c++;
	}
	if (c * 5 > nr)		/* at least 20 percent is available */
	    b1[y] = v * Vscale / c;
	else
	    b1[y] = Vndata;
    }

    for (y = 0; y < yz; y++) {		/* azi smooth the data */
	int s, c;
	s = c = 0;
	for (i = -2; i <= 2; i++) {
	    v = b1[(y + i + yz) % yz];
	    if (v == Vndata)
		continue;
	    c++;
	    s += v;
	}
	if (c > 0)
	    vbuf[y] = s / c;
	else
	    vbuf[y] = Vndata;
    }

    n_segs = Search_segs (vbuf, yz, ub, segs);
    if (n_segs == 0 || n_segs >= 3)
	return (n_segs);

    if (n_segs == 1) {			/* search zero crossing */
	int steps, k;

	segs->z1 = segs->z2 = -1;
	steps = Myround (30. / vdv->gate_width);
	for (k = 0; k < 2; k++) {
	    int min, mini, v, ind;
	    min = 0xffff;
	    mini = 0;
	    for (i = 1; i <= steps; i++) {
		if (k == 0)
		    ind = (segs->end + i) % yz;
		else
		    ind = (segs->st - i + yz) % yz;
		v = vbuf[ind];
		if (v == Vndata)
		    break;
		if (v < 0)
		    v = -v;
		if (v < lb && v < min) {
		    min = v;
		    mini = ind;
		}
	    }
	    if (min < 0xffff) {
		if (k == 0)
		    segs->z1 = mini;
		else
		    segs->z2 = mini;
	    }
	}
    }

    if (n_segs == 2) {			/* search zero crossing */
	int k;
	for (k = 0; k < 2; k++) {
	    int st, end, min, mini, v, ind;

	    segs[k].z1 = segs[k].z2 = -1;
	    if (k == 0) {
		st = segs[0].end;
		end = segs[1].st;
	    }
	    else {
		st = segs[1].end;
		end = segs[0].st;
	    }
	    if (end < st)
		end += yz;

	    min = 0xffff;
	    mini = 0;
	    for (i = st; i <= end; i++) {
		ind = i % yz;
		v = vbuf[ind];
		if (v == Vndata)
		    continue;
		if (v < 0)
		    v = -v;
		if (v < lb && v < min) {
		    min = v;
		    mini = ind;
		}
	    }
	    if (min < 0xffff) {
		segs[k].z1 = mini;
	    }
	    else if (end - st - 1 <= Myround (8. / vdv->gate_width)) {
		double vs = vbuf[st % yz];	/* ZC from interpolation */
		double ve = vbuf[end % yz];
		segs[k].z1 = (st - Myround (vs * (end - st) / (ve - vs))) % 
									yz;
	    }
	}
    }

    return (n_segs);
}
/***************************************************************************

    Searches for segments on array of buf of size yz for V_sign_analysis.
    Returns the number of segments found. 3 is returned if at least 3 segs
    is found and the values are not assigned.

***************************************************************************/

static int Search_segs (short *buf, int yz, int thr, void *vsegs) {
    int fp, find, i, p, lind, cnt, c, end;
    Segs_t *segs = (Segs_t *)vsegs;

    fp = find = 0;
    for (i = 0; i < yz; i++) {	/* find first non-zero data */
	int v = buf[i];
	if (v == Vndata)
	    continue;
	if (v > thr) {
	    fp = 1;
	    find = i; 
	    break;
	}
	if (v < -thr) {
	    fp = -1;
	    find = i; 
	    break;
	}
    }
    if (fp == 0)		/* no significant v found */	
	return (0);

    p = fp;
    segs[0].st = find;
    segs[0].p = fp;
    lind = find;
    cnt = c = 0;
    end = find + yz;
    for (i = find; i <= end; i++) {
	int v = buf[i % yz];
	if (v == Vndata)
	    continue;
	if (v > thr) {
	    if (p > 0) {
		if (i < end) {
		    lind = i;
		    c++;
		}
		continue;
	    }
	    if (i < end)
		p = 1;
	}
	else if (v < -thr) {
	    if (p < 0) {
		if (i < end) {
		    lind = i;
		    c++;
		}
		continue;
	    }
	    if (i < end)
		p = -1;
	}
	else
	    continue;
	segs[cnt].end = lind % yz;
	segs[cnt].cnt = c;
	cnt++;
	if (cnt >= 3)
	    return (cnt);
	segs[cnt].st = i % yz;
	segs[cnt].p = p;
	lind = i;
	c = 1;
    }
    if (p == fp) {
	if (cnt == 0) {
	    segs[cnt].end = lind % yz;
	    segs[cnt].cnt = c;
	    cnt++;
	}
	else {
	    segs[0].st = segs[cnt].st;
	    segs[0].cnt += c;
	}
    }
    if (cnt == 1) {	/* adjust to get rid of max internal empty segment */
	int max, s, e;
	max = s = e = c = 0;
	for (i = segs[0].st; i <= segs[0].end; i++) {
	    int v = buf[i];
	    if (v != Vndata && ((segs[0].p > 0 && v > thr) || 
					(segs[0].p < 0 && v < -thr))) {
		if (c > max) {
		    max = c;
		    s = i - c - 1;
		    e = i;
		}
		c = 0;
	    }
	    else
		c++;
	}
	if (max > segs[0].st + yz - segs[0].end - 1) {
	    segs[0].st = e;
	    segs[0].end = s;
	}
    }

    return (cnt);
}

/****************************************************************************

    Returns the zero crossing value of array "dvs" based on source array of 
    svs and source zero crossing szc. Future improvement may include: 1. 
    Checking how good the correlation minimum is established (The beter, the
    more reliable zc estimate). 2. Check estimated zc against the data to
    make sure it is still in the gap (Check_boundary in test_code.c).

****************************************************************************/

static int Get_corr (short *v1, short *v2, int off, Vdeal_t *vdv, int zc) {
    int n90, yz, st, end, c, i, max1, max2;
    double s;

    n90 = Myround (90. / vdv->gate_width);
    yz = vdv->yz;
    st = zc - n90;
    end = zc + n90;
    /* find max1 and max2 to normalize the size of the data */
    max1 = max2 = 0;
    for (i = st; i < end; i++) {	/* use data near zc */	
	int i1, d;
	i1 = (i + yz) % yz;
	if (v1[i1] == Vndata)
	    continue;
	d = v1[i1];
	if (d < 0)
	    d = -d;
	if (d > max1)
	    max1 = d;
	if (v2[i1] == Vndata)
	    continue;
	d = v2[i1];
	if (d < 0)
	    d = -d;
	if (d > max2)
	    max2 = d;
    }
    s = c = 0;
    for (i = st; i < end; i++) {	/* compute correlation */	
	int i1, i2;
	double d;
	i1 = (i + yz) % yz;
	i2 = (i + off + yz) % yz;
	if (v1[i1] == Vndata || v2[i2] == Vndata)
	    continue;
	d = (double)v1[i1] * max2 - (double)v2[i2] * max1;
	s += d * d;
	c++;
    }
    if (c > 0)
	s = s / (max1 * max2 * c);
    else
	s = (double)(max1 + max2) * (max1 + max2);	/* the largest */
//printf ("  ************  st %d  end %d  %d %d off %d  %.1f\n", st, end, max1, max2, off, s);
    return ((int)s);
}

/****************************************************************************

    Returns the zero crossing value of array "dvs" based on source array of 
    svs and source zero crossing szc. Future improvement may include: 1. 
    Checking how good the correlation minimum is established (The better, the
    more reliable zc estimate). 2. Check estimated zc against the data to
    make sure it is still in the gap (Check_boundary in test_code.c).

****************************************************************************/
static int Zc_by_correlation (Vdeal_t *vdv, short *svs, short *dvs, int szc) {
    int min, mini, i, nsteps;

    nsteps = Myround (15. / vdv->gate_width);
    min = 0x7ffffff;
    mini = 0;
    for (i = 0; i <= nsteps; i++) {
	int cor = Get_corr (svs, dvs, i, vdv, szc);
	if (cor * 9 > min * 10)
	    break;
	if (cor < min) {
	    min = cor;
	    mini = i;
	}
    }
    for (i = -1; i >= -nsteps; i--) {
	int cor = Get_corr (svs, dvs, i, vdv, szc);
	if (cor * 9 > min * 10)
	    break;
	if (cor < min) {
	    min = cor;
	    mini = i;
	}
    }
//printf ("                mini %d  szc %d  min %d\n", mini, szc, min);
    if (min < 0x7fffffff && mini < nsteps  && mini > -nsteps)
	return ((mini + szc + vdv->yz) % vdv->yz);
    return (-1);
}

