// ES LA COMBINACIN DE LOS EA OFFSET Y NIVELES HORIZONTALES



//Show the indicator in the chart window

//#property indicator_chart_window => da error

#property strict

//Required -for scripts only- to display a window with the properties when attaching the script

#property script_show_inputs

//nuestra el nombre del EA en la esquina superior derecha

#property indicator_chart_window



//Input keyword para los parmetros que se asignan desde el pop-up (F7)

input double OffsetPoints = 15;   // Desplazamiento en puntos



string ButtonName = "DrawParallelBtn";

int totalObjetos = 0; //global



struct nivelHorizontal

{

  string nombre;

  double precio;

  bool existe;

  //datetime tiempo;

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



// OnTick solo est activo en los Expert Advisor, pero lo dejo para quitar el error: "OnCalculate not found"

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

   ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, clrDodgerBlue);   // Color de fondo

   ObjectSetString(0, ButtonName, OBJPROP_TEXT, "Paralela");



   ObjectSetInteger(0, ButtonName, OBJPROP_STATE, false); //IMPORTANTE



   actualizarNivelesCierreVelas();



   return INIT_SUCCEEDED;

}



// De-initialization

void OnDeinit(const int reason)

{

   // Borramos el botn al quitar el EA del grfico

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

      Sleep(20);



      DrawParallel();

      ObjectSetInteger(0, ButtonName, OBJPROP_STATE, false);

   }

}



//----------------------- FUNCIONES DE OFFSET -----------------------//

// Buscar lnea de tendencia seleccionada

string GetSelectedTrendLine()

{

   // Pequeo delay inicial para asegurar que la seleccin est registrada

   Sleep(20);



   int total = ObjectsTotal(0, 0, -1);



   string selectedTrendLine = "";

   int countSelected = 0;



   // Recorrer todos los objetos

   for(int i = total - 1; i >= 0; i--)

   {

      string name = ObjectName(0, i);



      // Verificar que NO sea el botn

      if(name == ButtonName) continue; //vuelve al principio del loop



      // Verificar que est seleccionado

      if(ObjectGetInteger(0, name, OBJPROP_SELECTED) == true)

      {

         // CRUCIAL: Verificar que sea una lnea de tendencia

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



// Dibujar lnea paralela

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



   Sleep(20);



   // Leer coordenadas INMEDIATAMENTE para evitar race conditions

   datetime t1 = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME, 0);

   datetime t2 = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME, 1);

   double   p1 = ObjectGetDouble(0, objName, OBJPROP_PRICE, 0);

   double   p2 = ObjectGetDouble(0, objName, OBJPROP_PRICE, 1);



   // Validar que las coordenadas sean vlidas

   if(t1 == 0 || t2 == 0 || p1 == 0 || p2 == 0)

   {

      Alert("Error: Coordenadas de la lnea invlidas");

      Print("t1=", t1, " t2=", t2, " p1=", p1, " p2=", p2);

      return;

   }



   // Propiedades visuales originales

   color lineColor = (color)ObjectGetInteger(0, objName, OBJPROP_COLOR);

   int   lineWidth = (int)ObjectGetInteger(0, objName, OBJPROP_WIDTH);

   int   lineStyle = (int)ObjectGetInteger(0, objName, OBJPROP_STYLE);

   long  lineTime  = ObjectGetInteger(0, objName, OBJPROP_TIMEFRAMES);



   double offset = OffsetPoints * _Point;



   // SOLUCIN: Generar nombre nico GARANTIZADO

   string newName = "";

   bool nameFound = false;

   int attempt = 0;

   int maxAttempts = 10;



   while(!nameFound && attempt < maxAttempts)

   {

      // Combinar mltiples fuentes de aleatoriedad

      newName = "Parallel_" + IntegerToString(GetTickCount()) +

                "_" + IntegerToString(MathRand()) +

                "_" + IntegerToString(attempt);



      // Verificar si el nombre No est duplicado

      if(ObjectFind(0, newName) < 0) //If the object is not found, the function returns a negative number)

      {

         nameFound = true; //No duplicado

      }

      else

      {

         Print("Nombre duplicado detectado (intento ", attempt, "): ", newName);

         Sleep(5); // Pequeo delay para cambiar GetTickCount()

         attempt++;

      }

   }



   if(!nameFound)

   {

      Alert("Error: No se pudo generar un nombre nico despus de ", maxAttempts, " intentos");

      return;

   }



   Print("Nombre nico generado: ", newName);



   // Crear lnea paralela

   bool created = ObjectCreate(0, newName, OBJ_TREND, 0,

                               t1, p1 + offset,

                               t2, p2 + offset);



   if(!created)

   {

      int error = GetLastError();

      Alert("Error al crear la lnea paralela. Cdigo: ", error);

      Print("Error details - Name: ", newName, " Error: ", error);

      return;

   }



   // Pequeo delay despus de crear el objeto

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



   // Gestin de seleccin

   ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);

   ObjectSetInteger(0, newName, OBJPROP_SELECTED, true);



   Sleep(10);



   // Refrescar el grfico

   ChartRedraw(0);



   Print("Lnea paralela creada exitosamente: ", newName);

}



//----------------------- FUNCIONES DE CIERRE DE VELA -----------------------//



void actualizarNivelesCierreVelas(void)

{

  // Recorrer todos los objetos (lineas horizontales) del grfico actual

  totalObjetos = ObjectsTotal(0, 0, OBJ_HLINE); // 0 = grfico actual, 0 = ventana principal, -1 = todos los tipos

  if (!totalObjetos)

    Alert("No hay lineas horizontales creadas"); //muy improbable, algun error raro



  buscarVelasCierreAnteriores();

  buscarNivelesHorizontalesCierre();

  actualizarNivelHorizontal();

}



//Busca las lineas de cierre 1D, 4H y 1W por nombre

bool buscarNivelesHorizontalesCierre(void)

{

   for(int i = totalObjetos-1; i > 0 ; i--)

   {

      string nombreObjeto = ObjectName(0, i);



      // Verificar si el nombre coincide

      if(nombreObjeto == cierre_H_1D.nombre)

      {

        cierre_H_1D.existe = true;

        cierre_H_1D.precio = ObjectGetDouble(0, nombreObjeto, OBJPROP_PRICE, 0);

        Print("Lnea horizonal 1D encontrada: ", nombreObjeto);

      }

      if (nombreObjeto == cierre_H_1W.nombre)

      {

        cierre_H_1W.existe = true;

        cierre_H_1W.precio = ObjectGetDouble(0, nombreObjeto, OBJPROP_PRICE, 0);

        Print("Lnea horizonal 1W encontrada: ", nombreObjeto);

      }

      if (cierre_H_1D.existe == true && cierre_H_1W.existe == true)

        return true; //Exit loop

    }

      Print("WARNING: No hemos encontrado las lineas de cierre 1D y/o 1W");

      return false; // Lnea encontrada

}



//Busca los niveles de cierre anteriores de las velas de 1D, 4H y 1W

bool buscarVelasCierreAnteriores(void)

{

  vela_1D.close = iClose(Symbol(), PERIOD_D1, 1); //1 = vela anterior

  vela_1W.close = iClose(Symbol(), PERIOD_W1, 1); //1 = vela anterior

  if (vela_1D.close > 0 && vela_1W.close > 0)

  {

    Print("Cierre Vela 1D: ", DoubleToString(vela_1D.close, Digits()),

          " - Cierre Vela 1W: ", DoubleToString(vela_1W.close, Digits()));

    return true;

  }



  Print("ERROR: No hemos encontrado las velas de 1D y 1W");

  return false;

}

//Actualizar la linea horizontal segun el precio de la vela anterior de 1W/1D/4H

void actualizarNivelHorizontal(void)

{

  //CASE: NIVEL 1D

  if (cierre_H_1D.precio !=vela_1D.close) //Nivel horizontal es diferente del precio de cierre de la vela anterior

  {

    cierre_H_1D.precio = vela_1D.close;



    if (cierre_H_1D.existe)

    {

      //Ya existe la linea, solo hay que actualizar el nivel del precio

      ActualizarLineaHorizontal(cierre_H_1D.nombre, vela_1D.close);

    }

    else

    {

      //Hay que pintar la linea pues no existe todava

      DibujarLineaHorizontal(cierre_H_1D.nombre, vela_1D.close, clrDarkKhaki, "NivelHorizonalCierre_1D");

    }

  }



  //CASE: NIVEL 1W

  if (cierre_H_1W.precio !=vela_1W.close) //Nivel horizontal es diferente del precio de cierre de la vela anterior

  {

    cierre_H_1W.precio = vela_1W.close;

    if (cierre_H_1W.existe)

    {

      //Ya existe la linea, solo hay que actualizar el nivel del precio

      ActualizarLineaHorizontal(cierre_H_1W.nombre, vela_1W.close);

    }

    else

    {

      //Hay que pintar la linea pues no existe todava

      DibujarLineaHorizontal(cierre_H_1W.nombre, vela_1W.close, clrDarkOrange, "NivelHorizonalCierre_1W");

    }

  }

}



// Dibujar lnea horizontal

bool DibujarLineaHorizontal(string nombre, double precio, color colorLinea, string descripcion)

{

   // Crear la lnea horizontal

   bool created = (ObjectCreate(0, nombre, OBJ_HLINE, 0, 0, precio));



   if(!created)

   {

      int error = GetLastError();  // 4200 = objeto ya existe

      Alert("Error al crear la lnea, cdigo: ", error);

      return false;

   }



    // Configurar propiedades de la lnea

    ObjectSetString(0, nombre, OBJPROP_TEXT, descripcion);



    ObjectSetInteger(0, nombre, OBJPROP_COLOR, colorLinea);

    ObjectSetInteger(0, nombre, OBJPROP_WIDTH, 1);

    ObjectSetInteger(0, nombre, OBJPROP_STYLE, STYLE_DASHDOT);

    ObjectSetInteger(0, nombre, OBJPROP_BACK, true);

    ObjectSetInteger(0, nombre, OBJPROP_SELECTABLE, true);

    ObjectSetInteger(0, nombre, OBJPROP_SELECTED, false);



    if (nombre == cierre_H_1D.nombre)

    {

      ObjectSetInteger(0, nombre, OBJPROP_TIMEFRAMES,

      OBJ_PERIOD_M1 | OBJ_PERIOD_M5 | OBJ_PERIOD_M15 |

      OBJ_PERIOD_M30 | OBJ_PERIOD_H1 | OBJ_PERIOD_D1);

    }

    else //nombre == cierre_H_1W.nombre

    {

      ObjectSetInteger(0, nombre, OBJPROP_TIMEFRAMES,

      OBJ_PERIOD_M1 | OBJ_PERIOD_M5 | OBJ_PERIOD_M15 |

      OBJ_PERIOD_M30 | OBJ_PERIOD_H1 | OBJ_PERIOD_H4 | OBJ_PERIOD_D1);

    }



    // Refrescar el grfico

    ChartRedraw(0);

    return true;

}



// Actualizar precio lnea horizontal                                        |

bool ActualizarLineaHorizontal(string nombre, double precio)

{

     for(int i = totalObjetos; i > 0 ; i--) //totalObjetos es global, ya se calculado en la primera llamada

   {

      string nombreObjeto = ObjectName(0, i);



      // Verificar si el nombre coincide

      if(nombreObjeto == nombre)

      {

        ObjectSetDouble(0, nombreObjeto, OBJPROP_PRICE, 0, precio);

        ChartRedraw(0);

        Print("Lnea actualizada: ", nombreObjeto, " en precio ", DoubleToString(precio, Digits()));

        return true;

      }

    }

    Alert("Error al actualizar la lnea horizontal");

    return false;

}
