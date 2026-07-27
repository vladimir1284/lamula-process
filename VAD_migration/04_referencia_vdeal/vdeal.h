
/***********************************************************************

    Description: Internal include file for vdeal.

***********************************************************************/

/* 
 * RCS info
 * $Author: cbryan $
 * $Locker:  $
 * $Date: 2024/10/01 19:51:25 $
 * $Id: vdeal.h,v 1.2 2024/10/01 19:51:25 cbryan Exp $
 * $Revision: 1.2 $
 * $State: Exp $
 */  

#ifndef VDEAL_H
#define VDEAL_H

#define MAX_ALTITUDE 18000.	/* max altitude, in meters, processed in
				   estimating EW */
#define MAX_EW_NRS 200		/* max number of EW grid points in range
				   direction */
#define MAX_N_PRF 3		/* max number of PRF sectors */
#define OVERLAP_SIZE 8		/* maximum partition one-side overlap size */

typedef struct {
    short x, y;
} Point_t;

enum {GATE_OTHER, GATE_ISOLATE};	/* for Gate_t.type */

typedef struct gate_t {	/* record special gate */
    short x;		/* x location */
    short y;		/* y location */
    unsigned char v;	/* value */
    unsigned char type;	/* type flag */
} Gate_t;

typedef struct {
    short nyq;		/* Nyquest v of PRF section */
    short azi;		/* start azi number of PRF section */
    int size;		/* number of radials of PRF section */
} Prf_sec_t;

typedef struct params {	/* algorithm paramters - may be optimized for VCP,
			   location and time of the year */
    int max_shear;	/* The maximum normal shear between neighboring gates.
			   This and the next are used in identifying connected
			   regions and 2D border type identification. */
    int am_shear;	/* The aliased maximum normal shear between
			   neighboring gates. */
    float weight_factor;/* weighting factor used for 2D weighting (.1). 0 for
			   linearly weighting. */
    float has_weight;	/* factor for shear-based azi weighting - improve 
			   tornado cases. >= 1 - disabled. */
    float bh_thr;	/* histogram analysis threshold for identifying failed
			   gates in 2D dealiasing (VDEAL_BH) (.35) */
    int small_gc;	/* small gate count used in histogram analysis */
    int data_off;	/* v offset (data value for v = 0) */

    float r_w_ratio;	/* factor for range border weight ratio */
    int r0;		/* (r0 + x) * r_w_ratio is gate width / gate size */
    int g_size;		/* gate size in range direction in meters */
    float data_scale;	/* data scale (number of levels per m/s) */
    int xs, ys;		/* region location */
    int xr, yr;		/* subsample ratio */
    void *vdv;

    int nyq;		/* Nyqust velocity */
    char use_ni;	/* for NI control. 0: NI map is not used;
			   1: thr for less BH gates; 2: more BH gates. */
    char fppi;		/* the region is full ppi */
    int min_hlw_r, max_hlw_r;	/* min max high local wind ranges */

    int bh_cnt;		/* returns the number of BH gates */
    int bhs_cnt;	/* returns count of the BH for PRF suggestion gates */
    int maxhdf;		/* returns the max hist deviation from 2KVn */

    int stride;		/* buffer stride for dmap */
    int yz;		/* if not 0, inp and dmap input is warpped at this y */
    unsigned char *dmap;/* region pointer to the dmap buffer */
    unsigned char *nimap;	/* NI map for subsampled regions */
} Params_t;

/* bit flags for Ew_struct_t.rfs */
#define RF_CLEAR_AIR 0x8
#define RF_HIGH_VS 0x2		/* high vertical shear - must be 2 */
#define RF_LOW_VS 0x1	/* low VS. If both set, very high VS - must be 1 */
#define RF_NONUNIFORM 0x20	/* non-uniform wind range */
#define RF_EW_UNAVAILABLE 0x4	/* EW not available */
#define RF_2SIDE_VAD 0x200	/* VAD on two sides exists */
#define RF_HIGH_WIND 0x10	/* high VAD wind detected */
#define RF_VAD_FAILED 0x40	/* VAD failed */

/* bit flags for Ew_struct_t.efs */
#define EF_HIGH_SHEAR 0x1	/* high shear area */
#define EF_STORM 0x4		/* storm area */
#define EF_CLEAR_AIR 0x8	/* clear air area */
#define EF_SECOND_TRIP 0x10	/* second trip in v */
#define EF_FRONT 0x20		/* front area */
#define EF_LOW_ELE_EW 0x40	/* use ew of lower elevation cut */
#define EF_HS_GRID 0x2		/* high shear grid detected by median inp */
#define EF_UNAVAIL 0x80		/* ew not available */

typedef struct Ew_struct {
    int n_rgs;		/* number of EW grid points in range direction */
    int rz;		/* EW grid's range step size, in number of gates */
    int n_azs;		/* number of EW grid points in azimuthal direction */
    float az;		/* EW grid's azimuthal step size, in degrees */
    short *ews;		/* array of current EWs. n_rgs by n_azs */
    short *ewm;		/* pointer to EW map. n_rgs by n_azs */
    short *sewm;	/* pointer to smoothed EW map. n_rgs by n_azs */
    short *vadg;	/* pointer to VAD on EW grid. n_rgs by n_azs */
    unsigned short *rfs;/* flags for each range */
    unsigned char *eww;	/* ewm weighting for each ew grid */
    unsigned char *efs;	/* flags for each ew grid */
    void *ups;		/* array of EW updating info */
} Ew_struct_t;

/* for Vdeal_t.data_type */
#define DT_SUB_IMAGE 0x1
#define DT_VH_VS 0x8		/* the data is of very high vertical shear */
#define DT_VH_VDS 0x200		/* the data is of very high vertical directional shear */
#define DT_NONUNIFORM 0x10	/* the data is non-uniform */
#define DT_NO_HIST 0x2		/* history from previous vol not available */
#define DT_SPRT 0x20		/* the data is staggered PRT */
#define DT_NO_EXTWIND 0x40	/* the external wind is not needed */
#define DT_NEAR_RADAR_STORM 0x80 /* near radar storm detected */
#define DT_HDF 0x100		/* data is of signif. deali failure, phase 1 */
#define DT_HVS_HW 0x400		/* both vertical shear and wind are high */
#define DT_VAD_NONUNIF 0x800	/* data long-range non-uniform based on vad */
#define DT_EW_REQUIRED 0x4	/* EW is required for this data */
#define DT_WEAK_DATA_NEAR_RADAR 0x1000	/* data near radar is week */
#define DT_NO_VS_HW 0x2000	/* data has no hs and hw in first trip */

enum {RT_DONE, RT_START_ELE, RT_PROCESS, RT_COMPLETED};
						/* for Vdeal_t.rt_state */
enum {RS_NONE, RS_START_ELE, RS_NORMAL, RS_END_ELE};
						/* for Vdeal_t.radial_status */

typedef struct vdeal_g_t {	/* vdeal global variables */
    int xz;		/* cut size in range, in number of bins */
    int yz;		/* cut size in azimuth, in number of bins */
    int data_off;	/* data offset in data levels (value for 0 m/s) */
    float data_scale;	/* data scale (number of levels per m/s) */
    float start_range;	/* starting range of the cut, in meters */
    int g_size;		/* gate size in meters */
    float start_azi;	/* starting azimuth of the cut, in degrees */
    float gate_width;	/* gate width of the radials, in degrees */
    int nyq;		/* Nyquist velocity in data levels. If multiple PRF
			   sections, the min nyq of all sections, */
    float elev;		/* elevation of the cut in degrees */
    char full_ppi;	/* this is 360 degree ppi */
    char low_prf;	/* this is a low PRF scan */
    short vcp;		/* VCP number */
    short unamb_range;
    short phase;	/* processing phase: 1 (EEW) or 2 */
    int vol_num;	/* volume number */
    int cut_num;	/* cut number in the current volume */
    time_t dtm;		/* data time */
    int data_type;	/* data type */
    int nonuniform_vol;	/* the latest vol_num of nonuniform data detected */
    int ext_win_range;	/* the start range where external wind is used */

    int n_secs;		/* number of PRF sections */
    Prf_sec_t secs[MAX_N_PRF + 1];	/* PRF sections */

    short realtime;	/* this is realtime processing */
    short rt_read;	/* number of redials read in this elevation */
    short rt_processed;	/* number of redials processed in this elevation */
    short rt_done;	/* number of redials comleted in this elevation */
    char rt_state;	/* real time state */
    char radial_status;	/* status of the latest radial */

    unsigned char *inp;	/* input image of the current cut, xz by yz */
    unsigned char *dbz;	/* DBZ image of the current cut, xz by yz */
    unsigned char *spw;	/* SPW image of the current cut, xz by yz */
    unsigned char *ew_aind;	/* EW azimuth index of each radial */
    unsigned short *ew_azi; /* azimuth angle (in .1 degrees) of each radial */

    short *out;		/* output image, xz by yz */
    unsigned char *dmap;/* dealiasing map, xz by yz */
    unsigned char *nimap;	/* NI and other static maps, xz by yz */

    Ew_struct_t ew;	/* EW data */
} Vdeal_t;

typedef struct region_t {	/* struct for a region (connected area) */
    short *data;	/* the regions data. The stride is xz */
    int xs;		/* x global location */
    int ys;		/* y global location */
    int xz;		/* x size */
    int yz;		/* y size */
    int n_gs;		/* number of valid gates */
} Region_t;

typedef struct clump_df {	/* struct for a data filtering */
    unsigned char *map;		/* filtering map - The same stride as data */
    unsigned char yes_bits;	/* if non-0, any bit will enable data */
    unsigned char exc_bits;	/* if non-0, any bit will exclude data */
    unsigned char *omap;	/* output map - The same stride as data */
    unsigned char mapv;		/* value for assigning (ORed) to omap */
} Data_filter_t;

/* bit flag for Vdeal_t.dmap */
#define DMAP_BH 2	/* bit flag for bad gate based on histogram value */
#define DMAP_BE 4	/* bit flag for bad gate based on EW */
//#define DMAP_NPRCD 16	/* bit flag for not processed data */
#define DMAP_NEWC 32	/* bit flag for no ew check is necessary */
#define DMAP_KEEP_2D 64	/* bit flag for not applying BH, BE, f2a fixing */
#define DMAP_FILL 1	/* bit flag for temporarily filled-in gates */
#define DMAP_LOCAL 8	/* bit flag for local use (shared) */
//#define DMAP_TN	128	/* bit flag for tordado neighbor */

#define pi 3.141592653589
#define deg2rad 0.017453293	/* pi / 180. */
#define rad2deg 57.295779513	/* 180. / pi */
#define SNO_DATA (2047)	/* gate is missing for short ((short)0x7ff) */
#define BNO_DATA 0	/* gate is missing for unsigned byte */

typedef double Banbks_t;

typedef double Spmcg_t;

typedef struct {		/* sparse matrix struct */
    int *ne;			/* # non-zero elements for each row */
    int *c_ind;			/* list of non-zero element column indeces */
    Spmcg_t *ev;		/* element values corresponding to c_ind */
} Sp_matrix;

/* values for parameters of VDC functions */
enum {VDC_IDR_XS, VDC_IDR_SIZE, VDC_IDR_XZ};
#define VDC_IDR_SORT 0xff
#define VDC_IDR_WRAP 0x100
#define VDC_PARM_ARRAY 0x200
#define VDC_NEXT 0x10000000
#define VDC_BIN 0x80000000

typedef struct part_t {	/* partitions struct */
    int ys;		/* starting y in the cut */
    int yz;		/* partition size in number of gates */
    int yoff;		/* offset of the first partition radial */
    int eyz;		/* extended partition y size */
    int nyq;
    int state;		/* current processsing state */
    int reported;	/* possible partition failure reported */
    unsigned char *inp;	/* partition data input */
    unsigned char *dmap;/* partition dmap */
} Part_t;

/* values for Nyquist interval map processing */
#define NI_SM_BIT 0x80		/* NI map - smooth gates */
#define NI_UP_BIT 0x40		/* NI map - ni value 1 */
#define NI_LOW_BIT 0x20		/* NI map - ni value -1 */
#define NI_AV_BIT 0x1		/* NI map - ni available */
#define NI_HSL_BIT 0x2		/* HSL map bit */
#define NI_HOW_BIT 0x8		/* HOW map bit */
#define NI_TORN 0x4		/* tornado map */
#define NI_HSPW 0x10		/* high spw gate */

#define TN_WIN_B_SZ(wz) ((((wz) * 2 + 1) * ((wz) * 2 + 1) + 7) / 8)
#define TB_B_SZ(size) (((size) + 7) / 8)

typedef struct {  /* optional input/output data for VDA_find_hs_features */
    unsigned char *dmap;	/* input data filter map */
    unsigned char fbits;	/* input filter bits */
    unsigned char *map;		/* caller provided work map (xz * yz). If not 
				   provided, the global Wbuf is used. */
    short check_smooth;		/* 1 - only hs points in smooth neighbor are 
				   in hs map (Checking smooth neighbor early);
				   2 - a feature is rejected if the hs points 
				   in non-smooth neighbor dominate in a feature
				   (Checking smooth neighbor later).*/
    int min_fsz;		/* minimum feature size. The default is 4. */
    int thr;			/* threshold; The default is 3 * nyq / 2 */
    int nwz, mwz;		/* filling distances for no-data and medium 
				   shear respectively. The default is 0. */

    int fxs, fys, fxz, fyz, sz;
		/* feature locations and sizes. sz is the diagonal size. These
		   are used for passing values to the callback. By function 
		   return, they contains the values of the maximum feature. */
    int cnt;	/* number of points of the feature, used for passing values to
		   the callback. */
    int (*cb) (int npts, Point_t *pts, void *prms, void *argsp);
		/* call back function for exporting the features. This is 
		   called for each feature. npts is the number of points in pts
		   which is the array of feature points. prms is the parameter
		   struct which contains the following output fields: fxs, fys,
		   fxz, fyz (feature location and sizes), and
		   cnt (The total number of points). npts may be less than cnt
		   if cnt is too large. */
    void *argsp;		/* parameters pass-through to cb */
} Dhsf_t;

/* failed 2d area type */
#define F2A_HS 0x1		/* failed from high shear - per-partition */
#define F2A_TURB 0x2		/* failed from turbulence - per-partition */
#define F2A_EV 0x4		/* extreme values detected - per-partition */
#define F2A_HSF 0x8		/* large hsf detected - per-partition */
#define F2A_ETURB 0x10		/* azi extended turb detection */
#define F2A_ALL 0xff		/* all types */
/* flag for PP_check_f2a_range input */
#define F2A_CHSF 0x100		/* hsf of current cut only */
#define F2A_BTURB 0x200		/* rst of best match. default: smallest */
#define F2A_COV 0x400		/* large elev diff allowed for f2a_coverage */
#define F2A_HSF_CLT 0x1000	/* use all evev and all time in hsf cluster */
/* flag for PP_check_f2a_range output */
#define F2A_EL_DIFF 0x100	/* found item has different elev */


int VD2D_2d_dealiase (short *carea, Params_t *parms, int n_gates,
						int xsize, int ysize);
int VDB_solve (int n, Sp_matrix *a, Banbks_t *b);
int VDB_linear_fit (int n, double *x, double *y, double *ap, double *bp);
void VDB_check_timeout (int seconds);

int VDE_initialize (Vdeal_t *vdv);
int VDE_global_dealiase (Vdeal_t *vdv, Region_t *region,
				unsigned char *dmap, int stride, int *qerr);
int VDE_update_ew (Vdeal_t *vdv);
void VDE_print_ew_flags (Vdeal_t *vdv);
short VDE_get_ew_value (Vdeal_t *vdv, int x, int y);
short VDE_get_intp_ew_value (Vdeal_t *vdv, int x, int y);
int VDE_neighbor_dealiase (Vdeal_t *vdv, Region_t *region, 
				int nyq, int *qerr, Part_t *part);

int VDD_get_nyq (Vdeal_t *vdv, int ys);
int VDD_process_image (Vdeal_t *vdv);
int VDD_apply_gd_copy_to_out (Vdeal_t *vdv, Region_t *region, int gd);
int VDD_init_vdv (Vdeal_t *vdv);
int VDD_process_realtime (Vdeal_t *vdv);
void VDD_log (const char *format, ...);
void VDD_set_parameters (Vdeal_t *vdv, Params_t *parms, int nyq);
int VDD_handle_2d_ni0_area (Vdeal_t *vdv, Region_t *rgn_2d, Region_t *region, int nyq);

void VDC_reset_next_region (void *rgsp);
int VDC_get_next_region (void *rgsp, int ind, Region_t *out);
int VDC_identify_regions (unsigned char *img, Data_filter_t *dmap, int stride, 
	int xst, int yst, int xsize, int ysize, 
	void *parms, int sort, void **rgsp);
void VDC_free (void *rgsp);

int VDE_get_azi_ind (Vdeal_t *vdv, double azimuth);
void VDE_ew_deal_area (Vdeal_t *vdv, int ys, int xz, int yz,
						unsigned char fbits);
int VDE_check_global_deal (Vdeal_t *vdv, Region_t *region, int gd);
int VDE_reset (Vdeal_t *vdv, int all);
int VDE_generate_ewm (Vdeal_t *vdv);
void VDE_set_ew_flags (Vdeal_t *vdv);
int VDE_quantize_gd (int nyq, int diff, int *qerr);
void VDE_generate_sewm (Vdeal_t *vdv);

int EE_estimate_ew (Vdeal_t *vdv);
short EE_get_eew_value (int x, int y);
int Myround (double x);
int EE_read_data (Vdeal_t *vdv, FILE *fl, char *fname, int ops);
int EE_save_data (Vdeal_t *vdv, FILE *fl, char *fname, int ops);
int EE_get_near_elev_ew (Vdeal_t *vdv, double r, double azi);
int EE_get_previous_ew (Vdeal_t *vdv, int x, int y);

int VDR_realtime_process (int argc, char *argv[], Vdeal_t *vdv);
int VDR_output_processed_radial (Vdeal_t *vdv);
int VDR_get_volume_time (time_t *v_st);
char *VDR_get_image_label ();
void VDR_set_image_label (char *label);
int VDR_get_ext_wind (int alt, int up, double *speed, double *dir, 
						unsigned int *tm);
void VDR_status_log (const char *msg);
void VDR_output_prfs (Vdeal_t *vdv, int min_nv, int min_nv_he, float min_he);

int VDV_vad_analysis (Vdeal_t *vdv, int tmp);
int VDV_read_history (Vdeal_t *vdv, int ops);
int VDV_write_history (Vdeal_t *vdv, int ops);
int VDV_get_wind (Vdeal_t *vdv, int xs, double *spdp, double *azip);
void VDV_save_storm_distance (Vdeal_t *vdv);
int VDV_get_bw_vs_correction (Vdeal_t *vdv, int xi, int yi);
double VDV_range_to_alt (Vdeal_t *vdv, double R);
double VDV_alt_to_range (Vdeal_t *vdv, double alt);
int VDV_basic_vad (Vdeal_t *vdv, int rst, int nr, double *c0,
				double *spd, double *dir, double *rms);
int VDV_modify_FAW (Vdeal_t *vdv, double speed, double dir, 
					double min_alt, double max_alt);
int VDV_print_samples (Vdeal_t *vdv, double a1, double a2);
int VDV_check_and_update_vads (Vdeal_t *vdv);
int VDV_is_dup_elevation (Vdeal_t *vdv);
void VDV_set_instance_label (char *label);
int VDV_nonuniform_range (Vdeal_t *vdv);
int VDV_is_in_long_range_eye (Vdeal_t *vdv, Region_t *region);
void VDV_check_data_history (Vdeal_t *vdv);
int VDV_get_nonuniform_yc (Vdeal_t *vdv, int *yc);

void VD2D_realtime_processing (Vdeal_t *vdv);

void PP_fill_in_gaps (Vdeal_t *vdv, unsigned char *inp, int xz, int yz,
				int level, int fp, int max_gap, int nyq);
short *PP_get_hz_cnt ();
void PP_analyze_z (Vdeal_t *vdv);
int PP_preprocessing_v (Vdeal_t *vdv, int ys, int yn, int nyq);
void PP_set_front_ew (Vdeal_t *vdv);
void PP_setup_prf_sectors (Vdeal_t *vdv, int nyq, int n, int *secs);
unsigned char *PP_get_med_v ();
void PP_detect_fronts (Vdeal_t *vdv);
void PP_set_nyq_interval_map (Vdeal_t *vdv);
void PP_set_max_v (Vdeal_t *vdv);
int PP_read_data (Vdeal_t *vdv, FILE *fl, char *fname);
int PP_save_data (Vdeal_t *vdv, FILE *fl, char *fname);
int PP_get_first_trip_range ();
void PP_get_max_min_v (Vdeal_t *vdv, int x, int y, int *maxv, int *minv);
int PP_is_front_deteted ();
int PP_in_front_range (Vdeal_t *vdv, int r);
void PP_report_failed_2d_area (Vdeal_t *vdv, int type, 
					int rst, int yc, int width);
int PP_check_f2a_range (Vdeal_t *vdv, int type, int y, int *ret);
int PP_f2a_coverage (Vdeal_t *vdv);

int VDA_search_median_value (int *d, int n, int nyq, int d_off, int *maxdp);
int VDA_Compute_shear_hist (unsigned char *inp, int xz, int yz, 
					int stride, int fp, int **histp);
void VDA_get_neighbor_offset (int n, int y, int xz, int yz, int fp, int *off);
int VDA_compute_data_hist (unsigned char *inp, int stride, int xs, 
					int xz, int yz, int **histp);
void VDA_set_constants (int nyq, int data_off);
int VDA_detect_false_shear (Vdeal_t *vdv, Region_t *reg, int thr, int *maxwp);
int VDA_check_fit_out (Vdeal_t *vdv, Region_t *reg, 
					int gd, int thr, int *bcntp);
int VDA_border_dealiase (Vdeal_t *vdv, Region_t *reg, Part_t *part, 
					int *conn, int *bcntp, int *std);
int VDA_check_border_conn (Vdeal_t *vdv, Region_t *reg, int use_out, int fppi);
void VDA_thin_and_dialate (unsigned char *mapbuf, int xz, int yz,
					int fp, int v, int level);
int VDA_find_thin_conn (unsigned char *inp, int xz, int yz, int level, int fp,
		Data_filter_t *dft, int nyq, int d_off, 
		unsigned char *outmap, unsigned char mapv);
int VDA_remove_single_gate_conn (unsigned char *inp, int xz, int yz, 
	    Data_filter_t *dft, unsigned char *outmap, unsigned char mapv);
int VDA_check_failed_gates (Vdeal_t *vdv, Part_t *parts, int ptind,
					Point_t *fp, int fp_bz);
void VDA_set_border_map (Region_t *reg, int fppi, unsigned char *map);
void VDA_detect_hs_features (Vdeal_t *vdv, int *m_nyq, int *deal_fail);
void VDA_init_travel (int nb_sz, int rxz, int ryz, int rfp, unsigned char *wmap,	int wz, int max_depth, int (*cb) (int, int, int, void *), void *args);
void VDA_init_cut_travel (int xs, int ys, int xz, int yz, int fp);
void VDA_set_next_point (int xn, int yn);
int VDA_get_offset (int x, int y, int *roff);
int VDA_test_bit (int set, unsigned char *map, int off);
int VDA_get_cut_offset (int x, int y, int *off);
int VDA_start_travel (int x, int y);
int VDA_travel_depth ();
int VDA_find_hs_features (short *da, int xz, int yz,
				int nyq, int fp, int data_off, Dhsf_t *prms);
float VDA_angle_diff (float a1, float a2);
int VDA_y_diff (Vdeal_t *vdv, int y1, int y2, int *snp);
float VDA_linear_interp (float x, float x1, float x2, float y1, float y2);

void CD_remove_ground_clutter (Vdeal_t *vdv);
int CD_read_gcc (Vdeal_t *vdv, FILE *fl, char *fname);
int CD_save_gcc (Vdeal_t *vdv, FILE *fl, char *fname);
int CD_get_saved_gcc_gate (Gate_t **saved_gates);
int CD_get_gcc_likely (char **p);
int CD_detect_tornado (Vdeal_t *vdv);
int CD_get_hlw_ranges (Vdeal_t *vdv, int *min_r, int *max_r, int type);
int CD_is_near_hlw (Vdeal_t *vdv, int xs, int ys, int xz, int yz, 
				int r_tol, int a_tol);
void CD_get_hlw_map (Vdeal_t *vdv, unsigned char *map, int bit, int type);
void CD_init_tn_hlw_detection (Vdeal_t *vdv);
int CD_detect_hurricane (Vdeal_t *vdv);
int CD_is_hurricane_detected (Vdeal_t *vdv, int *yc);
int CD_get_hurr_info (Vdeal_t *vdv, int rc, int *ycp);
void CD_prf_suggestion (Vdeal_t *vdv);
void CD_report_bh (Vdeal_t *vdv, int n_gs, int bhs_cnt, int maxhdf);
int CD_any_hlw_tn (int type);

/* debugging routines */
int dump_simage (char *name, short *image, int xsize, int ysize, int stride);
int dump_bimage (char *name, unsigned char *image, 
				int xsize, int ysize, int stride);
int dump_timage (Vdeal_t *vdv, char *name, void *image, 
				int xsize, int ysize, int stride);
int Aliase_image (unsigned char *image, Vdeal_t *vdv, char *fname);
int VDT_dump_dmap (char *name, Vdeal_t *vdv);
int VDT_dump_ew (char *name, Vdeal_t *vdv, char *field);
int VDT_read_ew (char *name, Ew_struct_t *ew);
int VDT_dump_efs (char *name, Vdeal_t *vdv, unsigned char bit);
void VDT_set_dump_image_mode ();
int VDT_is_dbg_region (Region_t *region, Part_t *part, int step, int n_gs);
int dbg_cut ();
int VDT_set_vdv (Vdeal_t *vdv);
char *VDT_get_next_image_name (char *iname);
int VDT_send_ack_event (Vdeal_t *vdv);
void VDT_set_modificatiions (char *mods);
int VDT_is_mod (char *mod);

//int ORPGINFO_is_one_ms_resolution ();

#endif		/* #ifndef VDEAL_H */
