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
   EventSetTimer(600);
   crearBotonCalcularArrayPrecios();
   ChartRedraw();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  EventKillTimer();
  ObjectDelete(0, "BTN_CALCULAR");
  ChartRedraw();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() { }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  // Manejar el clic en el botón
  if(id == CHARTEVENT_OBJECT_CLICK && sparam == "BTN_CALCULAR")
    {
    string nombre = "";
    int total_objects = ObjectsTotal(0, -1, -1);

    // Iterar por todos los objetos para encontrar el primero seleccionado (que no sea el botón)
    for(int i = 0; i < total_objects; i++)
      {
        string obj_name = ObjectName(0, i);
        //--- check button is not selected -otherwise error-
        if(ObjectGetInteger(0, obj_name, OBJPROP_SELECTED) && obj_name != "BTN_CALCULAR")
          {
          nombre = obj_name;
          PrintFormat("Objeto seleccionado: %s", obj_name);
          //PENDING: cambiar el loop cuando haya que seleccionar todos los objetos -producción-
          break;
          }
      }

    if(nombre != "")
      {
        PrecioMinuto resultado[];
        calcularPrecioAlMinuto(nombre, resultado);
        mostrarArrayPrecioMinuto(resultado);
      }
    else
      {
        Alert("Por favor, selecciona una línea en el gráfico.");
      }

    // Deseleccionar el botón para efecto visual
    ObjectSetInteger(0, "BTN_CALCULAR", OBJPROP_STATE, false);
    ChartRedraw();
    }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calcula el precio de un objeto de línea para cada minuto del día |
//+------------------------------------------------------------------+
void calcularPrecioAlMinuto(string nombreObjeto, PrecioMinuto &resultado[])
{
  //DynamicArray => memory from heap
  ArrayResize(resultado, 1440); // 1440 minutos en un dia

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

//+------------------------------------------------------------------+
//| Muestra los primeros 100 elementos del array de precios          |
//+------------------------------------------------------------------+
void mostrarArrayPrecioMinuto(PrecioMinuto &resultado[])
{
  int total = ArraySize(resultado);
  int limite = (total > 100) ? 100 : total;

  Print("Mostrando los primeros ", limite, " registros del array:");

  for(int i = 0; i < limite; i++)
    {
    string tiempo = TimeToString(resultado[i].tiempo, TIME_DATE | TIME_MINUTES);
    string precio = DoubleToString(resultado[i].precio, _Digits);
    PrintFormat("[%d] Tiempo: %s, Precio: %s", i, tiempo, precio);
    }
}

//+------------------------------------------------------------------+
//| Crea un botón en el gráfico para ejecutar el cálculo            |
//+------------------------------------------------------------------+
void crearBotonCalcularArrayPrecios(void)
{
  string name = "BTN_CALCULAR";
  if(ObjectFind(0, name) < 0)
    {
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, 30);
    ObjectSetString(0, name, OBJPROP_TEXT, "Calcular Precios");
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrDodgerBlue);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrNONE);
    }
}
