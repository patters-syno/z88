
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

  Copyright (C) 1991-2006, Gunther Strube, gbs@users.sourceforge.net

  This file is part of Mpm.
  Mpm is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by the Free Software Foundation;
  either version 2, or (at your option) any later version.
  Mpm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along with Mpm;
  see the file COPYING.  If not, write to the
  Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

  $Id$

 -------------------------------------------------------------------------------------------------*/



#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <ctype.h>

#include "config.h"             /* compilation constant definitions */
#include "datastructs.h"        /* data structure definitions */
#include "symtables.h"          /* functions to access local/global/extern symbol table data */
#include "libraries.h"          /* functions to manage libraries */
#include "z80_relocate.h"       /* functions to manage Z80 code auto-relocation */
#include "modules.h"            /* functions to manage compiled modules */
#include "errors.h"             /* functions for error reporting and error message definitions */
#include "pass.h"               /* functions for source file management and Pass 1 & 2 */
#include "options.h"            /* functions to cmd line arguments and display of help */


/* local functions */
static void ReleaseFilenames (void);
static void CloseFiles (void);
static void DefineEndianLayout(void);
static int TestAsmFile (void);
static int GetModuleSize (void);


/* global variables */
FILE *srcasmfile, *listfile, *errfile, *objfile, *mapfile, *modsrcfile, *libfile;

long TOTALLINES;
char PAGELEN;
int PAGENO, LINENO;

char *srcfilename, *lstfilename, *objfilename, *errfilename, *libfilename;
const char asmext[] = ".asm", lstext[] = ".lst", defext[] = ".def", binext[] = ".bin";
const char mapext[] = ".map", wrnext[] = ".wrn", errext[] = ".err", libext[] = ".lib", segmbinext[] = ".bn0";
char srcext[5];                 /* contains default source file extension */
char objext[5];                 /* contains default object file extension */
char binfilename[255];          /* -o explicit filename buffer */

long listfileptr;
unsigned char *codearea, *codeptr;
size_t CODESIZE;
unsigned long PC, oldPC;                /* Program Counter */
time_t asmtime;                         /* time of assembly in seconds */
char *date;                             /* pointer to datestring calculated from asmtime */


/* externally defined variables */
extern int ASSEMBLE_ERROR, ERRORS, TOTALERRORS, WARNINGS, TOTALWARNINGS;
extern enum flag datestamp, verbose, useothersrcext, autorelocate;
extern enum flag uselistingfile, createlibrary, asmerror, mpmbin, mapref, createglobaldeffile;
extern enum flag BIGENDIAN, USEBIGENDIAN;
extern libraries_t *libraryhdr;
extern modules_t *modulehdr;
extern module_t *CURRENTMODULE;
extern avltree_t *globalroot, *staticroot;
extern symbol_t *gAsmpcPtr, *__gAsmpcPtr; /* pointer to Assembler PC symbol (defined in global symbol variables) */
extern unsigned char *reloctable;


static void
ReleaseFilenames (void)
{
  if (srcfilename != NULL) free (srcfilename);
  if (lstfilename != NULL) free (lstfilename);
  if (objfilename != NULL) free (objfilename);
  if (errfilename != NULL) free (errfilename);
  srcfilename = lstfilename = objfilename = errfilename = NULL;
}


static void
CloseFiles (void)
{
  if (srcasmfile != NULL) fclose (srcasmfile);
  if (listfile != NULL) fclose (listfile);
  if (objfile != NULL) fclose (objfile);
  if (errfile != NULL) fclose (errfile);
  srcasmfile = listfile = objfile = errfile = NULL;
}


static int
TestAsmFile (void)
{
  struct stat afile, ofile;

  if (datestamp)
    {                           /* assemble only updated files */
      if (stat (srcfilename, &afile) == -1)
        return GetModuleSize ();        /* source file not available, try object file... */
      else if (stat (objfilename, &ofile) != -1)
        if (afile.st_mtime <= ofile.st_mtime)
          return GetModuleSize ();      /* source is older than object module, use object file... */
    }
  if ((srcasmfile = fopen (AdjustPlatformFilename(srcfilename), "rb")) == NULL)
    {                                           /* Open source file */
      ReportIOError (srcfilename);              /* Object module is not found or */
      return -1;                                /* source is has recently been updated */
    }
  fclose(srcasmfile);

  return 1; /* assemble if no datestamp check */
}


static int
GetModuleSize (void)
{
  char modulename[256];
  const char *objwatermark;
  long fptr_modcode, fptr_modname;
  size_t size;

  if ((objfile = OpenObjectFile(objfilename, &objwatermark)) == NULL)
    {
      return -1;
    }
  else
    {
      fseek (objfile, strlen(objwatermark) + 4, SEEK_SET);  /* point at module name file pointer (just after ORG address) */
      fptr_modname = ReadLong (objfile);                    /* get file pointer to module name */
      fseek (objfile, fptr_modname, SEEK_SET);              /* set file pointer to module name */

      size = fgetc (objfile);
      fread (modulename, sizeof (char), size, objfile);     /* read module name */
      modulename[size] = '\0';
      if ((CURRENTMODULE->mname = AllocIdentifier (size + 1)) == NULL)
        {
          ReportError (NULL, 0, Err_Memory);
          return -1;
        }
      else
        strcpy (CURRENTMODULE->mname, modulename);

      fseek (objfile, strlen(objwatermark) + 4+4+4+4+4, SEEK_SET);  /* set file pointer to point at module code pointer file pointer */
      fptr_modcode = ReadLong (objfile);                /* get file pointer to module code */
      if (fptr_modcode != -1)
        {
          fseek (objfile, fptr_modcode, SEEK_SET);      /* set file pointer to module code */
          size = ReadLong (objfile);                    /* read 32 bit integer length of module code */
          if (CURRENTMODULE->startoffset + size > MAXCODESIZE)
            ReportError (objfilename, 0, Err_MaxCodeSize);
          else
            CODESIZE += size;
        }
      fclose (objfile);

      return 0;
    }
}


/* ------------------------------------------------------------------------------------------
   Investigate whether the memory architecture running this assembler
   use Little Endian (low byte - high byte order) or Big Endian (high byte - low byte order)
   ------------------------------------------------------------------------------------------ */
static void
DefineEndianLayout(void)
{
   unsigned long   v = 0x80000000;
   unsigned char   *vp;

   vp = (unsigned char *) &v;      /* point at first byte of signed long word */
   if (*vp == 0x80)
     BIGENDIAN = ON;
   else
     BIGENDIAN = OFF;        /* little endian - low byte, high byte order */
}


/* ------------------------------------------------------------------------------------------
   Main entry of Mpm
   ------------------------------------------------------------------------------------------ */
int
main (int argc, char *argv[])
{
  int asmflag;
  char argument[254];
  int pathsepCount = 0;
  int b;

  DefineEndianLayout();

  USEBIGENDIAN = OFF;           /* for Z80, code generation always use little endian format on integers */

  DefaultOptions();

  libfilename = NULL;
  modsrcfile = NULL;
  CURRENTMODULE = NULL;

  globalroot = NULL;            /* global identifier tree initialized */
  staticroot = NULL;            /* static identifier tree initialized */

  if (DefineDefSym (OS_ID, 1, &staticroot) == NULL)
    exit (1);

  /* Get command line arguments, if any... */
  if (argc == 1)
    {
      prompt ();
      exit (1);
    }
  time (&asmtime);
  date = asctime (localtime (&asmtime));        /* get current system time for date in list file */

  codearea = (unsigned char *) calloc (MAXCODESIZE, sizeof (char));     /* Allocate memory for machine code */
  if (codearea == NULL)
    {
      ReportError (NULL, 0, Err_Memory);
      exit (1);
    }
  CODESIZE = 0;

  PAGELEN = 66;
  TOTALERRORS = 0;
  TOTALWARNINGS = 0;
  TOTALLINES = 0;

  if ((CURRENTMODULE = NewModule ()) == NULL)
    {                                      /* then create a dummy module */
      ReportError (NULL, 0, Err_Memory);   /* this is needed during command line parsing */
      exit (1);
    }
  while (--argc > 0)
    {                           /* Get options first */
      ++argv;

      if ((*argv)[0] == '-')
        SetAsmFlag (((*argv) + 1));
      else
        {
          if ((*argv)[0] == '@')
            if ((modsrcfile = fopen (AdjustPlatformFilename( (*argv + 1) ), "rb")) == NULL)
              ReportIOError ((*argv + 1));
          break;
        }
    }

  ReleaseModules ();            /* Now remove dummy module again, not needed */

  if (!argc && modsrcfile == NULL)
    {
      ReportError (NULL, 0, Err_SrcfileMissing);
      exit (1);
    }

  if (verbose == ON)
    display_options ();         /* display status messages of select assembler options */

  if (useothersrcext == OFF)
    strcpy (srcext, asmext);    /* use ".asm" as default source file extension */

  for (;;)
    {                           /* Module loop */
      srcasmfile = listfile = objfile = errfile = NULL;

      codeptr = codearea;       /* Pointer (PC) to store instruction opcode */
      ERRORS = 0;
      WARNINGS = 0;
      ASSEMBLE_ERROR = -1;      /* General error flag */

      if (modsrcfile == NULL)
        {
          if (argc > 0)
            {
              if ((*argv)[0] != '-')
                {
                  strncpy(argument, *argv, 253);
                  --argc;
                  ++argv;       /* get ready for next filename */
                }
              else
                {
                  ReportError (NULL, 0, Err_IllegalSrcfile);    /* Illegal source file name */
                  break;
                }
            }
          else
            break;
        }
      else
        {
          FetchModuleFilename(modsrcfile, argument);
          if (strlen (argument) == 0)
            {
              fclose (modsrcfile);
              break;
            }
        }

      /* scan filename backwards and truncate extension, if found, but before a pathname separator */
      for (b=strlen(argument)-1; b>=0; b--) {
          if (argument[b] == '\\' || argument[b] == '/') pathsepCount++; /* Ups, we've scanned past the short filename */

          if (argument[b] == '.' && pathsepCount == 0) {
               argument[b] = '\0'; /* truncate file extension */
               break;
          }
      }

      srcfilename = AddFileExtension((const char *) argument, srcext);
      if (srcfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      objfilename = AddFileExtension((const char *) srcfilename, objext);
      if (objfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      if (uselistingfile == ON)
        {
          lstfilename = AddFileExtension((const char *) srcfilename, lstext);
          if (lstfilename == NULL)
            {
              ReportError (NULL, 0, Err_Memory);   /* No more room */
              break;
            }
        }

      errfilename = AddFileExtension((const char *) srcfilename, errext);
      if (errfilename == NULL)
        {
          ReportError (NULL, 0, Err_Memory);   /* No more room */
          break;
        }

      if ((CURRENTMODULE = NewModule ()) == NULL)
        {                       /* Create module data structures for new file */
          ReportError (NULL, 0, Err_Memory);
          break;
        }
      if ((CURRENTFILE = Newfile (NULL, srcfilename)) == NULL)
        break;                  /* Create first file record, if possible */

      if ((asmflag = TestAsmFile ()) == 1)
        {

          PC = oldPC = 0;
          Copy (staticroot, &CURRENTMODULE->localroot, (int (*)()) cmpidstr, (void *(*)()) CreateSymNode);

          gAsmpcPtr = DefineDefSym (ASSEMBLERPC, PC, &globalroot);      /* Create standard '$PC' identifier */
          __gAsmpcPtr = DefineDefSym (__ASSEMBLERPC, PC, &globalroot);  /* 'ASMPC' identifier for compatibility with z80asm */
          if (gAsmpcPtr == NULL || __gAsmpcPtr == NULL)
            {
              ReportError (NULL, 0, Err_Memory);
              return 0;
            }

          AssembleSourceFile ();        /* begin assembly... */

          DeleteAll (&CURRENTMODULE->localroot, (void (*)()) FreeSym);
          DeleteAll (&CURRENTMODULE->notdeclroot, (void (*)()) FreeSym);
          DeleteAll (&globalroot, (void (*)()) FreeSym);

          if (verbose)
            putchar ('\n');     /* separate module texts */
        }
      else if (asmflag == -1)
        break;                  /* file open error - stop assembler */

      ReleaseFilenames ();
    }                           /* for */

  ReleaseFilenames ();
  CloseFiles ();

  if (createlibrary && asmerror == OFF)
    CreateLib ();

  if (createlibrary)
    {
      fclose (libfile);
      if (asmerror)
        remove (libfilename);
      free (libfilename);
      libfilename = NULL;
    }

  if ((asmerror == OFF) && verbose)
    printf ("Total of %ld lines assembled.\n", TOTALLINES);

  if ((asmerror == OFF) && mpmbin)
    LinkModules ();

  if (asmerror == OFF && createglobaldeffile == ON)
    CreateDeffile ();

  if ((TOTALERRORS == 0) && mpmbin)
    {
      if (mapref == ON && mpmbin == ON) WriteMapFile ();
      CreateBinFile ();
    }

  ReleaseFilenames ();
  CloseFiles ();

  DeleteAll (&globalroot, (void (*)()) FreeSym);
  DeleteAll (&staticroot, (void (*)()) FreeSym);

  if (modulehdr != NULL)
    ReleaseModules ();          /* Release module information (symbols, etc.) */

  if (libraryhdr != NULL)
    ReleaseLibraries ();        /* Release library information */
  free (codearea);              /* Release area for machine code */

  if (autorelocate == ON)
    FreeRelocTable();

  ReleasePathInfo();            /* release collected path info (as defined from env. and cmd.line) */

  if (asmerror)
    ReportError (NULL, 0, Err_Status);

  if (TOTALWARNINGS > 0)
    ReportWarning (NULL, 0, Warn_Status);

  if (asmerror)
      return 1;
  else
      return 0;         /* assembler successfully ended */
}
