//+------------------------------------------------------------------+
//|                       BULLISH AND BEARISH.mq5                    |
//+------------------------------------------------------------------+
#property version   "1.0"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5

#property indicator_type1 DRAW_ARROW
#property indicator_width1 2
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 2
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell"

#property indicator_type3 DRAW_ARROW
#property indicator_width3 3
#property indicator_color3 0xFF8000
#property indicator_label3 ""

#property indicator_type4 DRAW_ARROW
#property indicator_width4 3
#property indicator_color4 0x0000FF
#property indicator_label4 ""

#property indicator_type5 DRAW_LINE
#property indicator_style5 STYLE_SOLID
#property indicator_width5 1
#property indicator_color5 0xFFAA00
#property indicator_label5 ""

#define PLOT_MAXIMUM_BARS_BACK 5000
#define OMIT_OLDEST_BARS 50

//--- indicator buffers
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];
double Buffer5[];

input int MA_Period = 14;
int handleCurrent;
double Close[];
int MA_handle;
double MA[];
int MA_handle2;
double MA2[];
int MA_handle3;
double MA3[];
int MA_handle4;
double MA4[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   PlotIndexSetInteger(0, PLOT_ARROW, 159);
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   PlotIndexSetInteger(1, PLOT_ARROW, 159);
   SetIndexBuffer(2, Buffer3);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   PlotIndexSetInteger(2, PLOT_ARROW, 233);
   SetIndexBuffer(3, Buffer4);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   PlotIndexSetInteger(3, PLOT_ARROW, 234);
   SetIndexBuffer(4, Buffer5);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   MA_handle = iMA(NULL, PERIOD_CURRENT, MA_Period, 0, MODE_SMA, PRICE_CLOSE);
   if(MA_handle < 0)
     {
      Print("The creation of iMA has failed: MA_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   MA_handle2 = iMA(NULL, PERIOD_CURRENT, MA_Period, 0, MODE_SMA, PRICE_LOW);
   if(MA_handle2 < 0)
     {
      Print("The creation of iMA has failed: MA_handle2=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   MA_handle3 = iMA(NULL, PERIOD_CURRENT, MA_Period, 0, MODE_SMA, PRICE_HIGH);
   if(MA_handle3 < 0)
     {
      Print("The creation of iMA has failed: MA_handle3=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   MA_handle4 = iMA(NULL, PERIOD_CURRENT, 10, 0, MODE_SMA, PRICE_CLOSE);
   if(MA_handle4 < 0)
     {
      Print("The creation of iMA has failed: MA_handle4=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   handleCurrent  = iMA(_Symbol, PERIOD_CURRENT, MA_Period, 0, MODE_SMA, PRICE_CLOSE);

   EventSetTimer(2);

   ObjectCreate(0, "TrendInfo", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_XDISTANCE, 500);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_YDISTANCE, 200);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectDelete(0, "TrendInfo");
   IndicatorRelease(handleCurrent);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   ArraySetAsSeries(Buffer3, true);
   ArraySetAsSeries(Buffer4, true);
   ArraySetAsSeries(Buffer5, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
      ArrayInitialize(Buffer3, EMPTY_VALUE);
      ArrayInitialize(Buffer4, EMPTY_VALUE);
      ArrayInitialize(Buffer5, EMPTY_VALUE);
     }
   else
      limit++;
   
   if(CopyClose(Symbol(), PERIOD_CURRENT, 0, rates_total, Close) <= 0) return(rates_total);
   ArraySetAsSeries(Close, true);
   if(BarsCalculated(MA_handle) <= 0) 
      return(0);
   if(CopyBuffer(MA_handle, 0, 0, rates_total, MA) <= 0) return(rates_total);
   ArraySetAsSeries(MA, true);
   if(BarsCalculated(MA_handle2) <= 0) 
      return(0);
   if(CopyBuffer(MA_handle2, 0, 0, rates_total, MA2) <= 0) return(rates_total);
   ArraySetAsSeries(MA2, true);
   if(BarsCalculated(MA_handle3) <= 0) 
      return(0);
   if(CopyBuffer(MA_handle3, 0, 0, rates_total, MA3) <= 0) return(rates_total);
   ArraySetAsSeries(MA3, true);
   if(BarsCalculated(MA_handle4) <= 0) 
      return(0);
   if(CopyBuffer(MA_handle4, 0, 0, rates_total, MA4) <= 0) return(rates_total);
   ArraySetAsSeries(MA4, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(PLOT_MAXIMUM_BARS_BACK-1, rates_total-1-OMIT_OLDEST_BARS)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(Close[1+i] > MA[i] //Candlestick Close > Moving Average
      )
        {
         Buffer1[i] = MA2[i]; //Set indicator value at Moving Average
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 2
      if(Close[1+i] < MA[i] //Candlestick Close < Moving Average
      )
        {
         Buffer2[i] = MA3[i]; //Set indicator value at Moving Average
        }
      else
        {
         Buffer2[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 3
      if(Close[1+i] > MA4[i]
      && Close[1+i+1] < MA4[i+1] //Candlestick Close crosses above Moving Average
      )
        {
         Buffer3[i] = MA2[i]; //Set indicator value at Moving Average
        }
      else
        {
         Buffer3[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 4
      if(Close[1+i] < MA4[i]
      && Close[1+i+1] > MA4[i+1] //Candlestick Close crosses below Moving Average
      )
        {
         Buffer4[i] = MA3[i]; //Set indicator value at Moving Average
        }
      else
        {
         Buffer4[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 5
      if(true //no conditions!
      )
        {
         Buffer5[i] = MA[i]; //Set indicator value at Moving Average
        }
      else
        {
         Buffer5[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void OnTimer()
{
   double maCurrent;
   double closePrice;
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 1, rates) < 1) return;
   closePrice = rates[0].close;

   // Ambil data MA dengan pengesahan
   if(!GetMAValue(handleCurrent, maCurrent)) return;

   string trendText;
   color textColor;

   // LOGIK BULLISH: Harga di atas semua MA
   if(closePrice > maCurrent)
   {
      trendText = "Bullish On This TimeFrame";
      textColor = clrDeepSkyBlue;
   }
   // LOGIK BEARISH: Harga di bawah semua MA (Sila perhatikan maM15 di bawah)
   else if(closePrice < maCurrent)
   {
      trendText = "Bearish On This TimeFrame";
      textColor = clrOrange;
   }
   // SELAIN ITU: Sideways / Mixed
   else
   {
      trendText = "Trend: Waiting / Sideways / Mixed";
      textColor = clrGray;
   }

   ObjectSetString(0, "TrendInfo", OBJPROP_TEXT, trendText);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, "TrendInfo", OBJPROP_FONTSIZE, 15);
   
   ChartRedraw(); // Memastikan teks dikemaskini pada carta
}

// Fungsi pembantu untuk mengambil data MA
bool GetMAValue(int handle, double &val)
{
   double buffer[1];
   if(CopyBuffer(handle, 0, 0, 1, buffer) < 1) return false;
   val = buffer[0];
   return true;
}
