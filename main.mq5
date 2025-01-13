//+------------------------------------------------------------------+
//|                                                  PriceAction.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade ;


//pip 1500 jpyusd ,  4500 gold

// Define input parameters
input int Pip = 100 ;  // Pip points
input int FastMAPeriod = 20;        // Fast MA Period
input int SlowMAPeriod = 50;        // Slow MA Period
input ENUM_MA_METHOD MAMethod = MODE_SMA; // Moving Average method
input ENUM_APPLIED_PRICE PriceType = PRICE_CLOSE; // Price type for MA calculation
input int PriceActionPeriod = 30 ; // Price Action Period
input ENUM_TIMEFRAMES TimeFrame = PERIOD_H1;

input double LotSize = 0.1;        // Lot size for trades

// Global variables
int fastMAHandle, slowMAHandle;     // Handles for moving averages




//+------------------------------------------------------------------+
//|       Essential funnc                                            |
//+------------------------------------------------------------------+






















// Function to generate a random number between 0 and 1
double getRandomNumber(int maxNumber)
  {
   int randomValue = MathRand(); // Generate a random integer value
   double result = NormalizeDouble(randomValue / 32767.0*maxNumber , 6); // Convert to a floating-point number between 0 and 1
   return result;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int positionTotalSymbol(string symbol)
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {

      if(PositionGetSymbol(i) == symbol)
        {
         count += 1;
        }
     }

   return count ;
  }





double GetHighestPrice(string symbol ,  int candleCount)
{
    double highestPrice = -1; // Initialize to an invalid low value

    // Loop through the last 'candleCount' candles
    for (int i = 0; i <= candleCount; i++)
    {
        // Get the high of the current candle (i)
        double currentHigh = iHigh(symbol, 0, i);
        
      
        
        // Check if it's the highest so far
        if (currentHigh > highestPrice)
        {
            highestPrice = currentHigh;
        }
    }

    return highestPrice;
}



double GetLowestPrice(string symbol, int candleCount)
{
    double lowestPrice = -1; // Initialize to an invalid high value

    // Loop through the last 'candleCount' candles
    for (int i = 0; i <= candleCount; i++)
    {
        // Get the low of the current candle (i)
        double currentLow = iLow(symbol, 0, i);

        // Check if it's the lowest so far
        if (lowestPrice == -1 || currentLow < lowestPrice)
        {
            lowestPrice = currentLow;
        }
    }

    return lowestPrice;
}




void createOrder(string symbol ,ENUM_ORDER_TYPE orderType )
  {


   int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   double ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK),digits) ;

   double bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), digits) ;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);



   



// Execute trading orders based on signals
if( positionTotalSymbol(symbol) == 0){
// 468
double gap_sl = Pip  * point ; 
double gap_tp = Pip  * point  ; 
 if(orderType == ORDER_TYPE_BUY )
     {

      double sl =  ask - gap_sl;
      double tp = ask +gap_tp ;
      trade.Buy(LotSize, symbol, ask,sl, tp,NULL);

     }
   else
      if(orderType == ORDER_TYPE_SELL)
        {

         double sl = bid +gap_sl ;
         double tp = bid -gap_tp ;

         trade.Sell(LotSize, symbol, bid, sl, tp,NULL);

        }

}
}












// Define OnInit function
int OnInit()
  {

 // Create Fast and Slow MA indicator handles
   fastMAHandle = iMA(Symbol(), TimeFrame, FastMAPeriod, 0, MAMethod, PriceType);
   slowMAHandle = iMA(Symbol(), TimeFrame, SlowMAPeriod, 0, MAMethod, PriceType);

   if (fastMAHandle == INVALID_HANDLE || slowMAHandle == INVALID_HANDLE)
   {
      Print("Failed to create MA indicator handles! Error: ", GetLastError());
      return INIT_FAILED;
   }

   Print("Moving Average indicators initialized.");
   return INIT_SUCCEEDED;
   
   
  }



double signalBuy1 = NULL;
double signalBuy0 = NULL;
double pullbackBuy = NULL;

double signalSell1 = NULL;
double signalSell0 = NULL;
double pullbackSell = NULL;

void OnTick()
{

 
    
    
    string symbol = Symbol();
    

     
    double fastMA[1], slowMA[1];

   // Copy the last two values for both MAs
   if (CopyBuffer(fastMAHandle, 0, 0, 1, fastMA) <= 0 || CopyBuffer(slowMAHandle, 0, 0, 1, slowMA) <= 0)
   {
      Print("Failed to copy MA values! Error: ", GetLastError());
      return;
   }

   // Check if MAs have changed since the last tick
   
   
  

    
   // Fetch the High and Low of the relevant bars using iHigh and iLow functions
    double highCurrent = iHigh(symbol, TimeFrame, 0);  // High of the last fully closed bar
    double  highPrev = iHigh(symbol, TimeFrame, 1);
    double lowCurrent = iLow(symbol, TimeFrame , 0);
     double lowPrev = iLow(symbol, TimeFrame , 1);
    
     
    
    
      // Detect crossover and execute trades
      if (fastMA[0] > slowMA[0] && fastMA[0] <  highCurrent) // Fast MA crosses above Slow MA
      {
      
      if(!signalBuy0) signalBuy0 = GetHighestPrice(symbol , PriceActionPeriod);
      
      if(signalBuy0 && highCurrent > signalBuy0){
       signalBuy0 = highCurrent;
       signalBuy1 = NULL;
       pullbackBuy = NULL;
      }
      
       if (highCurrent < signalBuy0 && highCurrent > highPrev && !pullbackBuy) {
       signalBuy1 = highCurrent; 
        Print("signal 1 buy detected." );
       }// signal1
       
       if(signalBuy0 && signalBuy1 && lowCurrent < lowPrev && signalBuy1 != highCurrent  ){
       pullbackBuy = lowCurrent;
       Print("Pullback buy");
       }
       
       if(signalBuy0 && signalBuy1 && pullbackBuy && highCurrent > highPrev && pullbackBuy != lowCurrent ){
       Print("Signal 2 buy detected");
       signalBuy0 = NULL;
       signalBuy1 = NULL;
       pullbackBuy = NULL;
       createOrder(symbol, ORDER_TYPE_BUY);
       
       }
       
       
       //sell 
        signalSell0 = NULL;
signalSell1 = NULL;
pullbackSell = NULL;



         
        
      
      }
      
      else if (fastMA[0] < slowMA[0] && fastMA[0] >  lowCurrent) // Fast MA crosses below Slow MA
      {
     signalBuy0 = NULL;
       signalBuy1 = NULL;
       pullbackBuy = NULL;
       
       
       //sell
      if(!signalSell0) signalSell0 = GetLowestPrice(symbol , PriceActionPeriod);
      
      if(signalSell0 && lowCurrent < signalSell0){
       signalSell0 = lowCurrent;
       signalSell1 = NULL;
       pullbackSell = NULL;
      }
      
       if ( lowCurrent > signalSell0 && lowCurrent < lowPrev && !pullbackSell ) {
       signalSell1 = lowCurrent; 
        Print("signal 1 sell detected." );
       }// signal1
       
       if(signalSell0 && signalSell1 && highCurrent > highPrev && signalSell1 != lowCurrent  ){
       pullbackSell = highCurrent;
       Print("Pullback sell");
       }
       
       if(signalSell0 && signalSell1 && pullbackSell && lowCurrent < lowPrev && pullbackSell != highCurrent ){
       Print("Signal 2 sell detected");
       signalSell0 = NULL;
       signalSell1 = NULL;
       pullbackSell = NULL;
      createOrder(symbol, ORDER_TYPE_SELL);
       
       }
       
       
       
        
         
       
      }
      else{
         signalBuy0 = NULL;
       signalBuy1 = NULL;
       pullbackBuy = NULL;
       
              signalSell0 = NULL;
signalSell1 = NULL;
pullbackSell = NULL;
      
      }
   
   
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+



void OnDeinit(const int reason)
{
   // Release the MA indicator handles
   if (fastMAHandle != INVALID_HANDLE)
      IndicatorRelease(fastMAHandle);
   if (slowMAHandle != INVALID_HANDLE)
      IndicatorRelease(slowMAHandle);

   Print("Moving Average indicators released.");
}