int ledPin =  13;    // LED connected to digital pin 13
int ledPin1 =  12;    // LED connected to digital pin 13
int inByte = 0;         // incoming serial byte
char inChar = 'x';
int pressureVal;

int sensorPin = 0; 

void setup() {
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT); 
  pinMode(ledPin1, OUTPUT); 
}
 
int quiet_count = 0;

void loop()
{
  inChar = Serial.read();
 
  //inChar = 'p';
  if(inChar == 'a') {
     digitalWrite(ledPin, HIGH);   // set the relay on
    // Serial.println("START pin 13");
     // Serial.print("char: "); 
     //Serial.println( -1);
      //delay(1000);                  // wait for a second
      inChar = 'x';
      
    
  }
  else if (inChar == 'b') {
     digitalWrite(ledPin, LOW);    // set the relay off
     //Serial.println("STOP pin 13");
     //Serial.print("char: "); 
   
     inChar = 'x';
   //delay(1000);                  // wait for a second
  }
  if(inChar == 'c') {
     digitalWrite(ledPin1, HIGH);   // set the relay on
    // Serial.println("START pin 12");
     // Serial.print("char: "); 
     //Serial.println( -1);
      //delay(1000);                  // wait for a second
      inChar = 'x';
      
    
  }
  else if (inChar == 'd') {
     digitalWrite(ledPin1, LOW);    // set the relay off
     //Serial.println("STOP pin 12");
     //Serial.print("char: "); 
   
     inChar = 'x';
   //delay(1000);                  // wait for a second
  }
  else if (inChar == 'p'){ 
     pressureVal = analogRead(sensorPin);   // read the analog input into a variable:
     pressureVal = map (pressureVal, 180, 350, 0, 100); // uncomment to change resolution of values returned to arduino, you may need to tweak this
     // Serial.println( -2);
     Serial.println(pressureVal);  // print the result:	
     //delay (50);
  //  Serial.println("x");
  }
  // otherwise echo anything else sent to us
 // while(Serial.available()) {
  //  inByte = Serial.read();
  //  Serial.print(inByte);
 // }
  //:w
  //delay(100);
}
