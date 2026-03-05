// ES LA COMBINACIN DE LOS EA OFFSET Y NIVELES HORIZONTALES

#property copyright "Copyright 2024"
#property link      "https://github.com/rentzboy/MQL5"
#property version   "1.00"
#property strict

// Input keyword para los parmetros que se asignan desde el pop-up (F7)
input double OffsetPoints = 15;   // Desplazamiento en puntos

string ButtonName = "DrawParallelBtn";
int totalObjetos = 0; //global

struct nivelHorizontal
{
  string nombre;
  double precio;
  bool existe;
} cierre_H_1D ={"Cierre_1D", 0, false}, cierre_H_4H ={"Cierre_4H", 0, false}, cierre_H_1W ={"Cierre_1W", 0, false};

struct vela_t
{
  datetime timeStamp;
  double open;
  double high;
  double low;
  double close;
} vela_4H = {0, 0, 0, 0, 0}, vela_1D = {0, 0, 0, 0, 0}, vela_1W = {0, 0, 0, 0, 0};

//----------------------- FUNCIONES DE METATRADER -----------------------//

void OnTick()
{
   actualizarNivelesCierreVelas();
}

// Initialization
int OnInit()
{
   if(ObjectFind(0, ButtonName) < 0)
   {
      if(!ObjectCreate(0, ButtonName, OBJ_BUTTON, 0, 0, 0))
      {
         Print("Error al crear el botón. Código: ", GetLastError());
      }
   }
   ObjectSetInteger(0, ButtonName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, ButtonName, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, ButtonName, OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, ButtonName, OBJPROP_YSIZE, 25);
   ObjectSetInteger(0, ButtonName, OBJPROP_COLOR, clrWhite);          // Color del texto
   ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, clrDodgerBlue);   // Color de fondo
   ObjectSetString(0, ButtonName, OBJPROP_TEXT, "Paralela");
   ObjectSetInteger(0, ButtonName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, ButtonName, OBJPROP_STATE, false);

   actualizarNivelesCierreVelas();
   ChartRedraw(0);

   return INIT_SUCCEEDED;
}

// De-initialization
void OnDeinit(const int reason)
{
   ObjectDelete(0, ButtonName);
}

// Gestin de eventos
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == ButtonName)
   {
      DrawParallel();
      ObjectSetInteger(0, ButtonName, OBJPROP_STATE, false);
      ChartRedraw(0);
   }
}

//----------------------- FUNCIONES DE OFFSET -----------------------//
string GetSelectedTrendLine()
{
   int total = ObjectsTotal(0, 0, OBJ_TREND);

   string selectedTrendLine = "";
   int countSelected = 0;

   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_TREND);

      if(ObjectGetInteger(0, name, OBJPROP_SELECTED) == true)
      {
         selectedTrendLine = name;
         countSelected++;
      }

      if(countSelected > 1)
      {
         selectedTrendLine = "multipleSelection";
         break;
      }
   }

   return selectedTrendLine;
}

void DrawParallel()
{
   string objName = GetSelectedTrendLine();

   if(objName == "")
   {
      Alert("No hay ninguna lnea de tendencia seleccionada");
      return;
   }
   if(objName == "multipleSelection")
   {
      Alert("ADVERTENCIA: Hay varias trendlines seleccionadas.");
      return;
   }

   datetime t1 = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME, 0);
   datetime t2 = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME, 1);
   double   p1 = ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);
   double   p2 = ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);

   if(t1 == 0 || t2 == 0 || p1 == 0 || p2 == 0)
   {
      Alert("Error: Coordenadas de la lnea invlidas");
      return;
   }

   color lineColor = (color)ObjectGetInteger(0, objName, OBJPROP_COLOR);
   int   lineWidth = (int)ObjectGetInteger(0, objName, OBJPROP_WIDTH);
   long  lineTime  = ObjectGetInteger(0, objName, OBJPROP_TIMEFRAMES);

   double offset = OffsetPoints * _Point;

   string newName = "Parallel_" + IntegerToString(GetTickCount()) + "_" + IntegerToString(MathRand());

   if(ObjectCreate(0, newName, OBJ_TREND, 0, t1, p1 + offset, t2, p2 + offset))
   {
      ObjectSetInteger(0, newName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, newName, OBJPROP_WIDTH, lineWidth);
      ObjectSetInteger(0, newName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, newName, OBJPROP_TIMEFRAMES, lineTime);
      ObjectSetInteger(0, newName, OBJPROP_BACK, true);
      ObjectSetInteger(0, newName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, newName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, newName, OBJPROP_SELECTED, true);

      ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
      ChartRedraw(0);
      Print("Lnea paralela creada: ", newName);
   }
   else
   {
      Alert("Error al crear la lnea paralela: ", GetLastError());
   }
}

//----------------------- FUNCIONES DE CIERRE DE VELA -----------------------//

void actualizarNivelesCierreVelas(void)
{
  totalObjetos = ObjectsTotal(0, 0, OBJ_HLINE);

  if(buscarVelasCierreAnteriores())
  {
     buscarNivelesHorizontalesCierre();
     actualizarNivelHorizontal();
  }
}

bool buscarNivelesHorizontalesCierre(void)
{
   cierre_H_1D.existe = false;
   cierre_H_1W.existe = false;

   for(int i = totalObjetos-1; i >= 0 ; i--)
   {
      string nombreObjeto = ObjectName(0, i, 0, OBJ_HLINE);

      if(nombreObjeto == cierre_H_1D.nombre)
      {
        cierre_H_1D.existe = true;
        cierre_H_1D.precio = ObjectGetDouble(0, nombreObjeto, OBJPROP_PRICE, 0);
      }
      if (nombreObjeto == cierre_H_1W.nombre)
      {
        cierre_H_1W.existe = true;
        cierre_H_1W.precio = ObjectGetDouble(0, nombreObjeto, OBJPROP_PRICE, 0);
      }
    }
    return (cierre_H_1D.existe || cierre_H_1W.existe);
}

bool buscarVelasCierreAnteriores(void)
{
  vela_1D.close = iClose(_Symbol, PERIOD_D1, 1);
  vela_1W.close = iClose(_Symbol, PERIOD_W1, 1);
  return (vela_1D.close > 0 && vela_1W.close > 0);
}

void actualizarNivelHorizontal(void)
{
  if (MathAbs(cierre_H_1D.precio - vela_1D.close) > _Point || !cierre_H_1D.existe)
  {
    cierre_H_1D.precio = vela_1D.close;
    if (cierre_H_1D.existe)
      ObjectSetDouble(0, cierre_H_1D.nombre, OBJPROP_PRICE, 0, cierre_H_1D.precio);
    else
      DibujarLineaHorizontal(cierre_H_1D.nombre, cierre_H_1D.precio, clrDarkKhaki, "NivelHorizonalCierre_1D");
  }

  if (MathAbs(cierre_H_1W.precio - vela_1W.close) > _Point || !cierre_H_1W.existe)
  {
    cierre_H_1W.precio = vela_1W.close;
    if (cierre_H_1W.existe)
      ObjectSetDouble(0, cierre_H_1W.nombre, OBJPROP_PRICE, 0, cierre_H_1W.precio);
    else
      DibujarLineaHorizontal(cierre_H_1W.nombre, cierre_H_1W.precio, clrDarkOrange, "NivelHorizonalCierre_1W");
  }
}

bool DibujarLineaHorizontal(string nombre, double precio, color colorLinea, string descripcion)
{
   if(ObjectCreate(0, nombre, OBJ_HLINE, 0, 0, precio))
   {
      ObjectSetString(0, nombre, OBJPROP_TEXT, descripcion);
      ObjectSetInteger(0, nombre, OBJPROP_COLOR, colorLinea);
      ObjectSetInteger(0, nombre, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, nombre, OBJPROP_STYLE, STYLE_DASHDOT);
      ObjectSetInteger(0, nombre, OBJPROP_BACK, true);
      ObjectSetInteger(0, nombre, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, nombre, OBJPROP_SELECTED, false);

      long visibility = OBJ_PERIOD_M1 | OBJ_PERIOD_M5 | OBJ_PERIOD_M15 | OBJ_PERIOD_M30 | OBJ_PERIOD_H1 | OBJ_PERIOD_D1;
      if (nombre == cierre_H_1W.nombre) visibility |= OBJ_PERIOD_H4;

      ObjectSetInteger(0, nombre, OBJPROP_TIMEFRAMES, visibility);
      ChartRedraw(0);
      return true;
   }
   return false;
}
