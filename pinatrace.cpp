#include "gzstream.h"
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include "pin.H"
#include <string>
/**
 * 直接输出程序的所有访存地址
 * **/
KNOB<string> KnobOutputFile(KNOB_MODE_WRITEONCE,    "pintool",
    "o", "pin_mem_trace.out", "specify trace file name");

KNOB<BOOL> KnobTrackStack(KNOB_MODE_WRITEONCE,   "pintool",
                          "ts", "0", "track stack");

#define PAGEINDEX(x) (~0x0 << 5) & (x)
//FILE * trace;
PIN_MUTEX lock;
//ADDRINT lastPage;
std::string filename;

std::map<THREADID, ogzstream *>gzout_map;
// std::map<THREADID, ADDRINT> lastpages;

//非线程安全，必须确保单线程进入
std::ostream *getOfstream(THREADID tid)
{
    std::ostream *out;
    if (gzout_map.find(tid) == gzout_map.end()) 
    {
        char name[128];
        sprintf(name,"%s-%d.gz",filename.c_str(), tid);
        gzout_map[tid] = new ogzstream(name);
    }
    out = gzout_map[tid];
    return out;
}

VOID RecordRMemOps(VOID *ip, VOID * addr, THREADID tid)
{
    RecordRMemOps(ip, addr, tid, 0);
}

VOID RecordWMemOps(VOID *ip, VOID * addr, THREADID tid)
{
    RecordMemOps(ip, addr, tid, 1);
}

// r:0,w:1
VOID RecordMemOps(VOID *ip, VOID * addr, THREADID tid, int rw) 
{
    PIN_MutexLock(&lock);
    std::ostream *out = getOfstream(tid);
    //ADDRINT curPage = PAGEINDEX((ADDRINT)addr);
    ADDRINT curPage = (ADDRINT)addr;
    INT32 col, line;
	std::string filename = "unknown";
	PIN_LockClient();
	PIN_GetSourceLocation((ADDRINT)ip, &col, &line, &filename);
	PIN_UnlockClient();
    *out << std::hex << curPage << " : " << ip 
        << (rw == 0? "R": "W")
        << std::dec << " : " 
        << col << " : " 
        << line << " : " << (filename == "" ? "unknown" : filename)
        << std::endl;
    PIN_MutexUnlock(&lock);
}

// Print a memory read record
// VOID RecordMemRead(VOID * ip, VOID * addr)
// {

//     //fprintf(trace,"%p\n",PAGEINDEX(addr));
// 	ADDRINT curPage = PAGEINDEX((ADDRINT)addr);
//     if (curPage != lastPage)
//     {
//         PIN_MutexLock(&lock);
//         fprintf(trace, "%lx : %p\n", curPage, ip);
//         PIN_MutexUnlock(&lock);
//         lastPage = curPage;
//     }

// }

// Print a memory write record
// VOID RecordMemWrite(VOID * ip, VOID * addr)
// {
//     // fprintf(trace,"%p: W %p\n", ip, addr);
//     //fprintf(trace,"%p\n", PAGEINDEX(addr));
//     ADDRINT curPage = PAGEINDEX((ADDRINT)addr);
//     if (curPage != lastPage)
//     {
//         PIN_MutexLock(&lock);
//         fprintf(trace, "%lx : %p\n", curPage, ip);
//         PIN_MutexUnlock(&lock);
//         lastPage = curPage;
//     }
    
// }

// Is called for every instruction and instruments reads and writes
VOID Instruction(INS ins, VOID *v)
{
    // Instruments memory accesses using a predicated call, i.e.
    // the instrumentation is called iff the instruction will actually be executed.
    //
    // The IA-64 architecture has explicitly predicated instructions. 
    // On the IA-32 and Intel(R) 64 architectures conditional moves and REP 
    // prefixed instructions appear as predicated instructions in Pin.

    if ((INS_IsStackRead(ins) || INS_IsStackWrite(ins)) && !KnobTrackStack)
    {
        return;
    }
    
    UINT32 memOperands = INS_MemoryOperandCount(ins);

    // Iterate over each memory operand of the instruction.
    for (UINT32 memOp = 0; memOp < memOperands; memOp++)
    {
        if (INS_MemoryOperandIsRead(ins, memOp))
        {
            INS_InsertPredicatedCall(
                ins, IPOINT_BEFORE, (AFUNPTR)RecordRMemOps,
                IARG_INST_PTR,
                IARG_MEMORYOP_EA, memOp,
                IARG_THREAD_ID,
                IARG_END);
        }
        // Note that in some architectures a single memory operand can be 
        // both read and written (for instance incl (%eax) on IA-32)
        // In that case we instrument it once for read and once for write.
        if (INS_MemoryOperandIsWritten(ins, memOp))
        {
            INS_InsertPredicatedCall(
                ins, IPOINT_BEFORE, (AFUNPTR)RecordWMemOps,
                IARG_INST_PTR,
                IARG_MEMORYOP_EA, memOp,
                IARG_THREAD_ID,
                IARG_END);
        }
    }
}

VOID Fini(INT32 code, VOID *v)
{
    //fprintf(trace, "#eof\n");
    //fclose(trace);
	for(std::map<THREADID,ogzstream*>::iterator it=gzout_map.begin();
		it!=gzout_map.end();++it)
	{
		ogzstream *out = it->second;
		out->close();
	}
    
    PIN_MutexFini(&lock);
}

/* ===================================================================== */
/* Print Help Message                                                    */
/* ===================================================================== */
   
INT32 Usage()
{
    PIN_ERROR( "This Pintool prints a trace of memory addresses\n" 
              + KNOB_BASE::StringKnobSummary() + "\n");
    return -1;
}

/* ===================================================================== */
/* Main                                                                  */
/* ===================================================================== */

int main(int argc, char *argv[])
{
    if (PIN_Init(argc, argv)) return Usage();
    filename = KnobOutputFile.Value();
    
    PIN_MutexInit(&lock);
    //lastpages = new std::map<THREADID, ADDRINT>();
    gzout_map = std::map<THREADID, ogzstream *>();
    //out_map = new std::map<THREADID, std::ofstream *>();
                             
    //trace = fopen(KnobOutputFile.Value().c_str(), "w");
	PIN_InitSymbols();
    INS_AddInstrumentFunction(Instruction, 0);
    PIN_AddFiniFunction(Fini, 0);

    // Never returns
    PIN_StartProgram();
    
    return 0;
}
