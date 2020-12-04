//+------------------------------------------------------------------+
//|                                                    Voldemort.mq4 |
//+------------------------------------------------------------------+
#property copyright   "Jussi Niskanen"
//#property link        
#property description "Volume Demonstration"
#property strict

//--- indicator settings------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 clrGold
#property indicator_color2 clrRed
#property indicator_color3 clrBlue

//---Compiler directives
#define debug

//--- input parameters--------------
input int   Periods = 12;
input color PowerColor = clrGold;
input color UpColor = clrDeepSkyBlue;
input color DnColor = clrRed;

//----------------------------------
struct   summary
  {int      totcnt;
   double    rsum;
   double    bsum;
   double   rcnt;
   double   bcnt;
   double    max;
   double    min;
  };
//Data on structure for posibility
//of more complicated dataformat in future
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

//--- global variables--------------
int      secs;
int      per;
color    obj_up_color;
color    obj_dn_color;
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

data_header head;
data        dat;

//----------------------------------
summary  hist;
summary  day;
summary  perios;



//+------------------------------------------------------------------+
//| Voldemort indicator initialization function                      |
//+------------------------------------------------------------------+
int OnInit()
  {

//---- indicator buffers
IndicatorBuffers(3);

SetIndexBuffer(0,Power);
SetIndexStyle(0,DRAW_LINE,EMPTY,1,PowerColor);
SetIndexLabel(0,"Suolinkainen");
ArraySetAsSeries(Power,true);
   
SetIndexBuffer(1,Max);
SetIndexStyle(1,DRAW_LINE,EMPTY,1,UpColor);
SetIndexLabel(1,"Upper");
ArraySetAsSeries(Max,true);
   
SetIndexBuffer(2,Min);
SetIndexStyle(2,DRAW_LINE,EMPTY,1,DnColor);
SetIndexLabel(2,"Downer");   
ArraySetAsSeries(Min,true);
   
//--- indicator settings
IndicatorDigits(0);
IndicatorShortName("Suolinkainen");
//---------------------------------

//--- set initial values for global variables
secs              = PeriodSeconds();
obj_up_color      = UpColor;
obj_dn_color      = DnColor;
per               = Periods;
terminal_data_path=TerminalInfoString(TERMINAL_DATA_PATH);
datafile          ="Suolinkainen"+Symbol()+ChartPeriod(0)+".bin";
objectfile        ="Voldemort"+Symbol()+".bin";
                       
   obj_file_handle  = FileOpen(objectfile,FILE_READ|FILE_CSV);   
//   Print("loading objects from file:",objectfile," handle:",obj_file_handle);
      if(obj_file_handle!=INVALID_HANDLE) 
     { 
      //--- read all data from the file to the array 
/*      FileReadArray(data_file_handle,data_buffer); 
      //--- receive the array size 
      int size=ArraySize(data_buffer); 
      //--- print data from the array 
      for(int i=0;i<size;i++) 
         Power[i]   = data_buffer[i].power;
         Min[i]         = data_buffer[i].min;
         Max[i]         = data_buffer[i].max;
*///      Print("Total data = ",size); 
      //--- close the file 
      FileClose(obj_file_handle); 
     } 
//   else Print("Init: Invalid file handle. Error: ",GetLastError());


   hist = shift_all(Time[0],secs,true);
//--- Done
   return(INIT_SUCCEEDED);
   }
//------------------------------------------------------+
//OnInit ends                                           +
//------------------------------------------------------+
/////////////////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------+
//    OnCalculate                                       +
//------------------------------------------------------+
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
string   value_str;
double    len;
double    len_old;
color    clr   = 0;
long    lots  = 0;

//---------------------------------------------------+
//    Waiting for all the data onto the Chart        +
//---------------------------------------------------+
if(prev_calculated==0)
   {
   volume_old  = tick_volume[0];
   close_old   = close[0];
   first       = true;
   return rates_total;
   }
//---------------------------------------------------+
//    All the bars are now loaded                    +
//--- Firstly load Voldemort's objects in place------+
if(first)
  {
   shift_all(Time[0],1,false);
   
   
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
//    Read header for next fragment                +
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
      Print("New fragment. Size of datafile:",FileSize(data_file_handle),". Pointer to new data_header: ",data_header_pointer);
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
//   New Bar                                         +
//---------------------------------------------------+
if(prev_calculated < rates_total)
   {
   volume_old        = 0;
   shift_all(Time[0],1,false);

//---------------------------------------------------+
//   Pick maximum and minmum values of indicator     +
//---------------------------------------------------+
   int j =2;
   while(Power[j]<Power[1] && j<=per)j++;
   if(Power[j]>=Power[1]&&Power[j]<EMPTY_VALUE)
      {
      for(int i=j;i>0;i--)Max[i]=Power[j];
      }
      else  for(int i=j;i>0;i--)Max[i]=Power[1];
   j =2;
   while(Power[j]>Power[1] && j<=per)j++;
   if(Power[j]<=Power[1])
      {
      for(int i=j;i>0;i--)Min[i]=Power[j];
      }
      else  for(int i=j;i>0;i--)Min[i]=Power[1];
//-----------------------------------------------------+
//   Save Suolinkainen's new data to file              +
//-----------------------------------------------------+
dat.power=Power[1];
head.cnt++;
data_file_handle = FileOpen(datafile,FILE_READ|FILE_WRITE|FILE_BIN);
if(data_file_handle != INVALID_HANDLE)
   {
   FileSeek(data_file_handle,data_header_pointer,SEEK_SET);
   uint bytes = FileWriteStruct(data_file_handle,head);
   if (bytes!=sizeof(data_header)) 
      { 
      Print("Write err. Bytes=",bytes," Error: ",GetLastError()); 
      //--- close the file 
      FileClose(data_file_handle); 
      } 
   FileSeek(data_file_handle,0,SEEK_END);
   bytes = FileWriteStruct(data_file_handle,dat);
   if (bytes!=sizeof(data)) 
      { 
      Print("Write err. Bytes=",bytes," Error: ",GetLastError()); 
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
////////////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------+
//    Level object calculations                              +
//-----------------------------------------------------------+
double   rect_price  = NormalizeDouble(close_old,Digits-1);//StringToDouble(name);
string   name        = DoubleToString(rect_price,Digits-1);
double   price_diff  = close[0] - close_old;
double   pips        = round(price_diff*MathPow(10,Digits));
if (price_diff > 0) lots = volume_old - tick_volume[0];   //Price raises-> lots < 0, lenght grows to right
if (price_diff < 0) lots = tick_volume[0] - volume_old;   //Price falls -> lots > 0, lenght grows to left
                   
   volume_old= tick_volume[0];
   close_old = close[0];


   if(!ObjectCreate(name,OBJ_RECTANGLE,0,time[0]+(secs),rect_price,time[0]+(secs*lots),rect_price))
     {
      if (GetLastError()==ERR_OBJECT_ALREADY_EXISTS)
      { 
       len_old     = MathRound((ObjectGet(name,OBJPROP_TIME1) - ObjectGet(name,OBJPROP_TIME2))/secs);    
       ObjectSet(name,OBJPROP_TIME2,ObjectGet(name,OBJPROP_TIME2)-(secs*lots));
       len         = MathRound((ObjectGet(name,OBJPROP_TIME1) - ObjectGet(name,OBJPROP_TIME2))/secs);
         }
         else //Error is not: "Object already exist"
            Print(__FUNCTION__,": failed to create a rectangle! Error code = ",GetLastError());
         }  //Existing object modified
//--- New object -----------------------------------------------------     
      else
     {
      len_old = 0;
      len         = MathRound((ObjectGet(name,OBJPROP_TIME1) - ObjectGet(name,OBJPROP_TIME2))/secs);
      //--- set the style of rectangle lines
      ObjectSet(name,OBJPROP_STYLE,STYLE_SOLID);
      //--- set width of the rectangle lines
      ObjectSet(name,OBJPROP_WIDTH,1);
      //--- display in the foreground (false) or background (true)
      ObjectSet(name,OBJPROP_BACK,false);

     }
//--- New object end -------------------------------------------------

//---check for historial values and changing props--------
   if(len == 0 && len_old > 0){hist.bcnt--;hist.bsum = hist.bsum + lots;}
   if(len == 0 && len_old < 0){hist.rcnt--;hist.rsum = hist.rsum + lots;}
     
   if(len > 0)//is blue
      {
       clr   = obj_up_color;
         if(len > hist.max)hist.max = len;
         if(len_old < 0)//new blue
            {
//               Print("RED to BLUE: ",hist.rcnt,", blues: ",hist.bcnt);
               hist.bcnt++;
               hist.rcnt--;
               hist.rsum = hist.rsum - len_old;
               hist.bsum = hist.bsum + len;
               }
                 else //len_old >= 0
                 {
                  hist.bsum = hist.bsum + lots;
                  if(len_old == 0)hist.bcnt++;
                 } //end new blue
                
         }//is blue end
   if(len < 0)//is red
      {
       clr   = obj_dn_color;
         if(len < hist.min)hist.min = len;
         if(len_old > 0)//new red
            {
//               Print("BLUE to RED ",hist.rcnt,", blues: ",hist.bcnt);
               hist.rcnt++;
               hist.bcnt--;
               hist.bsum = hist.bsum - len_old;
               hist.rsum = hist.rsum + len;
               }
                 else //len_old <= 0
                 {
                  hist.rsum = hist.rsum + lots;
                  if(len_old == 0) hist.rcnt++;
                 } //end new red

         }
   
Power[0] = hist.bsum + hist.rsum;
//Print("Power[0]: ",Power[0]);
//--Saving the object into file

//---Set objects tooltip
   hist.totcnt = ObjectsTotal();  
   value_str   = DoubleToString(len,0);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Voldemort\nLevel:"+name+"\nValue:"+value_str);
   Comment ("Voldemort   : ",DoubleToStr(hist.totcnt,0)," Levels, Sum: ",DoubleToStr(Power[0],0),"\n",
            "Reds total   : ",DoubleToStr(hist.rsum,0)," on ",DoubleToStr(hist.rcnt,0)," levels.\n",
            "Blues total  :  ",DoubleToStr(hist.bsum,0)," on ",DoubleToStr(hist.bcnt,0)," levels.\n",
            "Range        : ",DoubleToStr(hist.min,0),"...",DoubleToStr(hist.max,0),"\nLast @",
            name,": Value: ",value_str,"\n",
            "Pips: ",(int)pips," Lots: ",lots);
   
//---Set objects color
   ObjectSet(name,OBJPROP_COLOR,clr);
   return (rates_total);
   }
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
  
void OnDeinit(const int reason)
   {
   shift_all(Time[0],(double)1/secs,false);
   string text=""; 

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

   }
//---------------------------------------------------------------------------
//----------------------------------------------------------
//      Reposition All Grafical Objects
//----------------------------------------------------------
summary   shift_all(datetime new_time,double scale,bool oninit)  
   {
   
     int       obj_total=ObjectsTotal();
     string    name;
     string    lots_str;
     datetime  new_start;
     datetime  new_end;
     
     summary   sum={0,0,0,0,0,0,0};
     
     for(int i=0;i<obj_total;i++)
      {
      name        = ObjectName(i);
      double     lots_cum    = MathRound(ObjectGet(name,OBJPROP_TIME1) - ObjectGet(name,OBJPROP_TIME2));
      lots_str    = DoubleToString(lots_cum,0);
      new_start   = new_time;
      new_end     = new_start - (int)(lots_cum*scale);
      
         if(!ObjectSet(name,OBJPROP_TIME1,new_start) || !ObjectSet(name,OBJPROP_TIME2,new_end))
         {
            Print(__FUNCTION__,": failed positioning object's anchor point! Error = ",GetLastError());
            sum.totcnt = false;
            return sum;
         }
         else 
         {
         if(oninit)
         {
          if(lots_cum > 0)//blue level
          {
               sum.bcnt++;
               sum.bsum = sum.bsum + lots_cum;
               
               if(lots_cum > sum.max)sum.max = lots_cum;
               }//blue level end
               
          if(lots_cum < 0) //red level
          {
               sum.rcnt++;
               sum.rsum = sum.rsum + lots_cum;
               
               if(lots_cum < sum.min)sum.min = lots_cum;
               }//red level end
               
//          lots_str = DoubleToString(lots_cum,0);
          ObjectSetString(0,name,OBJPROP_TOOLTIP,"Voldemort\nLevel:"+name+"\nValue:"+lots_str);
          }//oninit end

         }
      }  //for
     ChartRedraw(0);
      sum.totcnt = obj_total;
      
      return sum;
 } 
//-----------end shift_all--------------------------------------------
