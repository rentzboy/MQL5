//+------------------------------------------------------------------+
//|                                        RSI_MultiTF_Alert_v2.0.mq5 |
//|                                  Copyright 2026, Jaume Sancho    |
//|                                https://github.com/jimmer89       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "2.00"
#property description "Multi-timeframe RSI scanner with visual dashboard and alerts"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

//--- Include the scanner class
#include <RsiScannerStd.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                  |
//+------------------------------------------------------------------+
input group "=== RSI Settings ==="
input int      InpRSI_Period       = 14;         // RSI Period (1-500)
input double   InpOverbought_Level = 70.0;       // Overbought Level (50-100)
input double   InpOversold_Level   = 30.0;       // Oversold Level (0-50)

input group "=== Timeframe Selection ==="
input bool     InpShow_M1  = true;               // Show M1
input bool     InpShow_M5  = true;               // Show M5
input bool     InpShow_M15 = true;               // Show M15
input bool     InpShow_M30 = true;               // Show M30
input bool     InpShow_H1  = true;               // Show H1
input bool     InpShow_H4  = true;               // Show H4
input bool     InpShow_D1  = true;               // Show D1

input group "=== Alert Settings ==="
input bool     InpEnable_Push_Alerts  = true;    // Enable Push Notifications
input bool     InpEnable_Email_Alerts = false;   // Enable Email Alerts
input bool     InpEnable_Sound_Alerts = true;    // Enable Sound Alerts
input string   InpAlert_Sound         = "alert2.wav"; // Alert Sound File
input bool     InpAlert_Retry_Enabled = true;    // Retry failed alerts

input group "=== Display Settings ==="
input int      InpDashboard_X      = 20;         // Dashboard X Position
input int      InpDashboard_Y      = 50;         // Dashboard Y Position
input int      InpDashboard_Width  = 200;        // Dashboard Width (pixels)
input color    InpColor_Overbought = clrRed;     // Overbought Color
input color    InpColor_Oversold   = clrDodgerBlue; // Oversold Color
input color    InpColor_Neutral    = clrGray;    // Neutral Color
input color    InpColor_Background = C'20,20,20'; // Dashboard Background
input int      FONT_SIZE        = 10;         // Font Size (6-24)
input int      InpUpdate_Seconds   = 1;          // Update Interval (1-60 seconds)
input bool     InpVerbose_Logging  = false;      // Enable verbose debug logging

//--- Global Instance
CRsiScanner g_scanner;

//+------------------------------------------------------------------+
//| Helper: Group all RSI Scanner inputs into structs                 |
//+------------------------------------------------------------------+
void GetScannerInputs(SRsiSettings &rsi, SAlertSettings &alerts, SDisplaySettings &display, STfSelection &tfs)
{
   // RSI Settings
   rsi.period = (int)MathMax(1, MathMin(500, InpRSI_Period));
   rsi.obLevel = InpOverbought_Level;
   rsi.osLevel = InpOversold_Level;
   
   // Alert Settings
   alerts.push = InpEnable_Push_Alerts;
   alerts.email = InpEnable_Email_Alerts;
   alerts.sound = InpEnable_Sound_Alerts;
   alerts.soundFile = InpAlert_Sound;
   alerts.retry = InpAlert_Retry_Enabled;
   
   // Display Settings
   display.x = InpDashboard_X;
   display.y = InpDashboard_Y;
   display.width = (int)MathMax(150, MathMin(500, InpDashboard_Width));
   display.clrOB = InpColor_Overbought;
   display.clrOS = InpColor_Oversold;
   display.clrNeutral = InpColor_Neutral;
   display.clrBG = InpColor_Background;
   display.fontSize = (int)MathMax(6, MathMin(24, FONT_SIZE));
   display.updateSec = (int)MathMax(1, MathMin(60, InpUpdate_Seconds));
   display.verbose = InpVerbose_Logging;
   
   // Timeframe Selection
   tfs.m1 = InpShow_M1; tfs.m5 = InpShow_M5; tfs.m15 = InpShow_M15;
   tfs.m30 = InpShow_M30; tfs.h1 = InpShow_H1; tfs.h4 = InpShow_H4; tfs.d1 = InpShow_D1;
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // 1. Initialize local structs from inputs
   SRsiSettings rsi;
   SAlertSettings alerts;
   SDisplaySettings display;
   STfSelection tfs;
   
   GetScannerInputs(rsi, alerts, display, tfs);

   // 2. Pass structs to the scanner instance
   int res = g_scanner.Init(rsi, alerts, display, tfs);
   if(res != INIT_SUCCEEDED) return res;
   
   // 3. Add here any other initialization for other features
   // ...
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_scanner.Deinit();
   
   // Cleanup other features here
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   g_scanner.Update();
   
   // Update other features here
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   // Calculate other indicator logic here if needed
   return(rates_total);
}
