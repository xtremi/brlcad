/*
 *			V R L I N K . C
 *
 *  Author -
 *	Michael John Muuss
 *  
 *  Source -
 *	SECAD/VLD Computing Consortium
 *	The U. S. Army Ballistic Research Laboratory
 *	Aberdeen Proving Ground, Maryland  21005-5066
 *  
 *  Copyright Notice -
 *	This software is Copyright (C) 1992 by the United States Army.
 *	All rights reserved.
 */
#ifndef lint
static char RCSid[] = "@(#)$Header$ (BRL)";
#endif

#include "conf.h"

#include <stdio.h>
#include <math.h>

#include "tcl.h"
#include "tk.h"

#include "machine.h"
#include "vmath.h"
#include "rtstring.h"
#include "raytrace.h"
#include "externs.h"
#include "pkg.h"
#include "./ged.h"
#include "./dm.h"

extern int		(*cmdline_hook)();	/* cmd.c */
extern void		(*viewpoint_hook)();	/* ged.c */

extern point_t		eye_pos_scr;		/* dozoom.c */

static struct pkg_conn	*vrmgr;			/* PKG connection to VR mgr */
static char		*vr_host = "None";	/* host running VR mgr */
static char		*tcp_port = "5555";	/* "gedd", remote mged */

#define VRMSG_ROLE	1	/* from MGED: Identify role of machine */
#define VRMSG_CMD	2	/* to MGED: Command to process */
#define VRMSG_EVENT	3	/* from MGED: device event */
#define VRMSG_POV	4	/* from MGED: point of view info */
#define VRMSG_VLIST	5	/* transfer binary vlist block */

void	ph_cmd();
void	ph_vlist();
static struct pkg_switch pkgswitch[] = {
	{ VRMSG_CMD,		ph_cmd,		"Command" },
	{ VRMSG_VLIST,		ph_vlist,	"Import vlist" },
	{ 0,			0,		(char *)0 }
};

/*
 *			P K G _ S E N D _ V L S
 */
int
pkg_send_vls( type, vp, pc )
int		type;
struct rt_vls	*vp;
struct pkg_conn	*pc;
{
	RT_VLS_CHECK(vp);
	return pkg_send( type, rt_vls_addr(vp), rt_vls_strlen(vp)+1, pc );
}

/*
 *  Called from cmdline() for now.
 *  Returns -
 *	!0	Print prompt for user.  Should always be this.
 *	 0	Don't print a prompt
 */
int
vr_event_hook(vp)
struct rt_vls	*vp;
{
	RT_VLS_CHECK(vp);

	if( vrmgr == PKC_NULL )  {
		cmdline_hook = 0;	/* Relinquish this hook */
		return 1;
	}

	if( pkg_send_vls( VRMSG_EVENT, vp, vrmgr ) < 0 )  {
		rt_log("event: pkg_send VRMSG_EVENT failed, disconnecting\n");
		pkg_close(vrmgr);
		vrmgr = PKC_NULL;
		cmdline_hook = 0;	/* Relinquish this hook */
	}
	return 1;
}

/*
 *  Called from the Tk event handler
 */
void
vr_input_hook()
{
	int	val;

	val = pkg_suckin(vrmgr);
	if( val < 0 ) {
		rt_log("pkg_suckin() error\n");
	} else if( val == 0 )  {
		rt_log("vrmgr sent us an EOF\n");
	}
	if( val <= 0 )  {
		Tk_DeleteFileHandler(vrmgr->pkc_fd);
		pkg_close(vrmgr);
		vrmgr = PKC_NULL;
		return;
	}
	if( pkg_process( vrmgr ) < 0 )
		rt_log("vrmgr:  pkg_process error encountered\n");
}

/*
 *  Called from ged.c refresh().
 */
void
vr_viewpoint_hook()
{
	struct rt_vls	str;
	quat_t		orient;

	rt_vls_init(&str);

	quat_mat2quat( orient, Viewrot );

	/* Need to send current viewpoint to VR mgr */
	/* XXX more will be needed */
	/* Eye point, quaturnion for orientation */
	rt_vls_printf( &str, "pov %e %e %e   %e %e %e %e   %e   %e %e %e\n", 
		-toViewcenter[MDX],
		-toViewcenter[MDY],
		-toViewcenter[MDZ],
		V4ARGS(orient),
		Viewscale,
		V3ARGS(eye_pos_scr) );

	if( pkg_send_vls( VRMSG_POV, &str, vrmgr ) < 0 )  {
		rt_log("viewpoint: pkg_send VRMSG_POV failed, disconnecting\n");
		pkg_close(vrmgr);
		vrmgr = PKC_NULL;
		viewpoint_hook = 0;	/* Relinquish this hook */
	}
	rt_vls_free( &str );
}

/*
 *			F _ P O V
 *
 *  Process the "pov" command generated above.
 *  XXX this should move to chgview.c when finished.
 */
int
f_pov( argc, argv )
int	argc;
char	*argv[];
{
	quat_t		orient;

	if( argc < 1+3+4+1+3 )  {
		rt_log("pov: insufficient args\n");
		return CMD_BAD;
	}
	toViewcenter[MDX] = -atof(argv[1]);
	toViewcenter[MDY] = -atof(argv[2]);
	toViewcenter[MDZ] = -atof(argv[3]);
	orient[0] = atof(argv[4]);
	orient[1] = atof(argv[5]);
	orient[2] = atof(argv[6]);
	orient[3] = atof(argv[7]);
	quat_quat2mat( Viewrot, orient );
	Viewscale = atof(argv[8]);
	eye_pos_scr[X] = atof(argv[9]);		/* interpreted in dozoom.c */
	eye_pos_scr[Y] = atof(argv[10]);
	eye_pos_scr[Z] = atof(argv[11]);
	new_mats();

	return CMD_OK;
}

/*
 *			F _ V R M G R
 *
 *  Establish a network link to the VR manager, using libpkg.
 *
 *  Syntax:  vrmgr host role
 */
int
f_vrmgr( argc, argv )
int	argc;
char	*argv[];
{
	struct rt_vls	str;
	char		*role;

	rt_vls_init(&str);

	if( vrmgr != PKC_NULL )  {
		rt_log("Closing link to VRmgr %s\n", vr_host);
		pkg_close( vrmgr );
		vrmgr = PKC_NULL;
		vr_host = "none";
	}

	vr_host = rt_strdup(argv[1]);
	role = argv[2];

	if( strcmp( role, "master" ) == 0 )  {
	} else if( strcmp( role, "slave" ) == 0 )  {
	} else if( strcmp( role, "overview" ) == 0 )  {
	} else {
		rt_log("role '%s' unknown, must be master/slave/overview\n", role);
		return CMD_BAD;
	}

	vrmgr = pkg_open( vr_host, tcp_port, "tcp", "", "",
		pkgswitch, NULL );
	if( vrmgr == PKC_ERROR )  {
		rt_log( "mged/f_vrmgr: unable to contact %s, port %s\n",
			vr_host, tcp_port);
		vrmgr = PKC_NULL;
		return CMD_BAD;
	}

	rt_vls_from_argv( &str, argc-2, argv+2 );

	/* Send initial message declaring our role */
	if( pkg_send_vls( VRMSG_ROLE, &str, vrmgr ) < 0 )  {
		rt_log("pkg_send VRMSG_ROLE failed, disconnecting\n");
		pkg_close(vrmgr);
		vrmgr = NULL;
		return CMD_BAD;
	}

	/* Establish appropriate hooks */
	if( strcmp( role, "master" ) == 0 )  {
		viewpoint_hook = vr_viewpoint_hook;
	} else if( strcmp( role, "slave" ) == 0 )  {
		cmdline_hook = vr_event_hook;
	} else if( strcmp( role, "overview" ) == 0 )  {
		/* No hooks required, just listen */
	}
	Tk_CreateFileHandler(vrmgr->pkc_fd, TK_READABLE,
			     (Tk_FileProc (*))vr_input_hook, (ClientData)NULL);
	rt_vls_free( &str );

	return CMD_OK;
}

/*
 *			P H _ C M D
 *
 *  Package handler for incomming commands.  Do whatever he says.
 */
void
ph_cmd(pc, buf)
register struct pkg_conn *pc;
char			*buf;
{
	struct rt_vls	str;

	rt_vls_init(&str);

	rt_vls_strcpy( &str, buf );

#ifdef XMGED
	(void)cmdline( &str, False );
#else
	(void)cmdline( &str );
#endif

	rt_vls_free( &str );
	if(buf) (void)free(buf);
}

/*
 *			P H _ V L I S T
 *
 *  Package handler for incomming vlist.
 *  Install whatever phantom solids he wants.
 */
void
ph_vlist(pc, buf)
register struct pkg_conn *pc;
unsigned char		*buf;
{
	struct rt_list	vhead;
	struct rt_vls	name;

	rt_vls_init(&name);

	RT_LIST_INIT( &vhead );

	rt_vlist_import( &vhead, &name, buf );

	invent_solid( rt_vls_addr(&name), &vhead, 0x0000FF00L, 0 );

	rt_vls_free( &name );
	if(buf) (void)free(buf);
}
