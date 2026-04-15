//Show the indicator in the chart window
//#property indicator_chart_window => da error
#property strict
//Required -for scripts only- to display a window with the properties when attaching the script
#property script_show_inputs
//nuestra el nombre del EA en la esquina superior derecha
#property indicator_chart_window 

//Input keyword para los parámetros que se asignan desde el pop-up (F7)
input double OffsetPoints = 15;   // Desplazamiento en puntos

string ButtonName = "DrawParallelBtn";

// OnTick solo está activo en los Expert Advisor, pero lo dejo para quitar el error: "OnCalculate not found"
void OnTick() {}

// Initialization
int OnInit()
{
   ObjectCreate(0, ButtonName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, ButtonName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, ButtonName, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, ButtonName, OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, ButtonName, OBJPROP_YSIZE, 25);
   ObjectSetInteger(0, ButtonName, OBJPROP_COLOR, clrWhite);          // Color del texto
   ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, clrOrange);   // Color de fondo
   ObjectSetString(0, ButtonName, OBJPROP_TEXT, "Paralela");
   
   ObjectSetInteger(0, ButtonName, OBJPROP_STATE, false); //IMPORTANTE

   return INIT_SUCCEEDED;
}

// De-initialization
void OnDeinit(const int reason)
{
   // Borramos el botón al quitar el EA del gráfico
   ObjectDelete(0, ButtonName);
}

//+--------------------------------------------------+
//| Gestión de eventos (CON DELAY)                   |
//+--------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == ButtonName)
   {
      Sleep(20);
      
      DrawParallel();
      ObjectSetInteger(0, ButtonName, OBJPROP_STATE, false);
   }
}


//+--------------------------------------------------+
//| Buscar línea de tendencia seleccionada (CON DELAY)|
//+--------------------------------------------------+
string GetSelectedTrendLine()
{
   // Pequeño delay inicial para asegurar que la selección está registrada
   Sleep(20);
   
   int total = ObjectsTotal(0, 0, -1);
   
   string selectedTrendLine = "";
   int countSelected = 0;
   
   // Recorrer todos los objetos
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      
      // Verificar que NO sea el botón
      if(name == ButtonName) continue; //vuelve al principio del loop
      
      // Verificar que esté seleccionado
      if(ObjectGetInteger(0, name, OBJPROP_SELECTED) == true)
      {
         // CRUCIAL: Verificar que sea una línea de tendencia
         int objType = (int)ObjectGetInteger(0, name, OBJPROP_TYPE);
         
         if(objType == OBJ_TREND)
         {
            selectedTrendLine = name;
            countSelected++;
            Print("Trendline seleccionada encontrada: ", name);
         }
         else
         {
            Alert("Objeto seleccionado pero NO es trendline: ", name, " (Tipo: ", objType, ")");
         }
      }
      
      if(countSelected > 1)
      {
         selectedTrendLine = "multipleSelection";
         break;
      }
   }//End Loop
   
   return selectedTrendLine;
}


//-----------------------
// Dibujar línea paralela
//-----------------------
void DrawParallel()
{
   string objName = GetSelectedTrendLine();
   
   if(objName == "")
   {
      Alert("No hay ninguna línea de tendencia seleccionada");
      return;
   }
   if(objName == "multipleSelection")
   {
      Alert("ADVERTENCIA: Hay varias trendlines seleccionadas.");
      return;
   }

   Sleep(20);
   
   // Leer coordenadas INMEDIATAMENTE para evitar race conditions
   datetime t1 = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME, 0);
   datetime t2 = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME, 1);
   double   p1 = ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);
   double   p2 = ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);

   // Validar que las coordenadas sean válidas
   if(t1 == 0 || t2 == 0 || p1 == 0 || p2 == 0)
   {
      Alert("Error: Coordenadas de la línea inválidas");
      Print("t1=", t1, " t2=", t2, " p1=", p1, " p2=", p2);
      return;
   }

   // Propiedades visuales originales
   color lineColor = (color)ObjectGetInteger(0, objName, OBJPROP_COLOR);
   int   lineWidth = (int)ObjectGetInteger(0, objName, OBJPROP_WIDTH);
   int   lineStyle = (int)ObjectGetInteger(0, objName, OBJPROP_STYLE);
   long  lineTime  = ObjectGetInteger(0, objName, OBJPROP_TIMEFRAMES);
   
   double offset = OffsetPoints * _Point;

   // SOLUCIÓN: Generar nombre único GARANTIZADO
   string newName = "";
   bool nameFound = false;
   int attempt = 0;
   int maxAttempts = 10;
   
   while(!nameFound && attempt < maxAttempts)
   {
      // Combinar múltiples fuentes de aleatoriedad
      newName = "Parallel_" + IntegerToString(GetTickCount()) + 
                "_" + IntegerToString(MathRand()) + 
                "_" + IntegerToString(attempt);
      
      // Verificar si el nombre No está duplicado
      if(ObjectFind(0, newName) < 0) //If the object is not found, the function returns a negative number)
      {
         nameFound = true; //No duplicado
      }
      else
      {
         Print("Nombre duplicado detectado (intento ", attempt, "): ", newName);
         Sleep(5); // Pequeño delay para cambiar GetTickCount()
         attempt++;
      }
   }
   
   if(!nameFound)
   {
      Alert("Error: No se pudo generar un nombre único después de ", maxAttempts, " intentos");
      return;
   }
   
   Print("Nombre único generado: ", newName);
   
   // Crear línea paralela
   bool created = ObjectCreate(0, newName, OBJ_TREND, 0,
                               t1, p1 + offset,
                               t2, p2 + offset);
   
   if(!created)
   {
      int error = GetLastError();
      Alert("Error al crear la línea paralela. Código: ", error);
      Print("Error details - Name: ", newName, " Error: ", error);
      return;
   }

   // Pequeño delay después de crear el objeto
   Sleep(10);

   // Aplicar propiedades
   ObjectSetInteger(0, newName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, newName, OBJPROP_WIDTH, lineWidth);
   ObjectSetInteger(0, newName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, newName, OBJPROP_TIMEFRAMES, lineTime);
   ObjectSetInteger(0, newName, OBJPROP_BACK, true);
   ObjectSetInteger(0, newName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, newName, OBJPROP_SELECTABLE, true);
   
   // Delay antes de cambiar selecciones
   Sleep(10);
   
   // Gestión de selección
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, newName, OBJPROP_SELECTED, true);
   
   Sleep(10);
   
   // Refrescar el gráfico
   ChartRedraw(0);
   
   Print("Línea paralela creada exitosamente: ", newName);
}