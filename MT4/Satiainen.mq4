//+---------------------------------------------------+
//|  Satiainen.mq4                                    |
//+---------------------------------------------------+
#property copyright   "junix64"
#property description "Power of Volume"
#property strict

//--- indicator settings ------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_level1 0 
#property indicator_color1 clrRed
#property indicator_color2 clrBlue

//--- Compiler directives -----------------------------
//#define debug

//--- input parameters --------------------------------
input int   Periods = 20;

//--- buffers -----------------------------------------
double   Power[];
double   Trend[];

//--- global variables --------------------------------
long     volume_old;
double   close_old;
double   cum = 0;
double   x_variance = 0;
int      per = Periods;
double   mid = per/2;
bool     sell = false;
bool     buy = false;

//+-------------------------------------------------- +
//|    initialization function                        |
//+---------------------------------------------------+
int OnInit()
  {
//---- indicator buffers ------------------------------
   SetIndexBuffer(0,Trend);
   SetIndexStyle(0,DRAW_LINE,EMPTY,1);
   SetIndexLabel(0,"Power of Trend");
   ArraySetAsSeries(Trend,true);
   ArrayInitialize(Trend,0);
   
   SetIndexBuffer(1,Power);
   SetIndexStyle(1,DRAW_LINE,EMPTY,1);
   SetIndexLabel(1,"Power");
   ArraySetAsSeries(Power,true);
   ArrayInitialize(Power,0);

//--- indicator settings ------------------------------
   IndicatorDigits(5);
   IndicatorShortName("Satiainen ("+string(Periods)+")");
   IndicatorSetInteger(INDICATOR_LEVELS,1);
   
/*--- seting up arrows --------------------------------
   ObjectCreate(0,"buy",OBJ_ARROW_UP,0,0,0);
   ObjectSetInteger(0,"buy",OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(0,"buy",OBJPROP_COLOR,clrLimeGreen);
   ObjectCreate(0,"sell",OBJ_ARROW_DOWN,0,0,0);
   ObjectSetInteger(0,"sell",OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ChartRedraw(0);
*/
//--- set initial values for global variables
   cum              = 0;
   for(int i=0;i<per;i++)x_variance+=MathPow(double(i)-mid,2);
   return(INIT_SUCCEEDED);
   }//OnInit ends

//----------------------------------------------------+
// Calculations for Power of Volume                   |
//----------------------------------------------------+
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
//---First Bar ----------------------------------------
   if(prev_calculated==0)
   {
      volume_old  = tick_volume[0];
      close_old   = close[0];
      return rates_total;
   }
//--- First Bar End -----------------------------------
//----------------------------------------------------+
//   New Bar                                          |
//----------------------------------------------------+
if(prev_calculated < rates_total)
   {
   volume_old        = 0;
   }
//-----------------------------------------------------------+
//    End New Bar                                            +
//-----------------------------------------------------------+

//--- Main calculations -------------------------------
   if (price_diff > 0) lots = (int)tick_volume[0] - (int)volume_old;  //Price raises-> lots > 0
   if (price_diff < 0) lots = (int)volume_old - (int)tick_volume[0];  //Price falls -> lots < 0

   volume_old = tick_volume[0];
   close_old = close[0];
   cum += lots;
   Power[0] = cum;
   
//--- Calculate correlation of Prise and Power of Vol -
   double   powers=0;
   double   squarsum=0;
   double   prices=0;
   double   squarsum_pr=0;

//--- Sum values for calculating avrs------------------
   for(int i=0;i<per;i++)
      {
      if(Power[i]<EMPTY_VALUE)
         {
         powers+=Power[i];
         }
            else
            {
            powers+=(powers/(i+1));
            }
      prices+=Close[i]*MathPow(10,Digits);
      }
   double   avr   = powers/per;
   double   avr_pr= prices/per;
   
//--- sum of squares ----------------------------------
   for(int i=0;i<per;i++)
      {
      double sift_x = mid-double(i);
      if(Power[i]<EMPTY_VALUE)   squarsum+=sift_x*(Power[i]-avr);
      squarsum_pr+=(mid-double(i))*((Close[i]*MathPow(10,Digits))-avr_pr);
      }

//--- least of sum of squares -------------------------      
   double mfactor_pw = squarsum/x_variance;
   double mfactor_pr = squarsum_pr/x_variance;
   double mfactor = mfactor_pr*mfactor_pw;
   Trend[0]   = mfactor;
   //Print("mf= "+string (Trend[0])+" mf_pr: "+string(mfactor_pr)+" mf_pw: "+string(mfactor_pw));


//----------------------------------------------------+
//   New Bar (again)                                  |
//----------------------------------------------------+
if(prev_calculated < rates_total)
   {
   if(Trend[1]<0)
      {
      if(mfactor_pr<0 && !buy)
         {
         string   name = "buy@ "+string(Close[0]);
         Print(name);
         ObjectCreate(0,name,OBJ_ARROW_UP,0,0,0);
         ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_TOP);
         ObjectSetInteger(0,name,OBJPROP_COLOR,clrLimeGreen);
         ObjectMove(0,name,0,TimeCurrent(),Close[0]);

         buy=true;
         sell=false;
         ChartRedraw(0);
         PlaySound("expert.wav"); 
         }
      if(mfactor_pw<0 && !sell)
         {
         string   name = "sell@ "+string(Close[0]);
         Print(name);
         ObjectCreate(0,name,OBJ_ARROW_DOWN,0,0,0);
         ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
         ObjectMove(0,name,0,TimeCurrent(),Close[0]);

         sell=true;
         buy=false;
         ChartRedraw(0);
         PlaySound("expert.wav"); 
         }
      }
   //Print("buy:"+string(buy)+" sell:"+string(sell));
   }

//-----------------------------------------------------
   return (rates_total);
   }
