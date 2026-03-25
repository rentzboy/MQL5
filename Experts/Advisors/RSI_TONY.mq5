//+------------------------------------------------------------------+
//|                                                     RSI_TONY.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 0 //voy a utilizar la MQL Standard Library
#property indicator_plots 0 // no pinta ninguna linea

#include <Controls/WndContainer.mqh>
#include <Controls/Dialog.mqh>
#include <Controls/Label.mqh>
#include <Controls/Rect.mqh>
#include <Controls/Panel.mqh>

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
input color    InpColor_Overbought = clrRed;     // Overbought Color
input color    InpColor_Oversold   = clrDodgerBlue; // Oversold Color
input color    InpColor_Neutral    = clrGray;    // Neutral Color
input color    InpColor_Background = clrBlack; // Dashboard Background

#define REFRESH_INTERVAL  60
#define DEBUG_LOGGING     false   // Enable verbose debug logging
#define DISPLAY_XX        20      // Dashboard X Position
#define DISPLAY_YY        50      // Dashboard Y Position
#define DISPLAY_WIDTH     200     // Dashboard Width (pixels)
#define ALIGNMENT_LEFT    3
#define ALIGNMENT_TOP     3
#define ALIGNMENT_RIGHT   3
#define ALIGNMENT_BOTTOM  3
#define SPACING           5
#define FONT_SIZE         10      // Font Size (6-24)



/* --------------- Class CDisplay -------------------- */
/* Habrá que llamar a CDisplay::Create() para crear el container
desde CDisplay::Create() y Add(control) para cada control de CDisplay
De esta manera todos los objetos se crearan con coordenadas relativas,
a la esquina superior izquierda del container object */
class CDisplay : public CDialog //para heredar los métodos Add(), Delete(), Destroy(), ....
{
private:
  CPanel m_panel; //CPanel es una clase derivada de CRect
  CLabel m_timeFrame[7];
  CLabel m_rsiTimeFrame[7];
  CLabel m_rsiOverSoldBought[7];

protected:
  bool Create(const long chart,const string name,const int subwin,
              const int x1,const int y1,const int x2,const int y2);
  bool CreatePanel(int x1, int y1, int x2, int y2);
  bool CreateTimeFrameLabels(void);
  bool CreateTimeFrameLabels2(void);

public:
  CDisplay(/* args */) {};
  ~CDisplay() {Print("CDisplay destroyed");};
  bool Initialize();
  //Destroy(): se hereda de CWndContainer from CDialog
  //Add(): se hereda de CWndContainer from CDialog
};

/* Create the visual Object */
bool CDisplay::Create(const long chart,const string name,const int subwin,
                      const int x1,const int y1,const int x2,const int y2)
{
  if(!CDialog::Create(chart,name,subwin,x1,y1,x2,y2)) return false;
  return true;
}

bool CDisplay::CreatePanel(int x1, int y1, int x2, int y2)
{
  if(!m_panel.Create(0, "RSI_Panel", 0, x1, y1, x2, y2)) return false; 
  m_panel.ColorBackground(clrDodgerBlue);
  m_panel.ColorBorder(clrDarkOrange);
  m_panel.FontSize(FONT_SIZE);
  PrintFormat("Panel created: x1=%d, y1=%d, x2=%d, y2=%d", x1, y1, x2, y2);
  if(!Add(m_panel)) return false;
  return true;
}

bool CDisplay:: CreateTimeFrameLabels(void)
{
  int i = 0;
  int x1 = ALIGNMENT_LEFT;
  int x2 = ALIGNMENT_LEFT + (FONT_SIZE * 4) + SPACING;
  int y1 = ALIGNMENT_TOP;
  int y2 = ALIGNMENT_TOP + FONT_SIZE + SPACING;

  if(InpShow_M1)
  {
    if(!m_timeFrame[i].Create(m_chart_id, "M1", 0, x1, y1, x2, y2)) return false;
    m_timeFrame[i].Text("M1:");
    m_timeFrame[i].FontSize(FONT_SIZE);
    //m_timeFrame[i].ColorText(clrWhite);
    m_timeFrame[i].ColorBackground(clrWheat);
    PrintFormat("Timeframe M1 label creado: x1=%d, y1=%d, x2=%d, y2=%d", x1, y1, x2, y2);
    y1 += FONT_SIZE*2;
    y2 += FONT_SIZE*2;
    if (!Add(m_timeFrame[i])) return false;
    i++;
  }
  if(InpShow_M5)
  {
    if(!m_timeFrame[i].Create(m_chart_id, "M5", 0, x1, y1, x2, y2)) return false;
    m_timeFrame[i].Text("M5:");
    m_timeFrame[i].FontSize(FONT_SIZE);
    PrintFormat("Timeframe M5 label creado: x1=%d, y1=%d, x2=%d, y2=%d", x1, y1, x2, y2);
    y1 += FONT_SIZE*2;
    y2 += FONT_SIZE*2;
    if (!Add(m_timeFrame[i])) return false;
    i++;
  } 
  if(InpShow_M15)
  {
    if(!m_timeFrame[i].Create(m_chart_id, "M15", 0, x1, y1, x2, y2)) return false;
    m_timeFrame[i].Text("M15:");
    m_timeFrame[i].FontSize(FONT_SIZE);
    PrintFormat("Timeframe M15 label creado: x1=%d, y1=%d, x2=%d, y2=%d", x1, y1, x2, y2);
    y1 += FONT_SIZE*2;
    y2 += FONT_SIZE*2;
    if (!Add(m_timeFrame[i])) return false;
    i++;
  } 
  PrintFormat("i=%d", i);
  ChartRedraw();
/*   if(InpShow_M30)
  {
    if(!m_timeFrame[i].Create(0, "M30", 0, x1, x2, y1, y2)) return false;
    y1 += FONT_SIZE*3;
    y2 += FONT_SIZE*3;
    i++;
    Print("Timeframe M30 label creado");
  } 
  if(InpShow_H1)
  {
    if(!m_timeFrame[i].Create(0, "H1", 0, x1, x2, y1, y2)) return false;
    y1 += FONT_SIZE*3;
    y2 += FONT_SIZE*3;
    i++;
    Print("Timeframe H1 label creado");
  } 
  if(InpShow_H4)
  {
    if(!m_timeFrame[i].Create(0, "H4", 0, x1, x2, y1, y2)) return false;
    y1 += FONT_SIZE*3;
    y2 += FONT_SIZE*3;
    i++;
    Print("Timeframe H4 label creado");
  }  */

  //Importante para que CWndContainer::Destroy() pueda borrarlo
/*    for (int i = 0; i < ArraySize(m_timeFrame); i++)
  {
    if (!Add(m_timeFrame[i])) return false;
  }  */
  return true;
}


bool CDisplay::CreateTimeFrameLabels2(void)
{
   int i = 0; 
   int x_start = ALIGNMENT_LEFT;
   int y_curr  = ALIGNMENT_TOP;
   int line_height = FONT_SIZE + 8; 

   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   string names[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1"};
   bool show[] = {InpShow_M1, InpShow_M5, InpShow_M15, InpShow_M30, InpShow_H1, InpShow_H4, InpShow_D1};

   for(int k=0; k<ArraySize(show); k++)
   {
      if(show[k])
      {
         string objName = "RSI_LBL_" + names[k];

         // Creamos la etiqueta RELATIVA al container
         if(!m_timeFrame[i].Create(m_chart_id, objName, m_subwin, x_start, y_curr, x_start + 50, y_curr + FONT_SIZE))
            return false;

         m_timeFrame[i].Text(names[k] + ":");
         m_timeFrame[i].FontSize(FONT_SIZE);
         PrintFormat("Timeframe %s label creado: x1=%d, y1=%d, x2=%d, y2=%d", names[k], x_start, y_curr, x_start + 50, y_curr + FONT_SIZE);

         // IMPORTANTE: Añadimos la etiqueta al diálogo principal
         if(!Add(m_timeFrame[i])) return false;

         y_curr += line_height; 
         i++; 
      }
   }

   ChartRedraw();
   return true;
}

bool CDisplay::Initialize()
{
  //1- Crear el container -coordenadas absolutas-
  g_display.Create(0, "RSI_Display", 0, DISPLAY_XX, DISPLAY_YY, DISPLAY_XX + 
                  DISPLAY_WIDTH, DISPLAY_YY + DISPLAY_WIDTH);  
  //1- Crear el panel -coordenadas relativas-
   g_display.CreatePanel(0, 0, DISPLAY_WIDTH / 2, DISPLAY_WIDTH / 2);
  //2- Crear los timeFrames labels -coordenadas relativas-
   g_display.CreateTimeFrameLabels();

  return true;
}


/* void CDisplay::Destroy(void)
{
  for(int i=0; i<ArraySize(m_timeFrame); i++)
  {
    m_timeFrame[i].Destroy();//Borra físicamente el objeto del gráfico
  }

  m_panel.Destroy(); //esto también debería borrar lo que hay dentro
} */

/* --------------- END Class CDisplay -------------------- */


CDisplay g_display;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    g_display.Initialize();

    EventSetTimer(REFRESH_INTERVAL);
   
    return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  g_display.Destroy();
  EventKillTimer();
  
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {

   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate function                                                   |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double &price[]) 
  {
    return(rates_total);
  }

//+------------------------------------------------------------------+
