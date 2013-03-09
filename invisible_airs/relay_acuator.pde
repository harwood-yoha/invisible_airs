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
 
  // inChar = 'p';
  //if(inChar == 'a') {
     digitalWrite(ledPin, HIGH);   // set the relay on
    // Serial.println("START pin 13");
     // Serial.print("char: "); 
     Serial.println( "high");
      //delay(1000);                  // wait for a second
      inChar = 'x';
      delay(1000);
    
  //}
  
  //else if (inChar == 'b') {
     digitalWrite(ledPin, LOW);    // set the relay off
     Serial.println("low");
     //Serial.print("char: "); 
   
     inChar = 'x';
   delay(1000);                  // wait for a second
 // inChar = 'p';
  //if(inChar == 'a') {
     digitalWrite(ledPin1, HIGH);   // set the relay on
    // Serial.println("START pin 13");
     // Serial.print("char: "); 
     Serial.println( "high");
      //delay(1000);                  // wait for a second
      inChar = 'x';
      delay(1000);
    
  //}
  
  //else if (inChar == 'b') {
     digitalWrite(ledPin1, LOW);    // set the relay off
     Serial.println("low");
     //Serial.print("char: "); 
   
     inChar = 'x';
   delay(1000);                  // wait for a second
  //delay(100);
}
