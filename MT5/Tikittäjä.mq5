//+---------------------+
//| Tikittäjä.mq4       |
//+---------------------+-
#property copyright   "junix64"
#property description "Efective TickVolume"

//---Compiler directives
#define Xc_clr  0xFF0000

//--- indicator settings------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Xc"
#property indicator_type1   DRAW_LINE
#property indicator_color1 Xc_clr
#property indicator_color1  DeepSkyBlue,Salmon
enum ENUM_COUNT_METHOD
{
Cumulative,
Simple,   
}; 


struct tickCount
{
   int total;
   int info;
   int trade;
   int buy; 
   int sell; 
   int ask; 
   int bid; 
   int last; 
   int volume;
   double rate_ask;
   double rate_bid;
};

struct spreadHist
{
   double min;
   double max;
   double last;
   datetime time_max;
   datetime time_min;
};
/*
+-----------------------------------------------------------------+
|   Class for counting and handling ticks                         |
+-----------------------------------------------------------------+
*/
class TicksCounter
{  
//----------------------------- 
   private: 
   tickCount count;
   spreadHist spread;
   int getTicks(MqlTick &array[], datetime from)
   {
      int t = CopyTicksRange(_Symbol,array,COPY_TICKS_ALL,from*1000);//to current. In milli seconds
      for(int i=0; i<t; i++) addTick(array[i]);
      return t;
   }
   
   int getTicks(MqlTick &array[],datetime from, datetime to)
   {
      int t = CopyTicksRange(_Symbol,array,COPY_TICKS_ALL,from*1000, to*1000);//period from->to. In milli seconds
      for(int i=0; i<t; i++) addTick(array[i]);
      return t;
   }
   
//------------------------------  
   public: 
   tickCount reset()
   {
      count.total =0; count.info=0; count.trade=0; count.buy=0; count.sell=0; count.ask=0; count.bid=0; count.last=0; count.volume=0; count.rate_ask=0; count.rate_bid  =0;
      return count;
   }
      
  spreadHist resetSpreadHist()
   {
      spread.min=0;
      spread.max=0;
      // spread.last=0;
      return spread;
   }
   
   spreadHist getSpreadHist()
   {
      return spread;
   }
//-------------------------------------------------------------------
   tickCount addTick(MqlTick &tick)
   {
      double spr = tick.ask-tick.bid;
      if(spr <= spread.min || spread.min == 0) {spread.min = spr; spread.time_min = tick.time;}
      if(spr >= spread.max) {spread.max = spr; spread.time_max = tick.time;}
      double spread_diff = spr - spread.last;
   //--- Checking flags 
      count.total++;
      
      if((tick.flags&TICK_FLAG_BUY)==TICK_FLAG_BUY) { count.buy++; count.trade++; }
      if((tick.flags&TICK_FLAG_SELL)==TICK_FLAG_SELL) { count.sell++; count.trade++; }
      if((tick.flags&TICK_FLAG_ASK)==TICK_FLAG_ASK)
      {
         count.rate_ask += spread_diff;
         count.ask --;
         count.info++; 
      }
      if((tick.flags&TICK_FLAG_BID)==TICK_FLAG_BID)
      {
         count.rate_bid -= spread_diff;
         count.bid ++;
         count.info++; 
      }
      if((tick.flags&TICK_FLAG_LAST)==TICK_FLAG_LAST) {count.last++;count.info++; }
      if((tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME) {count.volume++; count.info++; }
      spread.last = spr;
      return count;
   
   }
   
   tickCount getCount()
      {
         return count;
      }
   
   tickCount addTick(datetime from,datetime to)
   {
      MqlTick array[];      
      int t  = getTicks(array,from, to);     
      if(t==0)Print("No Ticks in period or error. Last Error is:", GetLastError());
      return count;    
   }

   tickCount addTick(datetime from)
   {
      MqlTick array[];          
      int t = getTicks(array,from);
      if(t==0)Print("No Ticks in period or error. Last Error is:", GetLastError());
      return count;        
   }

   string printTicks()
   {
      string desc = "";
      desc=StringFormat("Total: %d\n",//Info Ticks: %d\nTrade Ticks: %d\nSum: %d\nAsk: %d\nBid: %d\n",//Last: %d\nVolume: %d\n\nTrade Ticks: %d\nBuy: %d\nSell: %d\n", 
      count.total);//, count.info, count.trade, count.bid+count.ask, count.ask, count.bid);//, count.last, count.volume, count.trade, count.buy, count.sell);
      return desc;
   }
   
   string printSpreadHist()
   {      
      string hist = "";
      hist = StringFormat("Spread Min: %G",spread.min*dig) + " at " + TimeToString(spread.time_min )+"\n";
      hist += StringFormat("Spread Max: %G",spread.max*dig) + " at " + TimeToString(spread.time_max )+"\n";
      hist += StringFormat("Spread: %G\n",spread.last*dig);
      return hist;
   }
      
   string getTickDescription(MqlTick &tick) 
   { 
   string desc;//=StringFormat("%s.%03d ", TimeToString(tick.time),tick.time_msc%1000); 
//--- Checking flags 
   bool buy_tick=((tick.flags&TICK_FLAG_BUY)==TICK_FLAG_BUY); 
   bool sell_tick=((tick.flags&TICK_FLAG_SELL)==TICK_FLAG_SELL); 
   bool ask_tick=((tick.flags&TICK_FLAG_ASK)==TICK_FLAG_ASK); 
   bool bid_tick=((tick.flags&TICK_FLAG_BID)==TICK_FLAG_BID); 
   bool last_tick=((tick.flags&TICK_FLAG_LAST)==TICK_FLAG_LAST); 
   bool volume_tick=((tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME);
   
//--- Checking trading flags in a tick first 
   if(buy_tick || sell_tick) 
     { 
      //--- Forming an output for the trading tick 
      desc=desc+"Trade Tick:\n"; 
      desc=desc+(buy_tick?StringFormat("Buy Tick: Last=%G Volume=%d ",tick.last,tick.volume):""); 
      desc=desc+(sell_tick?StringFormat("Sell Tick: Last=%G Volume=%d ",tick.last,tick.volume):""); 
      desc=desc+(ask_tick?StringFormat("Ask=%G ",tick.ask):""); 
      desc=desc+(bid_tick?StringFormat("Bid=%G ",tick.ask):"");

     } 
    //if(bid_tick)desc=desc+(bid_tick?StringFormat("bidtick. Ask=%G Bid=%G Last=%G Volume=%d ",tick.ask,tick.bid,tick.last,tick.volume):"");
   else 
     { 
      //--- Form a different output for an info tick 
      desc=desc+"Info Tick:\n";
      desc=desc+(ask_tick?StringFormat("ASK. Ask=%G Bid=%G Last=%G Volume=%d \n",tick.ask,tick.bid,tick.last,tick.volume):""); 
      desc=desc+(bid_tick?StringFormat("BID. Ask=%G Bid=%G Last=%G Volume=%d \n",tick.ask,tick.bid,tick.last,tick.volume):""); 
      desc=desc+(last_tick?StringFormat("lasttick. Last=%G \n",tick.last):""); 
      desc=desc+(volume_tick?StringFormat("volumetick. Volume=%d \n",tick.volume):"");

     } 
//--- Returning tick description 
   return (desc); 
   }

 
}; //END class TicksCounter

//+------------------------------------------------------------------+
//| Indicator Code Starts                                            |
//+------------------------------------------------------------------+
// globals
input int      Days = 5;
//input bool     Cumulative = false;
input ENUM_COUNT_METHOD Method=Cumulative;  // Method

//---- buffers----------------------
double   Xc[];
double   Col[];

//---- global variables--------------
double   dig;
datetime startday;

//---- Counter ----------------------
static TicksCounter counter;

//+------------------------------------------------------------------+
//| Indicator initialization function                                |
//+------------------------------------------------------------------+
int OnInit()
   {
//---- indicator buffers
   SetIndexBuffer(0,Xc,INDICATOR_DATA);
   SetIndexBuffer(1,Col,INDICATOR_COLOR_INDEX);
   //ArrayInitialize(Xc, EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Tikittäjä("+string(Days)+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits); 
   if(Method == Simple)
      {
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_COLOR_HISTOGRAM); 
         PlotIndexSetInteger(0,PLOT_LINE_WIDTH,3);
      }
   if(Method == Cumulative)
      {
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE); 
         PlotIndexSetInteger(0,PLOT_LINE_WIDTH,2);
      }
//----
   dig = MathPow(10, _Digits);
   MqlDateTime start;
   TimeToStruct(TimeCurrent()-Days*86400,start);
   //Only full days are counted.
   start.hour  = 0; 
   start.min   = 0; 
   start.sec   = 0; 
   startday = StructToTime(start);
   Print("Start1: ",startday);

   return(INIT_SUCCEEDED);
   }//OnInit ends
//+-------------------------------------------------------------------+
//| Calculations for Tikittäjä                                        |
//+-------------------------------------------------------------------+
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
   int      rt    = rates_total-1;
   spreadHist spr;
   MqlTick tick;
   tickCount count;

//---- previous values
   if(prev_calculated == 0)
      {
      MqlTick array[];
      int calculated = 0;
      //int ticks;
      int i = 0;
      count = counter.reset();
      spr = counter.resetSpreadHist();
      while(time[calculated] < startday) //Finding the starting period. The period into which starting day falls or is starting with.
         {
         Xc[calculated] = 0;
         if( calculated >= rt )break; //last period is always counted in.
         calculated++;                //So it is never droped out.
         }
      startday = time[calculated];
      //ticks = 
      CopyTicksRange(_Symbol,array,COPY_TICKS_ALL,startday*1000);//to current. In milli seconds
      Print("Start2: ", startday," First Tick at: ", array[0].time);      
//------------------------------------------------------- 
      while(calculated < rt)
         {
         datetime to = time[calculated+1];
         while(array[i].time < to)
            {
               counter.addTick(array[i]);
               i++;
            }
         count = counter.getCount();
         Xc[calculated]=count.rate_bid + count.rate_ask;
         if (Method == Simple)
            {
            counter.reset();
            counter.resetSpreadHist();
            if(Xc[calculated] < 0)Col[calculated] = 1.0;
            else Col[calculated]= 0.0;
            }
         calculated++;
         }
         if(calculated == rt)
            {
            count = counter.addTick(time[rt]);
            Xc[rt]=count.rate_bid + count.rate_ask;
            Print("Last tick at: ", time[rt]);
            }
         
      //Comment(counter.printTicks());
      //counter.resetSpreadHist();
      //return(calculated+1);
      }// Previous Values Calculated

//--------------------------------------------------------
   if (prev_calculated < rates_total && Method == Simple){ counter.reset(); counter.resetSpreadHist();}
   SymbolInfoTick(_Symbol, tick);
   count = counter.addTick(tick);
   spr = counter.getSpreadHist();
   Xc[rt]   = count.rate_bid + count.rate_ask;
   if(Xc[rt] < 0)Col[rt] = 1.0;
   else Col[rt]= 0.0;

   //Comment(counter.printTicks()+StringFormat("Spread Min: %G at %D\nSpread Max: %G at %D\nSpread: %G\n", spr.min*dig, spr.time_min, spr.max*dig, spr.time_max, spr.last*dig)+counter.getTickDescription(tick));
   Comment(counter.printTicks()+counter.printSpreadHist()+counter.getTickDescription(tick));

   return (rates_total);
   }

//---  END OnCalculate  ----------------------------------------------------
void OnDeinit(const int reason)
   {
      Comment("");
   }
//---  END OnDeinit  -------------------------------------------------------
   


//---  END  ----------------------------------------------------------------

