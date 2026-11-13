# GOLD TERMINAL AI

Analizador local de GOLD.pro mediante MetaTrader 5 de OANDA TMS. El análisis nunca envía órdenes automáticamente; la interfaz incluye controles manuales protegidos para una cuenta DEMO cuando se habilitan explícitamente.

## Estado actual

La aplicación se centra exclusivamente en GOLD.pro (oro frente al dólar) de OANDA TMS. Conecta con el terminal MT5 ya autenticado, recupera tick y velas, separa la vela en formación, calcula indicadores y patrones, integra contexto macroeconómico oficial, titulares macro y geopolíticos por RSS, y genera una decisión auditable para el dashboard.

El dashboard es un único programa de uso diario: Iniciar análisis activa el modo en tiempo real, actualiza bid/ask/spread cada segundo y renueva el análisis técnico, macroeconómico, noticioso y geopolítico cada 30 segundos. Detener análisis pausa ambos ciclos sin cerrar la aplicación. Los indicadores del gráfico se pueden activar y desactivar sin perder el zoom.

Las fuentes macro oficiales activas incluyen BLS para CPI, desempleo y NFP, U.S. Treasury para rendimientos de 2 y 10 años mediante su XML oficial, CFTC para open interest y posición Managed Money de futuros de oro, y Federal Reserve para noticias y calendario FOMC. El calendario se conserva como dato de contexto: sus eventos no son ticks ni sustituyen el precio de MT5.

FRED añade dólar amplio, WTI y PCE cuando se configura `FRED_API_KEY`. Sin esa clave, esas tres series aparecen como pendientes y el motor mantiene una postura conservadora. El panel de la aplicación muestra el estado de cada fuente, su coste, el motivo de la clave y el enlace de documentación. Se conserva el aviso de atribución: “This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis.”

La macro y el calendario se cachean durante cinco minutos porque son publicaciones diarias o semanales; el precio y el spread siguen llegando desde MT5 en tiempo real y el análisis técnico se renueva cada 30 segundos. Así se evita sobrecargar fuentes oficiales sin perder actualidad operativa.

La recomendación combina el marco técnico elegido, MN1/W1/D1/H4/H1/M15/M5, macroeconomía, titulares geopolíticos y calidad de datos. Los datos opcionales pendientes se muestran como advertencias; el motor puede clasificar COMPRAR o VENDER cuando el precio y la confluencia técnica estén disponibles. El gráfico incluye EMA20/50/200, Bollinger, VWAP, Supertrend, Fibonacci y FVG, todos con controles independientes, además de soportes, resistencias y apertura semanal; el panel también muestra escenarios con referencia, stop y objetivo orientativos.

La calculadora de margen usa el precio y tamaño de contrato de MT5 para estimar el capital requerido según lotaje y apalancamiento. El panel inferior muestra los horarios regulares de Sídney, Tokio, Londres y Nueva York, y una estimación de presión compradora/vendedora basada en la dirección y el tick volume de las últimas velas M5. Esta presión es una aproximación porque MT5 no publica un porcentaje agregado de compradores y vendedores.

La cuenta y los movimientos recientes se leen desde MT5. Las casillas Comprar/Vender solo permiten una dirección a la vez y exigen volumen, confirmación manual y validación previa de MT5. Por seguridad, `MT5_TRADING_ENABLED=false` y `MT5_ALLOW_REAL_TRADING=false` son los valores predeterminados. La cuenta conectada debe ser DEMO; no se habilita operativa real desde esta aplicación por defecto.

## Requisitos

- Windows 10/11.
- Python 3.12 de 64 bits.
- MetaTrader 5 de OANDA TMS instalado, abierto y autenticado en el servidor `OANDATMS-MT5`.
- Node.js y pnpm para el frontend.

## Instalación

Desde esta carpeta:

```powershell
& "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe" -m venv .venv
& ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
& ".\.venv\Scripts\python.exe" -m pip install -r backend\requirements.txt
Copy-Item .env.example .env
```

La aplicación abre directamente el panel y utiliza la sesión que ya esté abierta en el terminal de MetaTrader 5. MT5 debe estar instalado, iniciado y conectado antes de abrir GOLD TERMINAL AI. FRED se configura mediante `FRED_API_KEY` en `.env` si quieres activar esas series macroeconómicas.

También puedes completar `.env` manualmente, pero no compartas ese archivo: contiene credenciales sensibles.

### Claves y configuración opcional

- `FRED_API_KEY`: clave gratuita asociada a una cuenta gratuita de FRED. Activa dólar amplio, WTI y PCE. Se solicita desde la documentación oficial de claves de FRED.
- `ECONOMIC_CALENDAR_URL`: no es una API key. Es una URL opcional de un proveedor autorizado que devuelva un calendario JSON. La app ya incluye el calendario FOMC oficial; no hace falta rellenarla para usarlo.
- `NEWS_RSS_URLS` y `GEOPOLITICAL_RSS_URLS`: tampoco son claves. Son listas opcionales de URLs RSS separadas por comas; las fuentes públicas predeterminadas ya están configuradas.
- BLS, U.S. Treasury y CFTC: no requieren una API key para las consultas que utiliza la aplicación.

## Arranque

Backend:

```powershell
& ".\.venv\Scripts\python.exe" -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000
```

Frontend:

```powershell
pnpm --dir frontend install
pnpm --dir frontend dev
```

También puedes arrancar ambos servicios con:

```powershell
.\start.ps1
```

El acceso directo del escritorio ejecuta ese lanzador y abre el dashboard en una ventana independiente del navegador. El acceso directo de usuario es único.

Abre la aplicación desde el acceso directo del escritorio. En el dashboard usa Iniciar análisis y Detener análisis para controlar el ciclo de análisis.

## Exportación como un único archivo

Para crear una versión portable de un solo archivo ejecutable:

```powershell
.\build-portable.ps1
```

El resultado queda en `export\GOLD TERMINAL AI.exe`. El ejecutable contiene el backend, el frontend compilado y las dependencias de Python. Al abrirlo en otro ordenador, el asistente solicita las credenciales locales de MT5 y FRED y las guarda junto al ejecutable; no se incrustan credenciales en el archivo portable.

En el otro ordenador deben estar instalados MetaTrader 5 de OANDA TMS, la cuenta OANDA debe estar autenticada y debe existir un navegador (Edge, Chrome o el predeterminado de Windows). El ejecutable detecta las rutas estándar de MT5, abre el dashboard y mantiene la aplicación en modo exclusivamente analítico. La `FRED_API_KEY` queda incluida en el archivo si estaba configurada al construirlo; trata ese `.exe` como un secreto personal y no lo compartas públicamente.

## Pruebas

```powershell
& ".\.venv\Scripts\python.exe" -m pytest backend\tests -q
```

La prueba test_mt5_integration.py usa el terminal real si está abierto; si el terminal no está disponible, se marca como omitida y no debe presentarse como conexión verificada. Las pruebas unitarias verificadas actualmente cubren datos, decisión con macro incompleta, indicadores, niveles, noticias/geopolítica, patrones y riesgo.

## Seguridad y límites

- Los datos se leen del terminal; no se solicitan credenciales.
- Las decisiones parten de ESPERAR si faltan datos, si están obsoletos o si no hay confluencia.
- La confianza mostrada es cualitativa, no una probabilidad validada.
- El cálculo monetario exige `trade_tick_size` y `trade_tick_value` proporcionados por MT5.
- Los gaps y el deslizamiento pueden causar pérdidas superiores a las estimadas.
