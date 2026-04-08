//+------------------------------------------------------------------+
//|                                                     RSI_TONY.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

/* NO DA el mismo resultado que el RSI original, pues no se calcula igual,
pero sirve como ejemplo para programar un indicator y para mostrar
 los datos en un dashboard */

#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Controls/WndContainer.mqh>
#include <Controls/Dialog.mqh>
#include <Controls/Label.mqh>
#include <Controls/Rect.mqh>
#include <Controls/Panel.mqh>
#include <Indicators/Oscilators.mqh>


//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 3 //voy a utilizar la MQL Standard Library
#property indicator_plots 1 // no pinta ninguna linea
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 70
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue

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

#define REFRESH_INTERVAL  2
#define DEBUG_LOGGING     false   // Enable verbose debug logging
#define DISPLAY_XX        320      // Dashboard X Position
#define DISPLAY_YY        50      // Dashboard Y Position
#define DISPLAY_WIDTH     250     // Dashboard Width (pixels)
#define ALIGNMENT_LEFT    3
#define ALIGNMENT_TOP     3
#define ALIGNMENT_RIGHT   3
#define ALIGNMENT_BOTTOM  3
#define SPACING           5
#define FONT_SIZE         10      // Font Size (6-24)

//Al definirlos como buffer, Metatrader gestiona la memoria para ellos (se va ampliando según crecen los datos)
double ExtRSIBuffer[]; //Hay que definirlos como globals
double ExtPosBuffer[];
double ExtNegBuffer[];
double sum_pos = 0.0;
double sum_neg = 0.0;


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
  bool CreatePanelLabels(void);
  void PrintLabelCoordenates(CWndObj &win);

  public:
  CDisplay(/* args */) {};
  ~CDisplay() {Print("CDisplay destroyed");};
  bool Initialize(void);
  void UpdateRSI(void);
  //Destroy(): se hereda de CWndContainer from CDialog
  //Add(): se hereda de CWndContainer from CDialog
};

void CDisplay::UpdateRSI(void)
{
  bool showTF[] = {InpShow_M1, InpShow_M5, InpShow_M15, InpShow_M30, InpShow_H1, InpShow_H4, InpShow_D1};
   for(int i=0; i<ArraySize(showTF); i++)
   {
      if(showTF[i] && i == 0)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
      if(showTF[i] && i == 1)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
      if(showTF[i] && i == 2)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
      if(showTF[i] && i == 3)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
      if(showTF[i] && i == 4)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
      if(showTF[i] && i == 5)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
      if(showTF[i] && i == 6)
      {
        g_indicator[i].Refresh();
        m_rsiTimeFrame[i].Text(DoubleToString(g_indicator[i].Main(0), 2));
      }
   }
   ChartRedraw();
}

void CDisplay::PrintLabelCoordenates(CWndObj &win)
{
  int x1 = win.Rect().left;
  int x2 = win.Rect().right;
  int y1 = win.Rect().top;
  int y2 = win.Rect().bottom;
  PrintFormat("TimeFrameLabel Left-top: %d - %d", x1, y1);
  PrintFormat("TimeFrameLabel Right-bottom: %d - %d", x2, y2);
}

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

bool CDisplay::CreatePanelLabels(void)
{
   int i = 0; 
   int x_start_tf = ALIGNMENT_LEFT;
   int x_end_tf = x_start_tf + (FONT_SIZE * 4);
   int x_start_rsi = x_end_tf + ALIGNMENT_LEFT;
  int x_end_rsi = x_start_rsi + (FONT_SIZE * 4);
   int y_curr  = ALIGNMENT_TOP;
   int line_height = FONT_SIZE + 8; 

   string TF_labels[] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1"};
   bool showTF[] = {InpShow_M1, InpShow_M5, InpShow_M15, InpShow_M30, InpShow_H1, InpShow_H4, InpShow_D1};

   for(int k=0; k<ArraySize(showTF); k++)
   {
      if(showTF[k])
      {
         string objNameLbl = "RSI_LBL_" + TF_labels[k];
         string objNameRSI = "RSI_LBL_" + TF_labels[k] + "value";

         // Creamos la etiqueta con las coordenadas relativas al container
         if(!m_timeFrame[i].Create(ChartID(), objNameLbl, m_subwin, x_start_tf, y_curr, x_end_tf, y_curr + FONT_SIZE))
            return false;
         m_timeFrame[i].Text(TF_labels[k] + ":");
         m_timeFrame[i].FontSize(FONT_SIZE);
         if(!Add(m_timeFrame[i])) return false;//Añadimos la etiqueta al panel principal (container)

         if(!m_rsiTimeFrame[i].Create(ChartID(), objNameRSI, m_subwin, x_start_rsi, y_curr, x_end_rsi, y_curr + FONT_SIZE))
            return false;
         m_rsiTimeFrame[i].Text("0.00"); //De inicio todas a 0.00 y luego con eventTime lo actualizamos
         m_rsiTimeFrame[i].FontSize(FONT_SIZE);
         if(!Add(m_rsiTimeFrame[i])) return false; // IMPORTANTE: Añadimos la etiqueta al panel principal (container)

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
  g_display.Create(ChartID(), "RSI_Display", 0, DISPLAY_XX, DISPLAY_YY, DISPLAY_XX + 
                  DISPLAY_WIDTH, DISPLAY_YY + DISPLAY_WIDTH);  
  //1- Crear el panel -coordenadas relativas-
   g_display.CreatePanel(0, 0, DISPLAY_WIDTH / 2, DISPLAY_WIDTH / 2);
  //2- Crear los timeFrames labels -coordenadas relativas-
  g_display.CreatePanelLabels();

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

/* --------------- Utility functions -------------------- */
void IndicatorBuffersMapping(void)
{
  //--- indicator buffers mapping
  SetIndexBuffer(0,ExtRSIBuffer,INDICATOR_DATA);
  SetIndexBuffer(1,ExtPosBuffer,INDICATOR_CALCULATIONS);
  SetIndexBuffer(2,ExtNegBuffer,INDICATOR_CALCULATIONS);
  //--- set accuracy
  IndicatorSetInteger(INDICATOR_DIGITS,2);
  //--- sets first bar from what index will be drawn
  PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpRSI_Period); //IMPORTANT: index=0 => plot ExtRSIBuffer
  //--- name for DataWindow and indicator subwindow label
  IndicatorSetString(INDICATOR_SHORTNAME,"RSI("+string(InpRSI_Period)+")");
}

bool RSI_Initialize(void)
{
  bool showTF[] = {InpShow_M1, InpShow_M5, InpShow_M15, InpShow_M30, InpShow_H1, InpShow_H4, InpShow_D1};
   for(int i=0; i<ArraySize(showTF); i++)
   {
      if(showTF[i] && i == 0) 
        if(!g_indicator[i].Create(_Symbol, PERIOD_M1, InpRSI_Period, PRICE_CLOSE)) return false;
      if(showTF[i] && i == 1) 
        if(!g_indicator[i].Create(_Symbol, PERIOD_M5, InpRSI_Period, PRICE_CLOSE)) return false;
      if(showTF[i] && i == 2) 
        if(!g_indicator[i].Create(_Symbol, PERIOD_M15, InpRSI_Period, PRICE_CLOSE)) return false;
      if(showTF[i] && i == 3) 
        if(!g_indicator[i].Create(_Symbol, PERIOD_M30, InpRSI_Period, PRICE_CLOSE)) return false;
      if(showTF[i] && i == 4)
        if(!g_indicator[i].Create(_Symbol, PERIOD_H1, InpRSI_Period, PRICE_CLOSE)) return false;
      if(showTF[i] && i == 5) 
        if(!g_indicator[i].Create(_Symbol, PERIOD_H4, InpRSI_Period, PRICE_CLOSE)) return false;
      if(showTF[i] && i == 6)
        if(!g_indicator[i].Create(_Symbol, PERIOD_D1, InpRSI_Period, PRICE_CLOSE)) return false;
   }
  return true;
}

/* --------------- END Utility functions -------------------- */

/* --------------- Global variables  -------------------- */
CDisplay g_display;
CiRSI g_indicator[7];

/* --------------- END Global variables -------------------- */

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    g_display.Initialize();

    if(!RSI_Initialize()) Print("RSI_Initialize() failed");

    /* Si comentamos la llamada a IndicatorBuffersMapping() entonces
       los valores del RSI no se muestran en el panel 
       pues da un runtime error, Array out of range */
    IndicatorBuffersMapping();

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
    g_display.UpdateRSI();
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
  //Si no hay velas nuevas OR muy pocas velas => Do nothing
  if(rates_total < InpRSI_Period+1 || rates_total == prev_calculated) return rates_total;

  //Unicamente se tiene que ejecutar la primera vez para los primeros 14 elementos
  if(prev_calculated < InpRSI_Period+1)
  {
    //PrintFormat("Prev_calculated = %d", prev_calculated);
    //PrintFormat("Total_rates = %d", rates_total);
    //El primer elemento todo es 0
    ExtRSIBuffer[0] = 0;
    ExtPosBuffer[0] = 0;
    ExtNegBuffer[0] = 0;

    for(int i=1; i < InpRSI_Period+1; i++)
    {
    double diff = price[i] - price[i-1];
    //PrintFormat("Diff = %f", diff);
    if (diff>0)
    {
      ExtPosBuffer[i] = diff;
      ExtNegBuffer[i] = 0;
    }
    else
    {
      ExtPosBuffer[i] = 0;
      ExtNegBuffer[i] = diff;
    }

    sum_pos += ExtPosBuffer[i];
    sum_neg += ExtNegBuffer[i];
    //PrintFormat("ExtPosBuffer[%f] = %f; ExtNegBuffer[%d] = %f", i, ExtPosBuffer[i], i, ExtNegBuffer[i]);
    //PrintFormat("Sum_pos = %f; Sum_neg = %f", sum_pos, sum_neg);
    }
  }

  //Bucle normal, para los elementos > ExtRSIPeriod
  int inicio = MathMax(prev_calculated, InpRSI_Period);
  //PrintFormat("Inicio = %d", inicio);
  for(int i=inicio; i <rates_total; i++)
  {
    double diff = price[i] - price[i-1];
    if (diff>0)
    {
      ExtPosBuffer[i] = diff;
      ExtNegBuffer[i] = 0;
    }
    else
    {
      ExtPosBuffer[i] = 0;
      ExtNegBuffer[i] = diff;
    }

    sum_pos += ExtPosBuffer[i];
    sum_neg += ExtNegBuffer[i];

    double avg_pos = sum_pos / InpRSI_Period;
    double avg_neg = sum_neg / InpRSI_Period;

    if (avg_neg) //No dividir x 0
    {
      ExtRSIBuffer[i] = 100 - (100 / (1 + (avg_pos / MathAbs(avg_neg))));
      //PrintFormat("ExtRSIBuffer[%d] = %f", i, ExtRSIBuffer[i]);
    }
  
    //Restamos la última vela del buffer
    sum_pos -= ExtPosBuffer[(i-InpRSI_Period)];
    sum_neg -= ExtNegBuffer[i-InpRSI_Period];
  }
  return rates_total;
}

//+------------------------------------------------------------------+
