//+------------------------------------------------------------------+
//|                                                RsiScannerStd.mqh |
//|                                  Copyright 2026, Jaume Sancho    |
//|                                https://github.com/jimmer89       |
//+------------------------------------------------------------------+
#ifndef RSISCANNER_STD_MQH
#define RSISCANNER_STD_MQH

#include <Indicators/Oscilators.mqh>
#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include <Arrays/ArrayObj.mqh>

//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
const double RSI_CHANGE_THRESHOLD   = 0.1;
const int    ALIGNMENT_THRESHOLD    = 3;
const int    DASHBOARD_PADDING      = 15;
const int    DASHBOARD_MARGIN       = 5;
const int    TITLE_FONT_BOOST       = 2;
const int    LINE_SPACING_EXTRA     = 5;
const int    LINE_HEIGHT_PADDING    = 8;
const string OBJ_PREFIX             = "RSI_MTF_";
const int    ALERT_MAX_RETRIES      = 2;
const int    ALERT_RETRY_DELAY_MS   = 100;

//+------------------------------------------------------------------+
//| Data Structures (Identical for compatibility)                     |
//+------------------------------------------------------------------+
struct SRsiSettings {
   int      period;
   double   obLevel;
   double   osLevel;
};

struct SAlertSettings {
   bool     push;
   bool     email;
   bool     sound;
   string   soundFile;
   bool     retry;
};

struct SDisplaySettings {
   int      x;
   int      y;
   int      width;
   color    clrOB;
   color    clrOS;
   color    clrNeutral;
   color    clrBG;
   int      fontSize;
   int      updateSec;
   int      rsiOffset;
   int      statusOffset;
   bool     verbose;
};

struct STfSelection {
   bool m1, m5, m15, m30, h1, h4, d1;
};

//+------------------------------------------------------------------+
//| Internal Class for Timeframe Data                                 |
//+------------------------------------------------------------------+
class CTfData : public CObject {
public:
   ENUM_TIMEFRAMES   tf;
   string            name;
   CiRSI             rsi_obj;
   datetime          lastAlertTime;
   double            lastRsi;
   double            currentRsi;
   
   CChartObjectLabel objTF;
   CChartObjectLabel objRSI;
   CChartObjectLabel objStatus;

   CTfData() : tf(PERIOD_CURRENT), name(""), lastAlertTime(0), lastRsi(-1), currentRsi(-1) {}
};

//+------------------------------------------------------------------+
//| Main Scanner Class (Standard Library Version)                     |
//+------------------------------------------------------------------+
class CRsiScanner {
private:
   SRsiSettings      m_rsi;
   SAlertSettings    m_alerts;
   SDisplaySettings  m_display;
   
   CArrayObj         m_tfs;      // Collection of CTfData
   
   CChartObjectRectLabel m_objBG;
   CChartObjectLabel     m_objTitle;
   CChartObjectLabel     m_objAlign;
   
   int               m_lastOB;
   int               m_lastOS;
   bool              m_dataReady;
   bool              m_loadingShown;

   void     CalculateUIPositions();
   bool     BuildTimeframes(const STfSelection &sel);
   void     CreateDashboard();
   void     TrySendAlert(CTfData *tf_data, string condition, double val);
   
   void     SendNotificationWithRetry(string msg);
   void     SendEmailWithRetry(string subject, string body);
   void     PlaySoundWithRetry(string file);

public:
            CRsiScanner();
           ~CRsiScanner() { Deinit(); }
           
   int      Init(const SRsiSettings &rsi, const SAlertSettings &alerts, const SDisplaySettings &display, const STfSelection &tfs);
   void     Deinit();
   void     Update();
};

CRsiScanner::CRsiScanner() : m_lastOB(-1), m_lastOS(-1), m_dataReady(false), m_loadingShown(false) {
   m_tfs.FreeMode(true);
}

int CRsiScanner::Init(const SRsiSettings &rsi, const SAlertSettings &alerts, const SDisplaySettings &display, const STfSelection &tfs)
{
   m_rsi = rsi;
   m_alerts = alerts;
   m_display = display;
   
   CalculateUIPositions();
   
   if(!BuildTimeframes(tfs)) {
      Print("Error: No timeframes selected!");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   for(int i=0; i<m_tfs.Total(); i++) {
      CTfData *data = (CTfData*)m_tfs.At(i);
      if(!data.rsi_obj.Create(_Symbol, data.tf, m_rsi.period, PRICE_CLOSE)) {
         Print("Error: Failed to create CiRSI for ", data.name);
         return INIT_FAILED;
      }
   }
   
   CreateDashboard();
   EventSetTimer(m_display.updateSec);
   
   return INIT_SUCCEEDED;
}

void CRsiScanner::Deinit()
{
   m_tfs.Clear();
   m_objBG.Delete();
   m_objTitle.Delete();
   m_objAlign.Delete();
   EventKillTimer();
   ChartRedraw(0);
}

void CRsiScanner::Update()
{
   int validCount = 0;
   int obCount = 0, osCount = 0;
   bool visualsChanged = false;
   int total = m_tfs.Total();
   
   for(int i=0; i<total; i++) {
      CTfData *data = (CTfData*)m_tfs.At(i);
      data.rsi_obj.Refresh();
      data.currentRsi = data.rsi_obj.Main(0);
      
      if(data.currentRsi != EMPTY_VALUE && data.currentRsi >= 0) {
         validCount++;
         if(data.currentRsi >= m_rsi.obLevel) obCount++;
         else if(data.currentRsi <= m_rsi.osLevel) osCount++;
      }
   }
   
   m_dataReady = (total > 0 && validCount >= (total+1)/2);
   
   if(!m_dataReady) {
      if(!m_loadingShown) {
         m_objAlign.Description("⏳ Loading data...");
         m_objAlign.Color(clrYellow);
         ChartRedraw(0);
         m_loadingShown = true;
      }
      return;
   }
   
   m_loadingShown = false;

   for(int i=0; i<total; i++) {
      CTfData *data = (CTfData*)m_tfs.At(i);
      double rsi = data.currentRsi;
      if(rsi == EMPTY_VALUE || rsi < 0) continue;
      
      if(MathAbs(rsi - data.lastRsi) >= RSI_CHANGE_THRESHOLD || data.lastRsi < 0) {
         data.lastRsi = rsi;
         visualsChanged = true;
         
         color clr = m_display.clrNeutral;
         string status = "";
         if(rsi >= m_rsi.obLevel) { clr = m_display.clrOB; status = "▲ OB"; }
         else if(rsi <= m_rsi.osLevel) { clr = m_display.clrOS; status = "▼ OS"; }
         
         data.objRSI.Description(DoubleToString(rsi, 1));
         data.objRSI.Color(clr);
         data.objStatus.Description(status);
         data.objStatus.Color(clr);
      }
   }
   
   if(obCount != m_lastOB || osCount != m_lastOS) {
      m_lastOB = obCount; m_lastOS = osCount;
      visualsChanged = true;
      
      string text = ""; color clr = clrGold;
      if(obCount >= ALIGNMENT_THRESHOLD) { text = StringFormat("⚠ %d TF OVERBOUGHT", obCount); clr = m_display.clrOB; }
      else if(osCount >= ALIGNMENT_THRESHOLD) { text = StringFormat("⚠ %d TF OVERSOLD", osCount); clr = m_display.clrOS; }
      
      m_objAlign.Description(text);
      m_objAlign.Color(clr);
   }
   
   for(int i=0; i<total; i++) {
      CTfData *data = (CTfData*)m_tfs.At(i);
      if(data.currentRsi >= m_rsi.obLevel) TrySendAlert(data, "OVERBOUGHT", data.currentRsi);
      else if(data.currentRsi <= m_rsi.osLevel) TrySendAlert(data, "OVERSOLD", data.currentRsi);
   }
   
   if(visualsChanged) ChartRedraw(0);
}

void CRsiScanner::CalculateUIPositions() {
   m_display.rsiOffset = MathMax(50, m_display.fontSize * 6);
   m_display.statusOffset = MathMax(100, m_display.fontSize * 12);
}

bool CRsiScanner::BuildTimeframes(const STfSelection &sel) {
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   string names[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1"};
   bool show[] = {sel.m1, sel.m5, sel.m15, sel.m30, sel.h1, sel.h4, sel.d1};
   
   m_tfs.Clear();
   for(int i=0; i<ArraySize(show); i++) {
      if(show[i]) {
         CTfData *data = new CTfData();
         data.tf = tfs[i];
         data.name = names[i];
         m_tfs.Add(data);
      }
   }
   return (m_tfs.Total() > 0);
}

void CRsiScanner::TrySendAlert(CTfData *tf_data, string condition, double val) {
   datetime barTime = iTime(_Symbol, tf_data.tf, 0);
   if(barTime == 0 || tf_data.lastAlertTime == barTime) return;
   
   tf_data.lastAlertTime = barTime;
   string msg = StringFormat("%s %s RSI %s: %.1f", _Symbol, tf_data.name, condition, val);
   
   if(m_alerts.sound) PlaySoundWithRetry(m_alerts.soundFile);
   if(m_alerts.push) SendNotificationWithRetry(msg);
   if(m_alerts.email) SendEmailWithRetry("RSI Alert: "+_Symbol, msg);
   Print("ALERT: ", msg);
}

void CRsiScanner::CreateDashboard() {
   int x = m_display.x, y = m_display.y;
   int h = m_display.fontSize + LINE_HEIGHT_PADDING;
   int totalH = (m_tfs.Total() + 2) * h + DASHBOARD_PADDING;
   
   m_objBG.Create(0, OBJ_PREFIX+"BG", 0, x-DASHBOARD_MARGIN, y-DASHBOARD_MARGIN, m_display.width, totalH);
   m_objBG.BackColor(m_display.clrBG);
   m_objBG.BorderType(BORDER_FLAT);
   m_objBG.Selectable(false);

   m_objTitle.Create(0, OBJ_PREFIX+"Title", 0, x, y);
   m_objTitle.Description("RSI Multi-TF ("+_Symbol+")");
   m_objTitle.FontSize(m_display.fontSize+TITLE_FONT_BOOST);
   m_objTitle.Font("Arial Bold");
   m_objTitle.Color(clrWhite);
   
   y += h + LINE_SPACING_EXTRA;

   for(int i=0; i<m_tfs.Total(); i++) {
      CTfData *data = (CTfData*)m_tfs.At(i);
      string idx = IntegerToString(i);
      //Create labels for each timeframe: Mx - RSI value - Status (overbought/oversold)
      data.objTF.Create(0, OBJ_PREFIX+"TF_"+idx, 0, x, y);
      data.objTF.Description(data.name+":");
      data.objTF.FontSize(m_display.fontSize);
      data.objTF.Color(clrWhite);

      data.objRSI.Create(0, OBJ_PREFIX+"RSI_"+idx, 0, x+m_display.rsiOffset, y);
      data.objRSI.Description("...");
      data.objRSI.FontSize(m_display.fontSize);
      data.objRSI.Color(m_display.clrNeutral);
      
      data.objStatus.Create(0, OBJ_PREFIX+"Status_"+idx, 0, x+m_display.statusOffset, y);
      data.objStatus.Description("");
      data.objStatus.FontSize(m_display.fontSize);
      y += h;
   }
   
   m_objAlign.Create(0, OBJ_PREFIX+"Align", 0, x, y+LINE_SPACING_EXTRA);
   m_objAlign.Description("⏳ Initializing...");
   m_objAlign.FontSize(m_display.fontSize);
   m_objAlign.Font("Arial Bold");
   m_objAlign.Color(clrGold);
   ChartRedraw(0);
}

void CRsiScanner::PlaySoundWithRetry(string file) {
   for(int i=0; i<=(m_alerts.retry?ALERT_MAX_RETRIES:0); i++) {
      if(PlaySound(file)) return;
      Sleep(ALERT_RETRY_DELAY_MS);
   }
}

void CRsiScanner::SendNotificationWithRetry(string msg) {
   for(int i=0; i<=(m_alerts.retry?ALERT_MAX_RETRIES:0); i++) {
      ResetLastError();
      if(SendNotification(msg)) return;
      Sleep(ALERT_RETRY_DELAY_MS);
   }
}

void CRsiScanner::SendEmailWithRetry(string subject, string body) {
   for(int i=0; i<=(m_alerts.retry?ALERT_MAX_RETRIES:0); i++) {
      ResetLastError();
      if(SendMail(subject, body)) return;
      Sleep(ALERT_RETRY_DELAY_MS);
   }
}

#endif
