/* 
 * gfxroute version 0.2 by megacz@usa.com
 *
 * This proggy allows to control 'AllocBitMap()' and 'AllocRaster()'
 * of 'fscreen' and 'CyberBugFix' respectively. Some portions of code
 * are from 'Scout' sources.
 *
 * [04-Jul-2008]  0.2  Smaller, Cleaner, Better.
*/

#define __USE_SYSBASE 1

#include <proto/dos.h>
#include <dos/rdargs.h>
#include <dos/dosextens.h>
#include <dos/dostags.h>
#include <utility/tagitem.h>
#include <proto/exec.h>
#include <exec/execbase.h>
#include <exec/types.h>
#include <exec/ports.h>
#include <exec/tasks.h>
#include <exec/io.h>
#include <proto/intuition.h>
#include <intuition/intuition.h>
#include <intuition/intuitionbase.h>
#include <devices/timer.h>
#include <string.h>
#include "showpatch.h"

#define TEMPLATE " *** template: gfxroute <[raster][+bitmap[-cyber]]/s> [chip|fast/s] [timeout/n]\n"
#define ITERATE_LIST(list, type, node)  for (node = (type)((struct List *)(list))->lh_Head; ((struct Node *)node)->ln_Succ; node = (type)((struct Node *)node)->ln_Succ)
#define FLAG_IS_SET(mask, flag) (((mask) & (flag)) == (flag))
#define FLAG_IS_CLEAR(mask, flag) (((mask) & (flag)) == 0)
#define BIT_IS_CLEAR(mask, bit) FLAG_IS_CLEAR(mask, 1 << bit)
#define SET_FLAG(mask, flag) (mask) |= (flag)
#define CLEAR_FLAG(mask, flag) (mask) &= ~(flag)
#define ZERO ((BPTR)0L)
#define TNSIZE 256
#define ITOABUF (4 * 8 * 302 / 1000 + 1 + 1)

int main (void)
{
  struct ExecBase *SysBase = (*((struct ExecBase **) 4));
  struct IntuitionBase *IntuitionBase;
  struct DosLibrary *DOSBase;
  struct RDArgs *rdargs;
  struct PatchPort *pp;
  struct LibPatchList *ll;
  struct Task *mytask;
  struct Screen *screen;
  struct MsgPort *Timer_MP;
  struct timerequest *Timer_Req;
  ULONG signals;
  ULONG TimerMask;
  ULONG absOffset;
  long argv[4];
  long sw_raster = 0;
  long sw_bitmap = 0;
  long sw_cyberg = 1;
  long sw_memory = 1;
  long rc = 5;
  char ppFlag[2] = {'?',NULL};
  BPTR console;
  char *rev_memtype = "chip";
  char *rev_functype;
  char rev_cmdline[TNSIZE+2];
  char *rev_procbstrptr;
  long rev_tnsize;
  long rev_tncnt;
  long rev_strlen;
  ULONG scr_lock;
  long scr_scrcount = 0;
  char *scr_scrcntptr;
  char scr_scrcntbuf[ITOABUF];
  long sub_timeout;
  char *sub_timeoutptr;
  char sub_timeoutbuf[ITOABUF];


  if ((IntuitionBase = (struct IntuitionBase *)OpenLibrary("intuition.library", 0L)) != NULL)
  {
    if((DOSBase=(struct DosLibrary *)OpenLibrary("dos.library", 36L)) != NULL)
    {    
      rev_cmdline[0]='\0';
      rev_cmdline[TNSIZE+1]='\0';
  
      console = Output();
  
      memset((char *)argv, 0, sizeof(argv));
  
      rdargs = ReadArgs("FUNCTYPE/A,MEMTYPE,TIMEOUT/N,SCRCOUNT/N", argv, NULL);
  
      if (rdargs)
      {
        if (argv[2])
        {
          if ((*(LONG *)argv[2] <= 0) || (*(LONG *)argv[2] > 120))
          {
            FPuts(console," *** timeout value should be in range of 1 to 120 seconds.\n");
            goto skip;
          }  
        }

        if (argv[1])
        {
          if (stricmp((char *)argv[1],"chip") == NULL)
          {
            sw_memory = 0;
            rev_memtype = "fast";
          }
          else if (stricmp((char *)argv[1],"fast") == NULL)
          {
            sw_memory = 1;
            rev_memtype = "chip";
          } 
          else
          {
            FPuts(console,TEMPLATE);
            goto skip;
          }
        }
  
        if (argv[0])
        {
          if (stricmp((char *)argv[0],"raster") == NULL)
          {
            sw_raster = 1;
          }
          else if (stricmp((char *)argv[0],"bitmap") == NULL)
          {
            sw_bitmap = 1;
          }
          else if ((stricmp((char *)argv[0],"raster+bitmap") == NULL) ||
                  (stricmp((char *)argv[0],"bitmap+raster") == NULL))
          {
            sw_raster = 1;
            sw_bitmap = 1;
          } 
          else if (stricmp((char *)argv[0],"bitmap-cyber") == NULL)
          {
            sw_bitmap = 1;
            sw_cyberg = 0;
          }
          else if ((stricmp((char *)argv[0],"raster+bitmap-cyber") == NULL) ||
                  (stricmp((char *)argv[0],"bitmap-cyber+raster") == NULL))
          {
            sw_raster = 1;
            sw_bitmap = 1;
            sw_cyberg = 0;
          }
          else
          {
            FPuts(console,TEMPLATE);
            goto skip;
          }
  
          rev_functype = (char *)argv[0];


          if (argv[3])
          {
            if (!(Timer_MP=CreateMsgPort()))
            {
              goto skip;
            }
            else
            {
              if (!(Timer_Req=(struct timerequest *)CreateIORequest(Timer_MP,sizeof(struct timerequest))))
              {
                DeleteMsgPort(Timer_MP);
                goto skip;
              }
              else
              {
                if (OpenDevice("timer.device",1,(struct IORequest *)Timer_Req,0))
                {
                  DeleteIORequest((struct IORequest *)Timer_Req);
                  DeleteMsgPort(Timer_MP);
                  goto skip;
                }
              }
            }
          
            TimerMask=(1L << (Timer_MP->mp_SigBit));
          
            for(rev_tncnt = 0; rev_tncnt < *(LONG *)argv[2]; rev_tncnt++)
            {
              Timer_Req->tr_node.io_Command=9;
              Timer_Req->tr_time.tv_secs=1UL;
              Timer_Req->tr_time.tv_micro=0UL;
              SendIO((struct IORequest *)Timer_Req);
              signals=Wait(TimerMask | SIGBREAKF_CTRL_C);
              while(GetMsg(Timer_MP));

              scr_scrcount = 0;
              scr_lock = LockIBase(0);
              screen = IntuitionBase->FirstScreen;
        
              while (screen)
              {
                screen = screen->NextScreen;
                 scr_scrcount++;
              }
        
              UnlockIBase(scr_lock);
            
              if ((signals & SIGBREAKF_CTRL_C) || (scr_scrcount > *(LONG *)argv[3]))
                break;
            }
          
            AbortIO((struct IORequest *)Timer_Req);
            WaitIO((struct IORequest *)Timer_Req);
            CloseDevice((struct IORequest *)Timer_Req);
            DeleteIORequest((struct IORequest *)Timer_Req);
            DeleteMsgPort(Timer_MP); 

            if (signals & SIGBREAKF_CTRL_C)
            {
              FPuts(console," *** process terminated!\n");
              goto skip;
            }

            if (argv[2])     
              argv[2] = NULL;
          }

  
          Forbid();
  
          pp = (struct PatchPort *)FindPort(PATCHPORT_NAME);
  
          if (!(pp))
          {
            FPuts(console," *** no 'SaferPatches' found in your system, aborting!\n");
            Permit();
            goto skip;
          }
  
          ITERATE_LIST(&pp->pp_PatchList, struct LibPatchList *, ll)
          {
            struct LibPatchNode *ln;
  
  
            ITERATE_LIST(&ll->ll_PatchList, struct LibPatchNode *, ln)
            {
              struct LibPatchEntry *le;
  
  
              ITERATE_LIST(&ln->ln_PatchList, struct LibPatchEntry *, le)
              {
                absOffset = (ln->ln_Offset)>=0?(ln->ln_Offset):(-ln->ln_Offset);
  
                /* Amiga - looks ulgy isnt it? :) */
                if (  ((stricmp(ll->ll_LibBase->lib_Node.ln_Name,"graphics.library") == NULL) &&
                   ((absOffset == 918) && (((stricmp(le->le_Patcher,"cyberbugfix") == NULL)   &&
                   (sw_cyberg > 0)) || ((stricmp(le->le_Patcher,"fscreen") == NULL)           ||
                   (stricmp(le->le_Patcher,"fscreen.exec") == NULL))) && (sw_bitmap > 0))     ||
                   ((absOffset == 492) && (stricmp(le->le_Patcher,"ramlib") == NULL)          &&
                   (sw_raster >0)))  )
                {
                  rc = 0;

                  if (sw_memory == 0)
                  {
                    if (BIT_IS_CLEAR(le->le_Flags, LEF_DISABLED) &&
                        BIT_IS_CLEAR(le->le_Flags, LEF_REMOVED))
                    {
                      SetFunction(ll->ll_LibBase, ln->ln_Offset, (APTR)&le->le_Jmp);
                      SET_FLAG(le->le_Flags, LEF_DISABLED);
                    }
                  }
                  else
                  {
                    if (FLAG_IS_SET(le->le_Flags, LEF_DISABLED) && 
                        FLAG_IS_SET(le->le_Flags, LEF_REMOVED))
                    {
                      SetFunction(ll->ll_LibBase, ln->ln_Offset, (APTR)le->le_NewEntry);
                      CLEAR_FLAG(le->le_Flags, LEF_DISABLED);
                    }
                  }
    
  
                  if (FLAG_IS_SET(le->le_Flags, LEF_DISABLED))
                    ppFlag[0] = 'D';
                  else
                    if (FLAG_IS_SET(le->le_Flags, LEF_REMOVED))
                      ppFlag[0] = 'R';
                    else
                      ppFlag[0] = 'A';
    
                  FPrintf(console," ### %s  $%08lx  -%04lx  %24s  %s\n",(LONG)ppFlag, 
                         (LONG)le->le_NewEntry, absOffset, (LONG)ll->ll_LibBase->lib_Node.ln_Name, 
                         (LONG)le->le_Patcher);

                }
              }
            }
          }
  
          Permit();
  
          if (rc > 0)
          {
            FPuts(console," *** nothing altered, make sure patches are installed!\n");
          }
          else
          {
            if (argv[2])
            { 
              struct TagItem rev_tags[5];


              rev_tags[0].ti_Tag = SYS_Input;
              rev_tags[0].ti_Data = (BPTR)Open("nil:", MODE_OLDFILE);
              rev_tags[1].ti_Tag = SYS_Output;
              rev_tags[1].ti_Data = (BPTR)Open("nil:", MODE_NEWFILE);
              rev_tags[2].ti_Tag = SYS_Asynch;
              rev_tags[2].ti_Data = TRUE; 
              rev_tags[3].ti_Tag = SYS_UserShell;
              rev_tags[3].ti_Data = TRUE;
              rev_tags[4].ti_Tag = TAG_DONE;
              rev_tags[4].ti_Data = 0;

              mytask = FindTask(0L);
          
              if (mytask->tc_Node.ln_Succ != NULL         &&
                 (mytask->tc_Node.ln_Type == NT_PROCESS))
              {
                struct Process *pr = (struct Process *)mytask;
          
          
                if (mytask->tc_Node.ln_Type == NT_PROCESS && pr->pr_CLI != ZERO)
                {
                  struct CommandLineInterface *cli = (struct CommandLineInterface *)BADDR(pr->pr_CLI);
          
          
                  if (cli->cli_Module != ZERO && cli->cli_CommandName != ZERO)
                  {
                    rev_procbstrptr = BADDR(cli->cli_CommandName);
                    rev_tnsize = TNSIZE;
          
                    if ((long)*rev_procbstrptr < rev_tnsize)
                      rev_tnsize = (long)*rev_procbstrptr;
          
                    rev_procbstrptr++;         
          
                    for(rev_tncnt = 0; rev_tncnt < rev_tnsize; rev_tncnt++)
                      rev_cmdline[rev_tncnt] = (char)*rev_procbstrptr++;
          
                    rev_cmdline[rev_tncnt]='\0';
                  }                
                }
              }
              else
              {
                FPuts(console," *** i have detected that im not a process, any ideas why?\n");
                goto skip;
              }


              scr_lock = LockIBase(0);
              screen = IntuitionBase->FirstScreen;
      
              while (screen)
              {
                screen = screen->NextScreen;
                 scr_scrcount++;
              }
      
              UnlockIBase(scr_lock);

              scr_scrcntbuf[sizeof scr_scrcntbuf - 1] = 0;
              scr_scrcntptr = &scr_scrcntbuf[sizeof scr_scrcntbuf - 1];
            
              do
              {
                *--scr_scrcntptr = (scr_scrcount % 10) + '0';
                scr_scrcount /= 10;
              } while (scr_scrcount);

              sub_timeout = *(LONG *)argv[2];
              sub_timeoutbuf[sizeof sub_timeoutbuf - 1] = 0;
              sub_timeoutptr = &sub_timeoutbuf[sizeof sub_timeoutbuf - 1];
            
              do
              {
                *--sub_timeoutptr = (sub_timeout % 10) + '0';
                sub_timeout /= 10;
              } while (sub_timeout);


              /* Amiga - i wanted to avoid the use of snprintf() */
              rev_strlen=strlen(rev_cmdline);
              if ((rev_strlen + 1) < TNSIZE)
              {
                strcpy(rev_cmdline + rev_strlen, " ");
                rev_strlen=strlen(rev_cmdline);
                if ((rev_strlen + strlen(rev_functype)) < TNSIZE)
                {
                  strcpy(rev_cmdline + rev_strlen, rev_functype);
                  rev_strlen=strlen(rev_cmdline);
                  if ((rev_strlen + 1) < TNSIZE)
                  {
                    strcpy(rev_cmdline + rev_strlen, " ");
                    rev_strlen=strlen(rev_cmdline);
                    if ((rev_strlen + strlen(rev_memtype)) < TNSIZE)
                    {
                      strcpy(rev_cmdline + rev_strlen, rev_memtype);
                      rev_strlen=strlen(rev_cmdline);
                      if ((rev_strlen + 1) < TNSIZE)
                      {
                        strcpy(rev_cmdline + rev_strlen, " ");
                        rev_strlen=strlen(rev_cmdline);
                        if ((rev_strlen + strlen(sub_timeoutptr)) < TNSIZE)
                        {
                          strcpy(rev_cmdline + rev_strlen, sub_timeoutptr);
                          rev_strlen=strlen(rev_cmdline);
                          if ((rev_strlen + 1) < TNSIZE)
                          {
                            strcpy(rev_cmdline + rev_strlen, " ");
                            rev_strlen=strlen(rev_cmdline);
                            if ((rev_strlen + strlen(scr_scrcntptr)) < TNSIZE)
                            {
                              strcpy(rev_cmdline + rev_strlen, scr_scrcntptr);
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              FPuts(console," /// auto mode active, toggle after timeout or on screen open.\n");

              SystemTagList(rev_cmdline, rev_tags);

            }

          }

        }
  
        skip:
        FreeArgs(rdargs);
      }
      else
        FPuts(console,TEMPLATE);
  
      CloseLibrary((struct Library *)DOSBase);
    }
    CloseLibrary((struct Library *)IntuitionBase);
  }

  return rc;
}
