//+------------------------------------------------------------------+
//|                                          A_EntriesManagement.mqh |
//|                        Copyright 2021, Nkondog Anselme Venceslas |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Nkondog Anselme Venceslas"
#property link      "https://www.mql5.com"

//Evaluate if there is an entry signal
void EvaluateEntry()
  {
   SignalEntry=SIGNAL_ENTRY_NEUTRAL;
   if(!IsSpreadOK)
     {
      Print("At "+SymbolInfoInteger(Symb, SYMBOL_SPREAD)+" Spread is too high to open a position");
      return;    //If the spread is too high don't give an entry signal
     }
   if(UseTradingHours && !IsOperatingHours)
      return;      //If you are using trading hours and it's not a trading hour don't give an entry signal
if(!IsNewCandle) return;      //If you want to provide a signal only if it's a new candle opening
//if(IsTradedThisBar) return;   //If you don't want to execute multiple trades in the same bar
   /*if(!ShouldTrade())
     {
      Print("No additional trade is allowed on a profitable day");
      return;
     }*/
   if(TotalOpenOrders>0)
     {
      Print("Trade activity suspended! Opened position(s) found.");
      return; //If there are already open orders and you don't want to open more
     }
entryConditions();

//--- Trend detection
    bool upTrend   = IsUpTrend();
    bool downTrend = IsDownTrend();



//Entry Signal for BUY orders
   if(priceMomentum == UP && upTrend)
     {
      SignalEntry=SIGNAL_ENTRY_BUY;
      Print("Buy entry signal");
      priceMomentum = NEUTRAL;
     }

//Entry Signal for SELL orders
   if(priceMomentum == DOWN && downTrend)
     {
      SignalEntry=SIGNAL_ENTRY_SELL;
      Print("Sell entry signal");
      priceMomentum = NEUTRAL;
     }
   Print("Evaluating entry possibility, Out Signal entry "+SignalEntry);
  }

//========================= TREND DETECTION =========================
bool IsUpTrend()
{
    double ema50  = iMA(Symb, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 1);
    double ema200 = iMA(Symb, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE, 1);
    return ema50 > ema200;
}

bool IsDownTrend()
{
    double ema50  = iMA(Symb, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 1);
    double ema200 = iMA(Symb, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE, 1);
    return ema50 < ema200;
}
//========================= EXECUTE ENTRY ==========================

//Execute entry if there is an entry signal
void ExecuteEntry()
  {
//If there is no entry signal no point to continue, exit the function
   if(SignalEntry==SIGNAL_ENTRY_NEUTRAL)
      return;
   int Operation;
   double OpenPrice=0;
   double StopLossPrice=0;
   double TakeProfitPrice=0;
//If there is a Buy entry signal
   if(SignalEntry==SIGNAL_ENTRY_BUY)
     {
      Print("In buy execution");
      Operation=ORDER_TYPE_BUY; //Set the operation to BUY
      OpenPrice=last_tick.ask;    //Set the open price to Ask price
      //If the Stop Loss is fixed and the default stop loss is set
      if(StopLossMode==SL_FIXED && DefaultStopLoss>0)
        {
         StopLossPrice=OpenPrice-DefaultStopLoss*_Point;
        }
      //If the Stop Loss is automatic
      if(StopLossMode==SL_AUTO)
        {
         //Set the Stop Loss to the custom stop loss price
         //StopLossPrice=last_tick.ask-((last_tick.ask-sell_level));
         //StopLossPrice=iLow(Symb, PERIOD_CURRENT, 3);
         double prevLow = iLow(Symb, PERIOD_CURRENT, 1);
         StopLossPrice = prevLow;
        }
      //If the Take Profix price is fixed and defined
      if(TakeProfitMode==TP_FIXED && DefaultTakeProfit>0)
        {
         TakeProfitPrice=OpenPrice+DefaultTakeProfit*_Point;
        }
      //If the Take Profit is automatic
      if(TakeProfitMode==TP_AUTO)
        {
         //Set the Take Profit to the custom take profit price
         TakeProfitPrice=OpenPrice+((OpenPrice-StopLossPrice)*TakeProfitPercent);
         if(ProfitRun)
           {
            TakeProfitPrice=OpenPrice+((OpenPrice-StopLossPrice)*ProfitRunTargetPercent);
           }
        }
      //Normalize the digits for the float numbers
      OpenPrice=NormalizeDouble(OpenPrice,Digits());
      StopLossPrice=NormalizeDouble(StopLossPrice,Digits());
      TakeProfitPrice=NormalizeDouble(TakeProfitPrice,Digits());
      //Submit the order
      SendOrder(Operation,Symbol(),OpenPrice,StopLossPrice,TakeProfitPrice);
     }


   if(SignalEntry==SIGNAL_ENTRY_SELL)
     {
      Operation=ORDER_TYPE_SELL; //Set the operation to SELL
      OpenPrice=last_tick.bid;    //Set the open price to Ask price
      //If the Stop Loss is fixed and the default stop loss is set
      if(StopLossMode==SL_FIXED && DefaultStopLoss>0)
        {
         StopLossPrice=OpenPrice+DefaultStopLoss*_Point;
        }
      //If the Stop Loss is automatic
      if(StopLossMode==SL_AUTO)
        {
         double prevHigh = iHigh(Symb, PERIOD_CURRENT, 1);
         StopLossPrice = prevHigh;
         // StopLossPrice=iHigh(Symb, PERIOD_CURRENT, 3);
        }
      //If the Take Profix price is fixed and defined
      if(TakeProfitMode==TP_FIXED && DefaultTakeProfit>0)
        {
         TakeProfitPrice=OpenPrice-DefaultTakeProfit*_Point;
        }
      //If the Take Profit is automatic
      if(TakeProfitMode==TP_AUTO)
        {
         //Set the Take Profit to the custom take profit price
         TakeProfitPrice=OpenPrice-((StopLossPrice-OpenPrice)*TakeProfitPercent);
         if(ProfitRun)
           {
            TakeProfitPrice=OpenPrice-((StopLossPrice-OpenPrice)*ProfitRunTargetPercent);
           }
        }
      //Normalize the digits for the float numbers
     NormalizePrices(OpenPrice, StopLossPrice, TakeProfitPrice);
      //Submit the order
      SendOrder(Operation,Symbol(),OpenPrice,StopLossPrice,TakeProfitPrice);
     }

  }

//========================= NORMALIZE PRICES ========================
void NormalizePrices(double &Open, double &SL, double &TP)
{
    Open = NormalizeDouble(Open, Digits());
    SL   = NormalizeDouble(SL, Digits());
    TP   = NormalizeDouble(TP, Digits());
}


//Send Order Function adjusted to handle errors and retry multiple times
void SendOrder(int Command, string Instrument, double OpenPrice, double SLPrice, double TPPrice, datetime Expiration=0)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

//Retry a number of times in case the submission fails
   for(int i=1; i<=OrderOpRetry; i++)
     {
      //Set the color for the open arrow for the order
      /*color OpenColor=clrBlueViolet;
      if(Command==OP_BUY)
        {
         OpenColor=clrChartreuse;
        }
      if(Command==OP_SELL)
        {
         OpenColor=clrDarkTurquoise;
        }*/
      //Calculate the position size, if the lot size is zero then exit the function
      double SLPoints=0;
      Print("Stop loss ", SLPrice, " Open price ", OpenPrice);
      //If the Stop Loss price is set then find the points of distance between open price and stop loss price, and round it
      if(SLPrice>0)
         SLPoints=MathCeil(MathAbs(OpenPrice-SLPrice)/_Point);
      //Call the function to calculate the position size
      CheckHistory();
      Print("Stop loss en point ", SLPoints, " Point ", _Point);
      LotSizeCalculate(SLPoints);
      //If the position size is zero then exit and don't submit any orderInit

      Print("Stop loss en point ", SLPoints);
      if(LotSize==0)
         return;

      request.action       =TRADE_ACTION_DEAL;                     // type de l'opération de trading
      request.symbol       =Instrument;                              // symbole
      request.volume       =LotSize;                                   // volume de 0.1 lot
      request.type         =Command;                        // type de l'ordre
      request.price        =SYMBOL_TRADE_EXECUTION_MARKET; // prix d'ouverture
      request.sl           =SLPrice;
      request.tp           =TPPrice;
      request.type_filling =ORDER_FILLING_FOK;
      request.deviation    =Slippage;
      request.expiration   =Expiration;                             // déviation du prix autorisée
      //Submit the order

      if(!OrderSend(request,result))
         PrintFormat("OrderSend erreur %d",GetLastError());     // en cas d'erreur d'envoi de la demande, affiche le code d'erreur
      //--- informations de l'opération
      PrintFormat("retcode=%u  transaction=%I64u  ordre=%I64u",result.retcode,result.deal,result.order);

      if(result.retcode == TRADE_RETCODE_DONE && result.deal != 0)
         break;
     }
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void entryConditions()
  {
   double lastCandleOpen, lastCandleClose, firstCandleOpen, firstCandleClose;
   int candles = NumberOfCandles + 1;
   priceMomentum = NEUTRAL;

   for(int i=0; i<candles; i++)
     {
      Print(" Candle number "+i);
      if(i == 1)
        {
         lastCandleClose = iClose(Symb, PERIOD_CURRENT, i);
         lastCandleOpen = iOpen(Symb, PERIOD_CURRENT, i);
         Print("Number ", i, " Last close ", iClose(Symb, PERIOD_CURRENT, i));
        }
      if(i == NumberOfCandles)
        {
         firstCandleOpen = iOpen(Symb, PERIOD_CURRENT, i);
         Print("Number ", NumberOfCandles, " First close ", iClose(Symb, PERIOD_CURRENT, i));
         firstCandleClose = iClose(Symb, PERIOD_CURRENT, i);
        }
     }

   if(firstCandleOpen > firstCandleClose)
     {
      candleType = BEARISH_CANDLE;
     }
   if(firstCandleOpen < firstCandleClose)
     {
      candleType = BULLISH_CANDLE;
     }

   if(candleType == BEARISH_CANDLE && lastCandleClose < firstCandleClose && lastCandleClose < lastCandleOpen)
     {
      priceMomentum=DOWN;
     }
   if(candleType == BULLISH_CANDLE && lastCandleClose > firstCandleClose && lastCandleClose > lastCandleOpen)
     {
      priceMomentum=UP;
     }
  }

//========================= TRAILING STOP & BREAK-EVEN ==============
void ManageOpenTrades()
{
    for(int i=PositionsTotal()-1; i>=0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket)) continue;

        double openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentBid  = SymbolInfoDouble(Symb, SYMBOL_BID);
        double currentAsk  = SymbolInfoDouble(Symb, SYMBOL_ASK);
        double sl          = PositionGetDouble(POSITION_SL);

        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        //--- Break-Even
        double profitPoints = (type==POSITION_TYPE_BUY) ? currentBid-openPrice : openPrice-currentAsk;
        if(profitPoints >= BreakEvenTrigger && sl!=openPrice)
        {
            double newSL = (type==POSITION_TYPE_BUY) ? openPrice + _Point*2 : openPrice - _Point;
             newSL = NormalizeDouble(newSL, Digits());
            //PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
            
            if(PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP))) 
               Print("Break-Even set for ticket ", ticket);
            else
               Print("Failed to modify SL for ticket ", ticket, " Error: ", GetLastError());

        }

        //--- Trailing Stop
        if(TrailingStop>0)
        {
            double distance;
            if(type==POSITION_TYPE_BUY)
            {
                distance = currentBid - sl;
                if(distance > TrailingStop*_Point)
                {
                    double newSL = currentBid - TrailingStop*_Point;
                    newSL = NormalizeDouble(newSL, Digits());   // <<< normalize here
                    if(newSL>sl)
                        PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
                }

            }
            else
            {
                distance = sl - currentAsk;
                if(distance > TrailingStop*_Point)
                {
                    double newSL = currentAsk + TrailingStop*_Point;
                    newSL = NormalizeDouble(newSL, Digits());   // <<< normalize here
                    if(newSL < sl)
                {
                     bool modified = PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
                      if(modified) Print("Trailing SL modified for ticket ", ticket);
                   else Print("Failed to modify trailing SL for ticket ", ticket, " Error: ", GetLastError());
                  }

                }
            }
        }
    }
}

//========================= SAFE LOT CALCULATION ===================
void LotSizeCalculate(double SLPoints)
{
    if(SLPoints<=0) { LotSize=0; return; }

    double accountRisk = AccountRiskPercent/100.0;
    double balance     = AccountInfoDouble(ACCOUNT_BALANCE);
    double tickValue   = SymbolInfoDouble(Symb, SYMBOL_TRADE_TICK_VALUE);
    double lotStep     = SymbolInfoDouble(Symb, SYMBOL_VOLUME_STEP);
    double maxLot      = SymbolInfoDouble(Symb, SYMBOL_VOLUME_MAX);

    double riskAmount  = balance * accountRisk;
  // LotSize = NormalizeDouble(MathMin(riskAmount / (SLPoints*tickValue), maxLot), 2);
    LotSize = MathMin(riskAmount / (SLPoints*tickValue), maxLot);
    if(LotSize < lotStep) LotSize = 0;



    
}


//+------------------------------------------------------------------+
new files 

// -------------------- GLOBALS --------------------
static int zzHandleHTF = -1;
static int zzHandleLTF = -1;
static double lastHTFSwingHigh = 0;
static double lastHTFSwingLow  = 0;
static double lastLTFEntrySwingHigh = 0;
static double lastLTFEntrySwingLow  = 0;

// ATR settings
input int ATRPeriod = 14;
input double ATRMultiplierEntry = 0.5;
input double ATRMultiplierSL    = 1.0;
input double ATRMultiplierTP    = 1.5;
input double ATRMultiplierTrail = 0.5;
input double ATRMultiplierBE    = 0.2;

// ------------------- UPDATE SWINGS -------------------
void UpdateHTFSwings()
{
    ENUM_TIMEFRAMES HTF = PERIOD_M15;
    if(zzHandleHTF == -1)
        zzHandleHTF = iCustom(Symb, HTF, "Examples\\ZigZag", Depth, Deviation, Backstep);
    if(zzHandleHTF == INVALID_HANDLE) return;
    double buffer[];
    ArraySetAsSeries(buffer,true);
    int copied = CopyBuffer(zzHandleHTF,0,0,50,buffer); // only last 50 bars needed
    if(copied <= 0) return;
    double swingHigh=0, swingLow=0;
    for(int i=0;i<copied;i++)
    {
        if(buffer[i]==EMPTY_VALUE) continue;
        if(buffer[i] > swingHigh) swingHigh = buffer[i];
        if(buffer[i] < swingLow || swingLow==0) swingLow = buffer[i];
    }
    lastHTFSwingHigh = swingHigh;
    lastHTFSwingLow  = swingLow;
}

void UpdateLTFEntrySwings()
{
    ENUM_TIMEFRAMES LTF = PERIOD_M1;
    if(zzHandleLTF == -1)
        zzHandleLTF = iCustom(Symb, LTF, "Examples\\ZigZag", Depth, Deviation, Backstep);
    if(zzHandleLTF == INVALID_HANDLE) return;
    double buffer[];
    ArraySetAsSeries(buffer,true);
    int copied = CopyBuffer(zzHandleLTF,0,0,50,buffer); // only last 50 bars needed
    if(copied <= 0) return;
    double swingHigh=0, swingLow=0;
    for(int i=0;i<copied;i++)
    {
        if(buffer[i]==EMPTY_VALUE) continue;
        if(buffer[i] > swingHigh) swingHigh = buffer[i];
        if(buffer[i] < swingLow || swingLow==0) swingLow = buffer[i];
    }
    lastLTFEntrySwingHigh = swingHigh;
    lastLTFEntrySwingLow  = swingLow;
}

// ------------------- GET ATR -------------------
double GetATR(int period, ENUM_TIMEFRAMES tf)
{
    double atrArray[];
    if(CopyATR(Symbol(), tf, period, 1, atrArray) <= 0) return 0;
    return atrArray[0];
}

// ------------------- EXECUTE ENTRY WITH PENDING CANCEL & AUTO-CLOSE -------------------
void ExecuteEntry()
{
    if(SignalEntry == SIGNAL_ENTRY_NEUTRAL) return;

    // ------------------- Update LTF swings -------------------
    UpdateLTFEntrySwings();

    double atr = GetATR(ATRPeriod, PERIOD_M1);
    if(atr == 0) atr = _Point*10; // fallback

    // ------------------- Cancel or close existing pending orders for this symbol -------------------
    for(int i=OrdersTotal()-1; i>=0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;

        if(OrderSymbol() == Symbol())
        {
            int type = OrderType();
            if(type == OP_BUYLIMIT || type == OP_BUYSTOP)
            {
                double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
                if(OrderOpenPrice() < bid)
                    OrderDelete(OrderTicket());
            }
            else if(type == OP_SELLLIMIT || type == OP_SELLSTOP)
            {
                double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                if(OrderOpenPrice() > ask)
                    OrderDelete(OrderTicket());
            }
        }
    }

    // ------------------- Determine entry price, SL, TP -------------------
    double OpenPrice  = 0;
    double StopLoss   = 0;
    double TakeProfit = 0;

    if(SignalEntry == SIGNAL_ENTRY_BUY)
    {
        OpenPrice  = lastLTFEntrySwingLow + atr*ATRMultiplierEntry;
        StopLoss   = lastLTFEntrySwingLow - atr*ATRMultiplierSL;
        TakeProfit = lastHTFSwingHigh + atr*ATRMultiplierTP;
    }
    else if(SignalEntry == SIGNAL_ENTRY_SELL)
    {
        OpenPrice  = lastLTFEntrySwingHigh - atr*ATRMultiplierEntry;
        StopLoss   = lastLTFEntrySwingHigh + atr*ATRMultiplierSL;
        TakeProfit = lastHTFSwingLow - atr*ATRMultiplierTP;
    }

    NormalizePrices(OpenPrice, StopLoss, TakeProfit);

    // ------------------- Place pending or market order -------------------
    if(PendingEnabled)
    {
        ENUM_ORDER_TYPE orderType = (SignalEntry==SIGNAL_ENTRY_BUY)? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
        SendOrder(orderType, Symbol(), OpenPrice, StopLoss, TakeProfit);
    }
    else
    {
        ENUM_ORDER_TYPE orderType = (SignalEntry==SIGNAL_ENTRY_BUY)? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        SendOrder(orderType, Symbol(), OpenPrice, StopLoss, TakeProfit);
    }

    // Reset signal
    SignalEntry = SIGNAL_ENTRY_NEUTRAL;
}

// ------------------- MANAGE OPEN TRADES OPTIMIZED -------------------
void ManageOpenTrades()
{
    UpdateHTFSwings();  // TP1 trail
    UpdateLTFEntrySwings(); // SL and TP2 trail

    double atr = GetATR(ATRPeriod, PERIOD_M1);
    if(atr == 0) atr = _Point*10; // fallback

    double minTrailDistance = atr*ATRMultiplierTrail;
    double TP2Activate      = atr*ATRMultiplierTP;
    double BETriggerAdjusted = atr*ATRMultiplierTP + atr*ATRMultiplierTrail;
    double BreakEvenBuffer   = atr*ATRMultiplierBE;

    for(int pos=PositionsTotal()-1; pos>=0; pos--)
    {
        if(!PositionSelect(Symbol())) continue;

        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl        = PositionGetDouble(POSITION_SL);
        double tp        = PositionGetDouble(POSITION_TP);
        double currentBid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
        double currentAsk = SymbolInfoDouble(Symbol(),SYMBOL_ASK);

        double profitPoints = (type==POSITION_TYPE_BUY) ? currentBid - openPrice : openPrice - currentAsk;

        // ---------------- Stage 1: Break-even with buffer ----------------
        if(!TradeBEActivated[0] && profitPoints >= BETriggerAdjusted)
        {
            double newSL = (type==POSITION_TYPE_BUY) ? openPrice + BreakEvenBuffer
                                                     : openPrice - BreakEvenBuffer;
            newSL = NormalizeDouble(newSL, Digits());
            if(newSL != sl && PositionModify(Symbol(), newSL, tp))
                TradeBEActivated[0] = true;
        }

        // ---------------- Stage 2: Trailing SL ----------------
        if(TradeBEActivated[0])
        {
            double trailSL;
            if(type==POSITION_TYPE_BUY)
                trailSL = MathMax(sl, MathMax(lastLTFEntrySwingLow, openPrice + minTrailDistance));
            else
                trailSL = MathMin(sl, MathMin(lastLTFEntrySwingHigh, openPrice - minTrailDistance));

            trailSL = NormalizeDouble(trailSL, Digits());

            if((type==POSITION_TYPE_BUY && trailSL>sl) || (type==POSITION_TYPE_SELL && trailSL<sl))
                PositionModify(Symbol(), trailSL, tp);
        }

        // ---------------- Stage 3: TP trailing ----------------
        double newTP = tp;
        if(type==POSITION_TYPE_BUY)
        {
            double tp1 = lastHTFSwingHigh;
            double tp2 = lastLTFEntrySwingHigh;
            if(profitPoints >= TP2Activate)
                newTP = MathMax(tp, MathMax(tp1, tp2));
            else
                newTP = MathMax(tp, tp1);
        }
        else
        {
            double tp1 = lastHTFSwingLow;
            double tp2 = lastLTFEntrySwingLow;
            if(profitPoints >= TP2Activate)
                newTP = MathMin(tp, MathMin(tp1, tp2));
            else
                newTP = MathMin(tp, tp1);
        }

        newTP = NormalizeDouble(newTP, Digits());
        if(newTP != tp)
            PositionModify(Symbol(), sl, newTP);
    }
}

//========================= NORMALIZE PRICES ========================
void NormalizePrices(double &Open, double &SL, double &TP)
{
    Open = NormalizeDouble(Open, Digits());
    SL   = NormalizeDouble(SL, Digits());
    TP   = NormalizeDouble(TP, Digits());
}


//Send Order Function adjusted to handle errors and retry multiple times
void SendOrder(int Command, string Instrument, double OpenPrice, double SLPrice, double TPPrice, datetime Expiration=0)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

//Retry a number of times in case the submission fails
   for(int i=1; i<=OrderOpRetry; i++)
     {
      double SLPoints=0;
      Print("Stop loss ", SLPrice, " Open price ", OpenPrice);
      if(SLPrice>0)
         SLPoints=MathCeil(MathAbs(OpenPrice-SLPrice)/_Point);
      CheckHistory();
      Print("Stop loss en point ", SLPoints, " Point ", _Point);
      LotSizeCalculate(SLPoints);
      if(LotSize==0)
         return;

      request.action       =TRADE_ACTION_DEAL;
      request.symbol       =Instrument;
      request.volume       =LotSize;
      request.type         =Command;
      request.price        =SYMBOL_TRADE_EXECUTION_MARKET;
      request.sl           =SLPrice;
      request.tp           =TPPrice;
      request.type_filling =ORDER_FILLING_FOK;
      request.deviation    =Slippage;
      request.expiration   =Expiration;

      if(!OrderSend(request,result))
         PrintFormat("OrderSend erreur %d",GetLastError());
      PrintFormat("retcode=%u  transaction=%I64u  ordre=%I64u",result.retcode,result.deal,result.order);

      if(result.retcode == TRADE_RETCODE_DONE && result.deal != 0)
         break;
     }
   return;
  } 
