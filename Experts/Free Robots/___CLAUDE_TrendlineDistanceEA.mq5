//+------------------------------------------------------------------+
//|                                          TrendlineDistanceEA.mq5 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Expert Advisor - Distancia a Línea de Tendencia"
#property version   "1.00"
#property strict

// Parámetros de entrada
input double LoteSize = 1.0;              // Tamaño del lote
input double DistanciaPips = 10.0;        // Distancia en pips para activar la operación
input string NombreLinea = "linea_de_prueba"; // Nombre de la línea de tendencia

// Variables globales
datetime ultimaVela = 0;
int digits;
double pipValue;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Obtener número de decimales del símbolo
   digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   // Calcular el valor de 1 pip
   if(digits == 3 || digits == 5)
      pipValue = 10 * _Point;
   else
      pipValue = _Point;
   
   Print("EA iniciado correctamente");
   Print("Símbolo: ", _Symbol);
   Print("Dígitos: ", digits);
   Print("Valor de pip: ", pipValue);
   Print("Buscando línea de tendencia: ", NombreLinea);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("EA detenido");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Verificar si hay una nueva vela de 1 minuto
   datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
   
   if(tiempoActual == ultimaVela)
      return; // No es una nueva vela
   
   ultimaVela = tiempoActual;
   
   // Obtener el precio de cierre de la vela anterior
   double precioCierre = iClose(_Symbol, PERIOD_M1, 1);
   
   // Buscar la línea de tendencia más cercana con el nombre especificado
   double distanciaPips = 0;
   bool lineaEncontrada = false;
   
   if(BuscarDistanciaLineaTendencia(precioCierre, distanciaPips))
   {
      lineaEncontrada = true;
      Print("Distancia a línea de tendencia '", NombreLinea, "': ", 
            DoubleToString(distanciaPips, 1), " pips");
   }
   
   // Si la línea fue encontrada y la distancia es menor a 10 pips
   if(lineaEncontrada && distanciaPips < DistanciaPips)
   {
      // Verificar si tenemos posiciones abiertas
      if(TienePosicionesAbiertas())
      {
         // Cerrar todas las posiciones
         CerrarTodasPosiciones();
         Print("Distancia < ", DistanciaPips, " pips - Cerrando posiciones");
      }
      else
      {
         // Abrir una posición de compra
         AbrirCompra(LoteSize);
         Print("Distancia < ", DistanciaPips, " pips - Abriendo compra de ", LoteSize, " lote(s)");
      }
   }
}

//+------------------------------------------------------------------+
//| Buscar distancia a la línea de tendencia más cercana            |
//+------------------------------------------------------------------+
bool BuscarDistanciaLineaTendencia(double precio, double &distanciaPips)
{
   double distanciaMinima = DBL_MAX;
   bool encontrada = false;
   
   // Recorrer todos los objetos del gráfico
   int totalObjetos = ObjectsTotal(0, 0, OBJ_TREND);
   
   for(int i = 0; i < totalObjetos; i++)
   {
      string nombreObjeto = ObjectName(0, i, 0, OBJ_TREND);
      
      // Verificar si es una línea de tendencia y tiene el nombre correcto
      if(ObjectGetInteger(0, nombreObjeto, OBJPROP_TYPE) == OBJ_TREND &&
         nombreObjeto == NombreLinea)
      {
         // Obtener los puntos de la línea de tendencia
         datetime tiempo1 = (datetime)ObjectGetInteger(0, nombreObjeto, OBJPROP_TIME, 0);
         double precio1 = ObjectGetDouble(0, nombreObjeto, OBJPROP_PRICE, 0);
         datetime tiempo2 = (datetime)ObjectGetInteger(0, nombreObjeto, OBJPROP_TIME, 1);
         double precio2 = ObjectGetDouble(0, nombreObjeto, OBJPROP_PRICE, 1);
         
         // Verificar si la línea se extiende al futuro
         bool rayDerecha = ObjectGetInteger(0, nombreObjeto, OBJPROP_RAY_RIGHT);
         
         // Calcular el precio de la línea en el momento actual
         datetime tiempoActual = TimeCurrent();
         double precioLinea = CalcularPrecioLineaTendencia(tiempo1, precio1, tiempo2, precio2, 
                                                            tiempoActual, rayDerecha);
         
         if(precioLinea != 0)
         {
            // Calcular la distancia en pips
            double distancia = MathAbs(precio - precioLinea) / pipValue;
            
            if(distancia < distanciaMinima)
            {
               distanciaMinima = distancia;
               encontrada = true;
            }
         }
      }
   }
   
   if(encontrada)
   {
      distanciaPips = distanciaMinima;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calcular precio de línea de tendencia en un momento dado        |
//+------------------------------------------------------------------+
double CalcularPrecioLineaTendencia(datetime t1, double p1, datetime t2, double p2, 
                                     datetime tActual, bool extenderDerecha)
{
   // Si el tiempo actual está fuera del rango y no se extiende, retornar 0
   if(!extenderDerecha && (tActual < t1 || tActual > t2))
      return 0;
   
   // Calcular la pendiente de la línea
   double pendiente = (p2 - p1) / (double)(t2 - t1);
   
   // Calcular el precio en el tiempo actual usando interpolación/extrapolación lineal
   double precioCalculado = p1 + pendiente * (double)(tActual - t1);
   
   return precioCalculado;
}

//+------------------------------------------------------------------+
//| Verificar si hay posiciones abiertas                            |
//+------------------------------------------------------------------+
bool TienePosicionesAbiertas()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones del símbolo actual                  |
//+------------------------------------------------------------------+
void CerrarTodasPosiciones()
{
   MqlTradeRequest request;
   MqlTradeResult result;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            ZeroMemory(request);
            ZeroMemory(result);
            
            request.action = TRADE_ACTION_DEAL;
            request.position = ticket;
            request.symbol = _Symbol;
            request.volume = PositionGetDouble(POSITION_VOLUME);
            request.deviation = 10;
            request.magic = 0;
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               request.type = ORDER_TYPE_SELL;
            }
            else
            {
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               request.type = ORDER_TYPE_BUY;
            }
            
            if(!OrderSend(request, result))
            {
               Print("Error al cerrar posición: ", GetLastError());
               Print("Código de retorno: ", result.retcode);
            }
            else
            {
               Print("Posición cerrada exitosamente. Ticket: ", ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Abrir posición de compra                                        |
//+------------------------------------------------------------------+
void AbrirCompra(double lotes)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotes;
   request.type = ORDER_TYPE_BUY;
   request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation = 10;
   request.magic = 0;
   request.type_filling = ORDER_FILLING_FOK;
   
   if(!OrderSend(request, result))
   {
      Print("Error al abrir compra: ", GetLastError());
      Print("Código de retorno: ", result.retcode);
   }
   else
   {
      Print("Compra abierta exitosamente. Ticket: ", result.order);
   }
}
//+------------------------------------------------------------------+
