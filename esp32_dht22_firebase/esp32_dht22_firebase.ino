#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

// ==========================================
// 1. WIFI & FIREBASE CONFIGURATION (EDIT ME)
// ==========================================
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Example: "https://your-project-id-default-rtdb.firebaseio.com"
const char* FIREBASE_DB_URL = "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com";
// Optional: Database secret or auth token if RTDB rules require auth
const char* FIREBASE_AUTH   = "";

// ==========================================
// 2. DHT22 SENSOR PINS
// ==========================================
#define DHTPIN 4       // GPIO4 connected to DHT22 DATA pin
#define DHTTYPE DHT22  // DHT 22 (AM2302)
DHT dht(DHTPIN, DHTTYPE);

const unsigned long SEND_INTERVAL_MS = 5000;
unsigned long lastSend = 0;

void setup() {
  Serial.begin(115200);
  dht.begin();

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
}

void loop() {
  if (millis() - lastSend < SEND_INTERVAL_MS) return;
  lastSend = millis();

  float humidity = dht.readHumidity();
  float tempC    = dht.readTemperature();

  if (isnan(humidity) || isnan(tempC)) {
    Serial.println("Failed to read from DHT22 sensor!");
    return;
  }

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String url = String(FIREBASE_DB_URL) + "/sensors/warehouse_env.json";
    if (strlen(FIREBASE_AUTH) > 0) {
      url += "?auth=" + String(FIREBASE_AUTH);
    }

    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    String payload = "{";
    payload += "\"temperatureC\":" + String(tempC, 1) + ",";
    payload += "\"humidityPct\":" + String(humidity, 1) + ",";
    payload += "\"deviceId\":\"esp32-warehouse-01\",";
    payload += "\"updatedAt\":{\".sv\":\"timestamp\"}";
    payload += "}";

    int httpCode = http.PUT(payload);
    if (httpCode > 0) {
      Serial.printf("Firebase PUT [%d]: %s\n", httpCode, payload.c_str());
    } else {
      Serial.printf("Firebase PUT failed: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  }
}
