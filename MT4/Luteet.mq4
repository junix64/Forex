//+------------------------------------------------------------------+
//|                                                    Voldemort.mq4 |
//+------------------------------------------------------------------+
#property copyright   "junix64"
//#property link        
#property description "Power of Volume"
#property strict

//--- indicator settings------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 clrBlue
#property indicator_color2 clrGold
#property indicator_color3 clrGold
#property indicator_color4 clrRed

//---Compiler directives
//#define debug

//--- input parameters--------------
input int   Periods = 20;

//----------------------------------
struct   summary
  {
   double   cum;
/*   int      rcnt;
   int      bcnt;
   double   max;
   double   min;
*/
  };
struct   data
  {
   double   power;
  };
  
struct   data_header
  {
   datetime time;
   int   timeframe;
   int   cnt;
  };
 
//---- buffers----------------------
double   Power[];
double   Min[];
double   Max[];
double   Trend[];

//--- global variables--------------
int      secs;
color    upper_color;
color    downer_color;
long     volume_old;
double   close_old;
bool     first;

//---------------------------------
string   datafile;
string   objectfile;
string   terminal_data_path;
int      obj_file_handle;
int      data_file_handle;
ulong    data_header_pointer;
double   lastdata;

data_header head;
data        dat;

//summary  hist;
double   cum;
double   x_variance;
int      per=Periods;
double   mid=per/2;


//+------------------------------------------------------------------+
//| Power of Volume indicator initialization function                      |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- indicator buffers
   SetIndexBuffer(0,Power);
   SetIndexStyle(0,DRAW_LINE,EMPTY,1);
   SetIndexLabel(0,"Power");
   ArraySetAsSeries(Power,true);
   ArrayInitialize(Power,0);
   
   SetIndexBuffer(1,Max);
   SetIndexStyle(1,DRAW_LINE,EMPTY,1);
   SetIndexLabel(1,"Max");
   ArraySetAsSeries(Max,true);
   ArrayInitialize(Max,0);
   
   SetIndexBuffer(2,Min);
   SetIndexStyle(2,DRAW_LINE,EMPTY,1);
   SetIndexLabel(2,"Min");   
   ArraySetAsSeries(Min,true);
   ArrayInitialize(Min,0);

   SetIndexBuffer(3,Trend);
   SetIndexStyle(3,DRAW_LINE,EMPTY,1);
   SetIndexLabel(3,"Trend");   
   ArraySetAsSeries(Trend,true);
   ArrayInitialize(Trend,0);

//--- indicator settings
   IndicatorDigits(0);
   IndicatorShortName("Luteet ("+string(Periods)+")");   
//--- set initial values for global variables
   secs             = PeriodSeconds();
   cum              = 0;
   datafile          ="Heisimato"+Symbol()+string(ChartPeriod(0))+".bin";
   for(int i=0;i<per;i++)x_variance+=MathPow(i-mid,2);

   
//--- Done
   return(INIT_SUCCEEDED);
   }//OnInit ends
//---------------------------------------------------------------------------------
// Calculations for Power
//---------------------------------------------------------------------------------
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])

   {
double   price_diff  = close[0] - close_old;
double   pips        = price_diff*MathPow(10,Digits); 
double   lots=0;
//---First Bar ----------------------------------------------
    if(prev_calculated==0)
    {
      volume_old  = tick_volume[0];
      close_old   = close[0];
      first       = true;
      return rates_total;
    }
//--- First Bar End ---------------------------------+
///////////////////////////////////////////////////////////////

//---------------------------------------------------+
//--- All the bars are now loaded                    +
//--- Firstly putting old data in place              +
//---------------------------------------------------+
if(first)
  {
//--------------------------------------------------------------+
//   Loading previously saved Suolinkainen's data from file     +
//--------------------------------------------------------------+
   data_file_handle = FileOpen(datafile,FILE_READ|FILE_WRITE|FILE_BIN);
   if(data_file_handle!=INVALID_HANDLE)
      {
      //ArraySetAsSeries(data_buffer,true);
      ulong filesize = FileSize(data_file_handle);
      ulong fpointer = FileTell(data_file_handle);
      Print("Loading data from file:",datafile," File Size:",filesize," FPointer on:",fpointer);
      FileSeek(data_file_handle,0,SEEK_SET);
      int j=0; //+-- just for counting purposes when debugging ---- +
   
   
//------------------------------------------------+
//    Reading fragments saved earlier             +
//------------------------------------------------+
            
      while(!FileIsEnding(data_file_handle))
         {
//------------------------------------------------+      
//    Read header for next fragment               +
//------------------------------------------------+
         uint bytesread=FileReadStruct(data_file_handle,head);
         if( bytesread!=sizeof(data_header))
            { 
            Print("Error reading header[",j,"]. Error ",GetLastError()); 
            break; //No header, break while readin more data
            }
            j++;
               #ifdef debug
                  fpointer=FileTell(data_file_handle);
                  Print("head[",j,"].time:",TimeToString(head.time),
                        " .cnt:",head.cnt," FPointer:",fpointer);
               #endif
     
//-------------------------------------------------+
//    Checking fragment's header                   +
//-------------------------------------------------+
         int   startindex  = iBarShift(NULL,0,head.time,true);
         ulong size_of_fragment  = head.cnt*sizeof(data);
         if(!startindex || head.cnt==0 || head.timeframe != secs)//Nothing to load onto this chart
            {
            Print("Fragment [",j,"] not shown on this chart or zero size.");
            FileSeek(data_file_handle,size_of_fragment,SEEK_CUR);
            continue;//Nothing to read in this fragment. Going to next header
            }
//-------------------------------------------------+
//    Loading fragment's data to indicator buffer  +
//-------------------------------------------------+
         else
            {
            int   startpoint  = startindex-head.cnt;
            for(int i=startindex;i>startpoint;i--)
              {
               data   d;
               FileReadStruct(data_file_handle,d,sizeof(d));
               Power[i]=d.power;
               //hist.cum=Power[i];
               cum=Power[i];
              }
            
            #ifdef  debug
            Print(head.cnt," values loaded. From Power[",startpoint,"] to Power[",startindex,"]. Values: ",Power[startindex],"; ",Power[startpoint+1],
                        " FPointer: ",FileTell(data_file_handle)); 
            #endif 
            }//there was something to load
               
         }//EOF  reached {while(!FileIsEnding(data_file_handle))}

//-------------------------------------------------------+
//    Now starting new fragment for current session      +
//-------------------------------------------------------+             
      head.time   = TimeCurrent();
      head.timeframe=secs;
      head.cnt    = 0;
      data_header_pointer = FileTell(data_file_handle);
      FileWriteStruct(data_file_handle,head);
      #ifdef debug
      Print("New fragment. Size of datafile:",FileSize(data_file_handle),". Pointer to new data_header: ",data_header_pointer);
      #endif 
      //--- close the file
      FileFlush(data_file_handle);
      FileClose(data_file_handle);
   } // Valid file handle  {if(data_file_handle!=INVALID_HANDLE)}
      else  //---Invalid file handle
      { 
      Print("Init: Invalid datafile handle. Error: ",GetLastError()); 
      }
   first = false;
   }
//---------------------------------------------------+
//    End First Tick                                 +
//---------------------------------------------------+ 
//////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------+

//---------------------------------------------------+
//   New Bar                                         +
//---------------------------------------------------+
if(prev_calculated < rates_total)
   {
   volume_old        = 0;
//-----------------------------------------------------+
//   Save Suolinkainen's new data to file              +
//-----------------------------------------------------+
dat.power=Power[1];
head.cnt++;
data_file_handle = FileOpen(datafile,FILE_READ|FILE_SHARE_READ|FILE_WRITE|FILE_BIN);
if(data_file_handle != INVALID_HANDLE)
   {
   FileSeek(data_file_handle,data_header_pointer,SEEK_SET);
   uint bytes = FileWriteStruct(data_file_handle,head);
   if (bytes!=sizeof(data_header)) 
      { 
      Print("Write error when increasing head.cnt. Bytes=",bytes," Error: ",GetLastError()); 
      //--- close the file 
      FileClose(data_file_handle); 
      } 
   FileSeek(data_file_handle,0,SEEK_END);
   bytes = FileWriteStruct(data_file_handle,dat);
   if (bytes!=sizeof(data)) 
      { 
      Print("Write error when adding new data. Bytes=",bytes," Error: ",GetLastError()); 
      //--- close the file 
      FileClose(data_file_handle); 
      } 
   #ifdef debug
   data d;
   FileSeek(data_file_handle,-sizeof(dat),SEEK_CUR);
   FileReadStruct(data_file_handle,d,sizeof(d));
   Print("head.cnt:",head.cnt," head.time:",TimeToString(head.time),
         " FPointer:",FileTell(data_file_handle)," HPointer:",data_header_pointer,
         " Data from file: ",d.power);
   #endif 
   FileFlush(data_file_handle);
   FileClose(data_file_handle);
   }//File hanle is valid
   else Print("New Bar: Invalid file handle. Error:",GetLastError());
   }
//-----------------------------------------------------------+
//    End New Bar                                            +
//-----------------------------------------------------------+

//--- Main calculations --------------------------------------

if (price_diff > 0) lots = (int)tick_volume[0] - (int)volume_old;   //Price raises-> lots > 0
if (price_diff < 0) lots = (int)volume_old - (int)tick_volume[0];  //Price falls -> lots < 0
                     
   volume_old = tick_volume[0];
   close_old = close[0];
   cum += lots;
   Power[0] = cum;
//---------------------------------------------------+
//   Pick maximum and minmum values of indicator     +
//---------------------------------------------------+
double   k=0;
double   m=0;
int      l=0;
int      n=0;
//----------------------------------------------------
double   powers=0;
double   avr=0;
double   squarsum=0;
double   mfactor=0;
//----------------------------------------------------
double   prices=0;
double   avr_pr=0;
double   squarsum_pr=0;
double   mfactor_pr=0;

for(int j=0;j<per;j++)
{
   if(Power[j]<EMPTY_VALUE)
   {
      double po=Power[j];
      if(po>Power[0]+(j*k))
         {
         k=(po-Power[0])/j;
         l=j+1;
         }
      if(po<Power[0]+(j*m))
         {
         m=(po-Power[0])/j;
         n=j+1;
         }
      powers+=po;
   }
   else
      {
      powers+=(powers/(j+1));
      }
   prices+=Close[j];
}
   avr=powers/per;
   avr_pr=prices/per;
   
   for(int i=0;i<per;i++)
      {
      double sift_x = mid-double(i);
      if(Power[i]<EMPTY_VALUE)   squarsum+=sift_x*(Power[i]-avr);
      squarsum_pr+=sift_x*(Close[i]-avr_pr);
      }
      
   mfactor = squarsum/x_variance;
   mfactor_pr = squarsum_pr/x_variance;
   //Print("mf= "+mfactor);
   
   for(int i=per;i>=0;i--)
      {
      if(i<l) Max[i]=Power[0]+(i*k);
         else Max[i]=EMPTY_VALUE;
      if(i<n) Min[i]=Power[0]+(i*m);
         else Min[i]=EMPTY_VALUE;
      if(i<per) Trend[i]=avr-((i-mid)*mfactor);
         else Trend[i]=EMPTY_VALUE;
      }
    
//----------------------------------------------------------------  
   return (rates_total);
   }
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
  
void OnDeinit(const int reason)
   {
/*   string text=""; 
   switch(reason) 
     { 
      case REASON_ACCOUNT: 
         text="Account was changed";break; 
      case REASON_CHARTCHANGE: 
         text="Symbol or timeframe was changed";break; 
      case REASON_CHARTCLOSE: 
         text="Chart was closed";break; 
      case REASON_PARAMETERS: 
         text="Input-parameter was changed";break; 
      case REASON_RECOMPILE: 
         text="Program "+__FILE__+" was recompiled";break; 
      case REASON_REMOVE: 
         text="Program "+__FILE__+" was removed from chart";break; 
      case REASON_TEMPLATE: 
         text="New template was applied to chart";break;
      case REASON_CLOSE: 
         text="Terminal was closet";break;
      case REASON_INITFAILED: 
         text="Init faild";break; 
      default:text="Another reason";
      }//switch 
      
//      Print("DeInit reason: ",text);

*/   }
//---------------------------------------------------------------------------