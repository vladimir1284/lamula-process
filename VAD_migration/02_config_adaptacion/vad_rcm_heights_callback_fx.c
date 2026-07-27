/*
 * RCS info
 * $Author: jeffs $
 * $Locker:  $
 * $Date: 2015/01/14 19:24:53 $
 * $Id: vad_rcm_heights_callback_fx.c,v 1.4 2015/01/14 19:24:53 jeffs Exp $
 * $Revision: 1.4 $
 * $State: Exp $
 */

/***************************************************************************/


/*** System Include Files ***/
#include <alg_adapt.h>
#include <product_parameters.h>


/*** Local Include Files ***/


#ifndef C_NO_UNDERSCORE

#ifdef LINUX
#define vad_rcm_heights_callback_fx vad_rcm_heights_callback_fx__
#endif

#endif


int vad_rcm_heights_callback_fx( void *block_address ){

  int i, ret = -1;	
  double get_array1[MAX_VAD_HEIGHTS];	
  double get_array2[MAX_RCM_HEIGHTS];
  vad_rcm_heights_t *vad_rcm_heights = (vad_rcm_heights_t *) block_address;

  /* Initialize the arrays. */
  memset( get_array1, 0, MAX_VAD_HEIGHTS*sizeof(double) );
  memset( get_array2, 0, MAX_RCM_HEIGHTS*sizeof(double) );

  /* Get vad heights data elements */
  ret = RPG_ade_get_values( VAD_RCM_HEIGHTS_DEA_NAME, ".vad", get_array1 );
  if( ret == 0 ){

    for( i = 0; i < MAX_VAD_HEIGHTS; i++ )
      vad_rcm_heights->vad[i] = (int) get_array1[i];
    
  }
  else{

    LE_send_msg( GL_ERROR, "VAD_RCM_HEIGHTS: vad heights unavailable, abort task\n" );
    RPG_abort_task();

  }

  /* Get vad heights data elements */
  ret = RPG_ade_get_values( VAD_RCM_HEIGHTS_DEA_NAME, ".rcm", get_array2 );
  if( ret == 0 ){

    for( i = 0; i < MAX_RCM_HEIGHTS; i++ )
      vad_rcm_heights->rcm[i] = (int) get_array2[i];
     
  }
  else{

    LE_send_msg( GL_ERROR, "VAD_RCM_HEIGHTS: rcm heights unavailable, abort task\n" );
    RPG_abort_task();

  }

#ifdef DEBUG
   for( i = 0; i < MAX_VAD_HEIGHTS; i++ )
     LE_send_msg( GL_INFO, "VAD_RCM_HEIGHTS: vad[%d] \t\t= %d\n", i, vad_rcm_heights->vad[i] );
    
   for( i = 0; i < STORM_CELL_MAX_REF_THRESH; i++ )
     LE_send_msg( GL_INFO, "VAD_RCM_HEIGHTS: rcm[%d] \t\t= %d\n", i, vad_rcm_heights->rcm[i] );
   
#endif

  return 0;
}
