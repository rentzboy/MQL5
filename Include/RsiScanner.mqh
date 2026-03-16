//+------------------------------------------------------------------+
//|                                                   RsiScanner.mqh |
//|                                  Copyright 2026, Jaume Sancho    |
//|                                https://github.com/jimmer89       |
//+------------------------------------------------------------------+
#ifndef RSISCANNER_MQH
#define RSISCANNER_MQH

//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
const double RSI_CHANGE_THRESHOLD   = 0.1;
const int    ALIGNMENT_THRESHOLD    = 3;
const int    DASHBOARD_PADDING      = 15;
const int    ITIME_WARNING_COOLDOWN = 60;
const int    DASHBOARD_MARGIN       = 5;
const int    TITLE_FONT_BOOST       = 2;
const int    LINE_SPACING_EXTRA     = 5;
const int    MIN_CHART_MARGIN       = 100;
const int    LINE_HEIGHT_PADDING    = 8;
const int    DEFAULT_DASH_X         = 20;
const int    DEFAULT_DASH_Y         = 50;
const int    ALERT_MAX_RETRIES      = 2;
const int    ALERT_RETRY_DELAY_MS   = 100;
const string OBJ_PREFIX             = "RSI_MTF_";

//+------------------------------------------------------------------+
//| Data Structures                                                   |
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

struct STfData {
   ENUM_TIMEFRAMES tf;
   string          name;
   int             handle;
   datetime        lastAlertTime;
   double          lastRsi;
   double          currentRsi;
   datetime        lastWarning;
   string          objTF;
   string          objRSI;
   string          objStatus;
   
   void Init(int index, ENUM_TIMEFRAMES _tf, string _name) {
      tf = _tf;
      name = _name;
      handle = INVALID_HANDLE;
      lastAlertTime = 0;
      lastRsi = -1.0;
      currentRsi = -1.0;
      lastWarning = 0;
      string idx = IntegerToString(index);
      objTF = OBJ_PREFIX + "TF_" + idx;
      objRSI = OBJ_PREFIX + "RSI_" + idx;
      objStatus = OBJ_PREFIX + "Status_" + idx;
   }
};

struct SScannerState {
   bool     dataReady;
   bool     loadingShown;
   int      lastOB;
   int      lastOS;
   string   objBG;
   string   objTitle;
   string   objAlign;
   
   void Reset() {
      dataReady = false;
      loadingShown = false;
      lastOB = -1;
      lastOS = -1;
      objBG = OBJ_PREFIX + "BG";
      objTitle = OBJ_PREFIX + "Title";
      objAlign = OBJ_PREFIX + "Align";
   }
};

//+------------------------------------------------------------------+
//| Main Scanner Class                                               |
//+------------------------------------------------------------------+
class CRsiScanner {
private:
   SRsiSettings      m_rsi;
   SAlertSettings    m_alerts;
   SDisplaySettings  m_display;
   SScannerState     m_state;
   STfData           m_tfs[];
   int               m_tfCount;

   void     CalculateUIPositions();
   bool     BuildTimeframes(const STfSelection &sel);
   void     ReleaseHandles();
   void     CreateDashboard();
   void     DestroyDashboard();
   void     CreateLabel(string name, int xOff, int yOff, string txt, int sz, color clr, string font="Arial");
   
   double   GetRSIValue(int handle, int shift = 0);
   void     TrySendAlert(int idx, string condition, double val);
   void     SendNotificationWithRetry(string msg);
   void     SendEmailWithRetry(string subject, string body);
   void     PlaySoundWithRetry(string file);

public:
            CRsiScanner() : m_tfCount(0) { m_state.Reset(); }
           ~CRsiScanner() { Deinit(); }
           
   int      Init(const SRsiSettings &rsi, const SAlertSettings &alerts, const SDisplaySettings &display, const STfSelection &tfs);
   void     Deinit();
   void     Update();
};

//+------------------------------------------------------------------+
//| Initialization                                                    |
//+------------------------------------------------------------------+
int CRsiScanner::Init(const SRsiSettings &rsi, const SAlertSettings &alerts, const SDisplaySettings &display, const STfSelection &tfs)
{
   m_state.Reset();
   m_rsi = rsi;
   m_alerts = alerts;
   m_display = display;
   
   CalculateUIPositions();
   
   if(!BuildTimeframes(tfs)) {
      Print("Error: No timeframes selected!");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   for(int i=0; i<m_tfCount; i++) {
      m_tfs[i].handle = iRSI(_Symbol, m_tfs[i].tf, m_rsi.period, PRICE_CLOSE);
      if(m_tfs[i].handle == INVALID_HANDLE) {
         Print("Error: Failed to create handle for ", m_tfs[i].name);
         return INIT_FAILED;
      }
   }
   
   CreateDashboard();
   EventSetTimer(m_display.updateSec);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization                                                  |
//+------------------------------------------------------------------+
void CRsiScanner::Deinit()
{
   ReleaseHandles();
   DestroyDashboard();
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Main Update Cycle                                                 |
//+------------------------------------------------------------------+
void CRsiScanner::Update()
{
   int validCount = 0;
   int obCount = 0, osCount = 0;
   bool visualsChanged = false;
   
   for(int i=0; i<m_tfCount; i++) {
      m_tfs[i].currentRsi = GetRSIValue(m_tfs[i].handle);
      if(m_tfs[i].currentRsi >= 0) {
         validCount++;
         if(m_tfs[i].currentRsi >= m_rsi.obLevel) obCount++;
         else if(m_tfs[i].currentRsi <= m_rsi.osLevel) osCount++;
      }
   }
   
   m_state.dataReady = (m_tfCount > 0 && validCount >= (m_tfCount+1)/2);
   
   if(!m_state.dataReady) {
      if(!m_state.loadingShown) {
         ObjectSetString(0, m_state.objAlign, OBJPROP_TEXT, "⏳ Loading data...");
         ObjectSetInteger(0, m_state.objAlign, OBJPROP_COLOR, clrYellow);
         ChartRedraw(0);
         m_state.loadingShown = true;
      }
      return;
   }
   
   m_state.loadingShown = false;

   for(int i=0; i<m_tfCount; i++) {
      double rsi = m_tfs[i].currentRsi;
      if(rsi < 0) continue;
      
      if(MathAbs(rsi - m_tfs[i].lastRsi) >= RSI_CHANGE_THRESHOLD || m_tfs[i].lastRsi < 0) {
         m_tfs[i].lastRsi = rsi;
         visualsChanged = true;
         
         color clr = m_display.clrNeutral;
         string status = "";
         if(rsi >= m_rsi.obLevel) { clr = m_display.clrOB; status = "▲ OB"; }
         else if(rsi <= m_rsi.osLevel) { clr = m_display.clrOS; status = "▼ OS"; }
         
         ObjectSetString(0, m_tfs[i].objRSI, OBJPROP_TEXT, DoubleToString(rsi, 1));
         ObjectSetInteger(0, m_tfs[i].objRSI, OBJPROP_COLOR, clr);
         ObjectSetString(0, m_tfs[i].objStatus, OBJPROP_TEXT, status);
         ObjectSetInteger(0, m_tfs[i].objStatus, OBJPROP_COLOR, clr);
      }
   }
   
   if(obCount != m_state.lastOB || osCount != m_state.lastOS) {
      m_state.lastOB = obCount; m_state.lastOS = osCount;
      visualsChanged = true;
      
      string text = ""; color clr = clrGold;
      if(obCount >= ALIGNMENT_THRESHOLD) { text = StringFormat("⚠ %d TF OVERBOUGHT", obCount); clr = m_display.clrOB; }
      else if(osCount >= ALIGNMENT_THRESHOLD) { text = StringFormat("⚠ %d TF OVERSOLD", osCount); clr = m_display.clrOS; }
      
      ObjectSetString(0, m_state.objAlign, OBJPROP_TEXT, text);
      ObjectSetInteger(0, m_state.objAlign, OBJPROP_COLOR, clr);
   }
   
   for(int i=0; i<m_tfCount; i++) {
      if(m_tfs[i].currentRsi >= m_rsi.obLevel) TrySendAlert(i, "OVERBOUGHT", m_tfs[i].currentRsi);
      else if(m_tfs[i].currentRsi <= m_rsi.osLevel) TrySendAlert(i, "OVERSOLD", m_tfs[i].currentRsi);
   }
   
   if(visualsChanged) ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Private Helpers                                                   |
//+------------------------------------------------------------------+
void CRsiScanner::CalculateUIPositions() {
   m_display.rsiOffset = MathMax(50, m_display.fontSize * 6);
   m_display.statusOffset = MathMax(100, m_display.fontSize * 12);
}

bool CRsiScanner::BuildTimeframes(const STfSelection &sel) {
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   string names[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1"};
   bool show[] = {sel.m1, sel.m5, sel.m15, sel.m30, sel.h1, sel.h4, sel.d1};
   
   m_tfCount = 0;
   for(int i=0; i<ArraySize(show); i++) if(show[i]) m_tfCount++;
   if(m_tfCount == 0) return false;
   
   ArrayResize(m_tfs, m_tfCount);
   int idx = 0;
   for(int i=0; i<ArraySize(show); i++) {
      if(show[i]) { m_tfs[idx].Init(idx, tfs[i], names[i]); idx++; }
   }
   return true;
}

void CRsiScanner::ReleaseHandles() {
   for(int i=0; i<m_tfCount; i++) {
      if(m_tfs[i].handle != INVALID_HANDLE) { IndicatorRelease(m_tfs[i].handle); m_tfs[i].handle = INVALID_HANDLE; }
   }
}

double CRsiScanner::GetRSIValue(int handle, int shift) {
   if(handle == INVALID_HANDLE || BarsCalculated(handle) <= 0) return -1.0;
   double buf[1];
   return (CopyBuffer(handle, 0, shift, 1, buf) == 1) ? buf[0] : -1.0;
}

void CRsiScanner::TrySendAlert(int idx, string condition, double val) {
   datetime barTime = iTime(_Symbol, m_tfs[idx].tf, 0);
   if(barTime == 0 || m_tfs[idx].lastAlertTime == barTime) return;
   
   m_tfs[idx].lastAlertTime = barTime;
   string msg = StringFormat("%s %s RSI %s: %.1f", _Symbol, m_tfs[idx].name, condition, val);
   
   if(m_alerts.sound) PlaySoundWithRetry(m_alerts.soundFile);
   if(m_alerts.push) SendNotificationWithRetry(msg);
   if(m_alerts.email) SendEmailWithRetry("RSI Alert: "+_Symbol, msg);
   Print("ALERT: ", msg);
}

void CRsiScanner::CreateDashboard() {
   int x = m_display.x, y = m_display.y;
   int h = m_display.fontSize + LINE_HEIGHT_PADDING;
   int totalH = (m_tfCount + 2) * h + DASHBOARD_PADDING;
   
   if(ObjectCreate(0, m_state.objBG, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      ObjectSetInteger(0, m_state.objBG, OBJPROP_XDISTANCE, x-DASHBOARD_MARGIN);
      ObjectSetInteger(0, m_state.objBG, OBJPROP_YDISTANCE, y-DASHBOARD_MARGIN);
      ObjectSetInteger(0, m_state.objBG, OBJPROP_XSIZE, m_display.width);
      ObjectSetInteger(0, m_state.objBG, OBJPROP_YSIZE, totalH);
      ObjectSetInteger(0, m_state.objBG, OBJPROP_BGCOLOR, m_display.clrBG);
      ObjectSetInteger(0, m_state.objBG, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, m_state.objBG, OBJPROP_HIDDEN, true);
   }

   CreateLabel(m_state.objTitle, x, y, "RSI Multi-TF ("+_Symbol+")", m_display.fontSize+TITLE_FONT_BOOST, clrWhite, "Arial Bold");
   y += h + LINE_SPACING_EXTRA;

   for(int i=0; i<m_tfCount; i++) {
      CreateLabel(m_tfs[i].objTF, x, y, m_tfs[i].name+":", m_display.fontSize, clrWhite);
      CreateLabel(m_tfs[i].objRSI, x+m_display.rsiOffset, y, "...", m_display.fontSize, m_display.clrNeutral, "Arial Bold");
      CreateLabel(m_tfs[i].objStatus, x+m_display.statusOffset, y, "", m_display.fontSize, m_display.clrNeutral);
      y += h;
   }
   
   CreateLabel(m_state.objAlign, x, y+LINE_SPACING_EXTRA, "⏳ Initializing...", m_display.fontSize, clrGold, "Arial Bold");
   ChartRedraw(0);
}

void CRsiScanner::CreateLabel(string name, int xOff, int yOff, string txt, int sz, color clr, string font="Arial") {
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xOff);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yOff);
      ObjectSetString(0, name, OBJPROP_TEXT, txt);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, sz);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
}

void CRsiScanner::DestroyDashboard() {
   ObjectsDeleteAll(0, OBJ_PREFIX);
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
      if(GetLastError()==4515) return;
      Sleep(ALERT_RETRY_DELAY_MS);
   }
}

void CRsiScanner::SendEmailWithRetry(string subject, string body) {
   for(int i=0; i<=(m_alerts.retry?ALERT_MAX_RETRIES:0); i++) {
      ResetLastError();
      if(SendMail(subject, body)) return;
      if(GetLastError()==4510) return;
      Sleep(ALERT_RETRY_DELAY_MS);
   }
}

#endif
