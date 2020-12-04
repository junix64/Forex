//+------------------------------------------------------------------+
//|                                                    Voldemort.mq4 |
//+------------------------------------------------------------------+
#property copyright   "Jussi Niskanen"
//#property link        
#property description "Trend"
#property strict

//--- indicator settings------------
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 clrGold
#property indicator_color2 clrGold
#property indicator_color3 clrRed

//--- input parameters--------------
input int   Periods = 12;

//--- buffers-----------------------
double   Min[];
double   Max[];
double   Trend[];

//--- Global varisbles
double   x_variance = 0;
int      per = Periods;
double   mid = per/2;

//bool     first;

//+------------------------------------------------------------------+
//| Power of Volume indicator initialization function                      |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- indicator buffers
   SetIndexBuffer(0,Max);
   SetIndexStyle(0,DRAW_LINE,EMPTY,1);
   SetIndexLabel(0,"Max");
   ArraySetAsSeries(Max,true);
   ArrayInitialize(Max,0);
   
   SetIndexBuffer(1,Min);
   SetIndexStyle(1,DRAW_LINE,EMPTY,1);
   SetIndexLabel(1,"Min");   
   ArraySetAsSeries(Min,true);
   ArrayInitialize(Min,0);
   
   SetIndexBuffer(2,Trend);
   SetIndexStyle(2,DRAW_LINE,EMPTY,1);
   SetIndexLabel(2,"Trend of Price");
   ArraySetAsSeries(Trend,true);
   ArrayInitialize(Trend,0);

   
//--- indicator settings
   IndicatorDigits(0);
   IndicatorShortName("Punkki ("+string(Periods)+")");

//--- set initial values for global variables
   for(int i=0;i<per;i++)x_variance+=MathPow(double(i)-mid,2);
   
  
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
//--- Main calculations --------------------------------------                     
//--- Calculate Trend of Price -------------------------------
   double   squarsum=0;
   double   prices=0;
double   k=0;
int      l=0;
   for(int j=0;j<per;j++)
      {
      prices+=Close[j];
      if(Close[j]>Close[0]+(j*k)) 
         {
         k=(Close[j]-Close[0])/j;
         l=j+1;
         }
      }
   for(int i=per;i>=0;i--)
      {
      if(i<l) Max[i]=Close[0]+(i*k);
         else Max[i]=EMPTY_VALUE;
      }
    
k=0;
l=0;
   for(int j=0;j<per;j++)
      {
      if(Close[j]<Close[0]+(j*k))
         {
         k=(Close[j]-Close[0])/j;
         l=j+1;
         }
         
      }
   for(int i=per;i>=0;i--)
      {
      if(i<l)Min[i]=Close[0]+(i*k);
         else Min[i]=EMPTY_VALUE;
      }
   
//--- sum of squares ----------------------------------
   double   avr = prices/per;

   for(int i=0;i<per;i++)
      {
      squarsum+=(mid-double(i))*(Close[i]-avr);
      }

//--- least of sum of squares -------------------------      
   double mfactor = squarsum/x_variance;
   for(int i=per;i>=0;i--)
      {
      if(i<per) Trend[i]=avr-((i-mid)*mfactor);
         else Trend[i]=EMPTY_VALUE;
      }
//----------------------------------------------------------------  
//---Set objects color
   return (rates_total);
   }
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
