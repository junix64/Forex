//+------------------------------------------------------------------+
//|                                                    Voldemort.mq4 |
//+------------------------------------------------------------------+
#property copyright   "Jussi Niskanen"
//#property link        
#property description "Volume Demonstration"
#property strict

//--- indicator settings------------
#property indicator_chart_window
#property indicator_buffers 3

//---Compiler directives
#define debug

input int   Periods = 12;
input color UpColor = clrDeepSkyBlue;
input color DnColor = clrRed;

struct   summary
  {int      totcnt;
   double    rsum;
   double    bsum;
   double   rcnt;
   double   bcnt;
   double    max;
   double    min;
  };

//--- global variables--------------
int      secs;
int      per;
long     volume_old;
double   close_old;
bool     first;

//----------------------------------
summary  hist;
summary  day;
summary  perios;



//+------------------------------------------------------------------+
//| Voldemort indicator initialization function                      |
//+------------------------------------------------------------------+
int OnInit()
  {

IndicatorShortName("Voldemort");
//---------------------------------

//--- set initial values for global variables
secs              = PeriodSeconds();
per               = Periods;

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
   first=false;
   
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
if (price_diff > 0) lots = tick_volume[0] - volume_old;   //Price raises-> lots < 0, lenght grows to right
if (price_diff < 0) lots = volume_old - tick_volume[0];   //Price falls -> lots > 0, lenght grows to left
                   
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
       clr   = UpColor;
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
       clr   = DnColor;
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

//---Set objects tooltip
   double power = hist.bsum + hist.rsum;
   hist.totcnt = ObjectsTotal();  
   value_str   = DoubleToString(len,0);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Voldemort\nLevel:"+name+"\nValue:"+value_str);
   Comment ("Voldemort   : ",DoubleToStr(hist.totcnt,0)," Levels, Sum: ",DoubleToStr(power,0),"\n",
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
Comment("");
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
