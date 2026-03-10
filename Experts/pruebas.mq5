//+------------------------------------------------------------------+
//|                                                      pruebas.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



struct PrecioMinuto
  {
   datetime          tiempo;
   double            precio;
  };

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

//+------------------------------------------------------------------+
//| Calcula el precio de un objeto de línea para cada minuto del día |
//+------------------------------------------------------------------+
void calcularPrecioAlMinuto(string nombreObjeto, PrecioMinuto &resultado[])
  {
   ArrayResize(resultado, 1440);

// Para obtener el inicio del día actual (00:00): resetear hora, minuto y segundo (queda solo la fecha)
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   datetime tiempoInicio = StructToTime(dt);

   for(int i = 0; i < 1440; i++)
     {
      datetime tiempoActual = tiempoInicio + i * 60;
      resultado[i].tiempo = tiempoActual;

      // Resetear error para validar la obtención del valor
      ResetLastError();
      double precio = ObjectGetValueByTime(0, nombreObjeto, tiempoActual, 0); //line_id always 0 for lines

      // Si hay error o el precio es 0, asignamos 0.0
      if(GetLastError() != ERR_SUCCESS || precio <= 0)
        {
         resultado[i].precio = 0.0;
        }
      else
        {
         resultado[i].precio = precio;
        }
     }
  }

void mostrarArrayPrecioMinuto(PrecioMinuto &precioMinuto)
{
/*TODO: existe alguna función en la libreria de MQL5 para mostrar los datos de un array o hay que iterar
mediante un loop y Print ? Hay alguna otra solución ? También quiero mostrar el array en los logs
Desde donde tengo que llamar a esta función -> implementar */
   for(int i = 0; i < 1440; i++)
     {
      string tiempo = TimeToString(precioMinuto[i].tiempo);
      string precio = DoubleToString(precioMinuto[i].precio);
      Print("Tiempo: " + tiempo + ", Precio: " + precio);
     }
}

void crearBotonCalcularArrayPrecios (void)
{
  /*TODO: Añadir un botón en la esquina superior del gráfico para llamar 
  a la función calcularPrecioAlMinuto para el objeto seleccionado.
  En caso de no haber ningún objeto seleccionado, mostrar un mensaje.
  A esta función se llamará desde OnInit() -> crear la llamada */
}



