#include <avr/pgmspace.h>

#define DEBUG 1

// Defines
#define R 0
#define G 1
#define B 2
#define LED1 0
#define LED2 1
#define NUMLEDS 2
#define NUMPARAMS 5

// RGB pin numbers for both LEDs.
const int _pinIDs[NUMLEDS][3] = 
{
  // R, G, B
  {3, 9, 10},  // LED 1
  {5, 6, 11}   // LED 2
};

// NumLights, R, G, B, frequency, duration
#define DI 1
#define RI 2
#define GI 3
#define BI 4
#define FI 5
prog_uint32_t _data[] =
{
  1, 1000, 255, 255, 255, 2,
  0
};

typedef struct PATCH_INFO_STRUCT
{
  int numLEDs;
  float RGB[2][3];
  float frequency[2];
} PatchInfo;

// Globals
unsigned long _time0;
unsigned long _patchDuration = 0;
int _dataIndex = 0;
PatchInfo _patchInfo;

#if DEBUG
  char _debugString[32];
#endif

void setup()
{
  Serial.begin(9600);
  
#if DEBUG
  Serial.println("Setup Serial");
#endif
  
  // Setup the PWM pins for both LEDs.
  for (int ledID = 0; ledID < NUMLEDS; ledID++) {
    pinMode(_pinIDs[ledID][R], OUTPUT);
    pinMode(_pinIDs[ledID][G], OUTPUT);
    pinMode(_pinIDs[ledID][B], OUTPUT);
  }
  
  // Establish time 0.
  _time0 = millis();
}

void loop()
{
  unsigned long timeNow = millis();
  
  // If the current patch is done, move on to the next one.
  if ((timeNow - _time0) > _patchDuration) {
#if DEBUG
    Serial.println("New patch");
#endif

    // Get the number of LEDs that are specified for this patch.
    _patchInfo.numLEDs = (int)pgm_read_dword(&(_data[_dataIndex]));
    uint32_t l = pgm_read_dword(&(_data[_dataIndex]));
    
#if DEBUG
    sprintf(_debugString, "Num LEDs: %d", l);
    Serial.println(_debugString);
#endif
    
    
    // If we get a value of 0, then we've reached the end of the patch list.
    // This means we loop back to the beginning.
    if (_patchInfo.numLEDs == 0) {
      _dataIndex = 0;
      _patchInfo.numLEDs = (int)pgm_read_dword(&(_data[_dataIndex]));
    }
    
#if DEBUG
    sprintf(_debugString, "Data Index: %d", _dataIndex);
    Serial.println(_debugString);
#endif
    
    // Get the patch duration.
    _patchDuration = (unsigned long)pgm_read_dword(&(_data[_dataIndex+DI]));
    
    // Copy over all the patch specs for LED 1.
    _patchInfo.RGB[LED1][R] = (float)pgm_read_dword(&(_data[_dataIndex+RI])) / 255.0;
    _patchInfo.RGB[LED1][G] = (float)pgm_read_dword(&(_data[_dataIndex+GI])) / 255.0;
    _patchInfo.RGB[LED1][B] = (float)pgm_read_dword(&(_data[_dataIndex+BI])) / 255.0;
    _patchInfo.frequency[LED1] = (float)pgm_read_dword(&(_data[_dataIndex+FI]));
    
    // Increment the data index to point to either the next LED spec or
    // the next patch.
    _dataIndex = _dataIndex + NUMPARAMS + 1;
    
    // If 2 LED values are specified, pull the 2nd set of values out of the
    // patch data.  Otherewise, we'll just copy LED1's values into LED2.
    if (_patchInfo.numLEDs == 1) {
      _patchInfo.RGB[LED2][R] =_patchInfo.RGB[LED1][R];
      _patchInfo.RGB[LED2][G] =_patchInfo.RGB[LED1][G];
      _patchInfo.RGB[LED2][B] = _patchInfo.RGB[LED1][B];
      _patchInfo.frequency[LED2] = _patchInfo.frequency[LED1];
    }
    else {
      _patchInfo.RGB[LED2][R] = (float)pgm_read_dword(&(_data[_dataIndex+RI-2])) / 255.0;
      _patchInfo.RGB[LED2][G] = (float)pgm_read_dword(&(_data[_dataIndex+GI-2])) / 255.0;
      _patchInfo.RGB[LED2][B] = (float)pgm_read_dword(&(_data[_dataIndex+BI-2])) / 255.0;
      _patchInfo.frequency[LED2] = (float)pgm_read_dword(&(_data[_dataIndex+FI-2]));
      
      // Increment the data index to the next patch.
      _dataIndex = _dataIndex + NUMPARAMS - 1;
    }
    
    // Reset our timer base.
    _time0 = millis();
    timeNow = _time0;
  }
  /*
   // Calculate the current analog output values for the LED channels.
   int rgb[NUMLEDS][3];
   for (int i = 0; i < NUMLEDS; i++) {
     rgb[i][R] = sin2aout(_patchInfo.RGB[i][R], _patchInfo.frequency[i], 0, (float)(timeNow-_time0));
     rgb[i][G] = sin2aout(_patchInfo.RGB[i][G], _patchInfo.frequency[i], 0, (float)(timeNow-_time0));
     rgb[i][B] = sin2aout(_patchInfo.RGB[i][B], _patchInfo.frequency[i], 0, (float)(timeNow-_time0));
   }
   
   // Now set the PWM pins.
   for (int i = 0; i < NUMLEDS; i++) {
     analogWrite(_pinIDs[i][R], rgb[i][R]);
     analogWrite(_pinIDs[i][G], rgb[i][G]);
     analogWrite(_pinIDs[i][B], rgb[i][B]);
   }
   */
}

int sin2aout(float intensity, float frequency, float phaseOffset, float clockTime)
{
  double aOut = (sin(frequency*2.0*PI*clockTime/1000.0 + phaseOffset + PI) + 1.0) / 2.0;

  return round(aOut * intensity * 255);
}

