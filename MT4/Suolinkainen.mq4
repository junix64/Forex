//+------------------------------------------------------------------+
//|                                                    Voldemort.mq4 |
//+------------------------------------------------------------------+
#property copyright   "Jussi Niskanen"
//#property link        
#property description "Power of Volume"
#property strict

//--- indicator settings------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 clrBlue
#property indicator_color2 clrRed
#property indicator_color3 clrGold

//--- input parameters--------------
input int   Periods = 12;

//----------------------------------
struct   summary
  {
   double   cum;
   double   pips;
   int      rcnt;
   int      bcnt;
   double   max;
   double   min;
  };
  
//---- buffers----------------------
double   Power[];
double   Min[];
double   Max[];

//--- global variables--------------
double   secs;
color    upper_color;
color    downer_color;
long     volume_old;
double   close_old;
bool     first;

summary  hist;

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
   
//--- indicator settings
   IndicatorDigits(0);
   IndicatorShortName("Power");   
//--- set initial values for global variables
   secs             = PeriodSeconds();
   hist.cum         = 0;
   hist.pips        =0;
   
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
int      per         = Periods;
double   lots=0;

//---First Bar ----------------------------------------------
    if(prev_calculated==0)
    {
      volume_old  = tick_volume[0];
      close_old   = close[0];
      first       = true;
      return rates_total;
    }
//--- First Bar End ------------------------------------------
//--- All the bars are now loaded
//--- Firstly putting objects in place------------------------
if(first)
  {
  Power[1]=0;
  first = false;
  }
//--- Done ---------------------------------------------------
//---New Bar -------------------------------------------------
    if(prev_calculated < rates_total)
      {
      volume_old        = 0;
      }
//--- End New Bar --------------------------------------------

//--- Main calculations --------------------------------------

if (price_diff > 0) lots = (int)tick_volume[0] - (int)volume_old;   //Price raises-> lots < 0
if (price_diff < 0) lots = (int)volume_old - (int)tick_volume[0];  //Price falls -> lots > 0
                     
   volume_old= tick_volume[0];
   close_old = close[0];
   hist.cum       = hist.cum + lots;
   hist.pips      = hist.pips + pips;
//---check for historial values and changing props--------
   if(hist.cum > hist.max)hist.max = hist.cum;
   if(hist.cum < hist.min)hist.min = hist.cum;     
   if(lots > 0)//is blue
      {       
         hist.bcnt++;
          }
   if(lots < 0)//is red
      {
         hist.rcnt++;
         }
   Power[0] = hist.pips - hist.cum;
//---------------------------------------------------+
//   Pick maximum and minmum values of indicator     +
//---------------------------------------------------+
double   k=0;
double   m=0;
int      l=0;
int      n=0;
for(int j=0;j<per;j++)
   {
   if(Power[j]>Power[0]+(j*k) &&Power[j]<EMPTY_VALUE)
      {
      k=(Power[j]-Power[0])/j;
      l=j+1;
      }
   if(Power[j]<Power[0]+(j*m)&&Power[j]<EMPTY_VALUE)
      {
      m=(Power[j]-Power[0])/j;
      n=j+1;
      }
   }
   for(int i=per;i>=0;i--)
      {
      if(i<l) Max[i]=Power[0]+(i*k);
         else Max[i]=EMPTY_VALUE;
      if(i<n) Min[i]=Power[0]+(i*m);
         else Min[i]=EMPTY_VALUE;
      }

//----------------------------------------------------------------  
//---Set objects color
   return (rates_total);
   }
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
  
void OnDeinit(const int reason)
   {

   }
//---------------------------------------------------------------------------