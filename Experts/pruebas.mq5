//+------------------------------------------------------------------+
//|                                                      pruebas.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(60);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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

//TODO:Implementar el código de la función
/* */ calcularPrecioAlMinuto(/* se le pasa una linea (horizontal o de tendencia) */)
{
  /* Parametro: cualquier linea del gráfico
     return: un array de 1440 elementos con el precio de la linea en cada minuto del día actual.
     struct {datetime tiempo; float precio}
  */
}