# Política de privacidad

para la app iOS "CulinaAI"

**Fecha:** 04.11.2025  
**Versión:** 1.0

---

## 1. Responsable

**Empresa:** CulinaAI  
**Representada por:** Moritz Serrin  
**Dirección:** Sonnenblumenweg 8, 21244 Buchholz, Alemania  
**Correo:** kontakt@culinaai.com  
**Privacidad:** datenschutz@culinaai.com

---

## 2. Información general

La protección de sus datos personales es una prioridad para nosotros. Procesamos datos personales exclusivamente conforme al RGPD, la ley federal alemana de protección de datos (BDSG) y otras normativas aplicables.

**Principios de procesamiento de datos:**

- **Minimización:** Solo se recogen datos necesarios
- **Transparencia:** Comunicación clara sobre el uso de datos
- **Seguridad:** Cifrado TLS y almacenamiento seguro
- **Sin publicidad:** No hay seguimiento ni perfilado

---

## 3. Datos recogidos

### 3.1 Cuenta de usuario

**Datos necesarios al registrarse:**

- Nombre de usuario (3–32 caracteres)
- Correo electrónico
- Contraseña (mín. 6 caracteres, bcrypt)
- Opcional: Sign in with Apple

**Propósito:** Creación y autenticación de cuenta  
**Base legal:** Art. 6 Abs. 1 lit. b RGPD (ejecución contrato)

### 3.2 Gestión de recetas

**Datos almacenados:**

- Título de la receta, ingredientes, instrucciones
- Valores nutricionales, tiempo de cocción, etiquetas
- Favoritos, planificación de menús
- Valoraciones (1–5 estrellas)

**Propósito:** Función principal – gestión de recetas  
**Duración:** Hasta que el usuario elimine los datos

### 3.3 Preferencias alimentarias

- Alergias (ej. frutos secos, gluten)
- Tipo de alimentación (vegano, vegetariano)
- Gustos y aversiones
- Notas (texto libre)

**Propósito:** Sugerencias personalizadas y filtrado

### 3.4 Inteligencia artificial (OpenAI)

Usamos OpenAI GPT-4o-mini para:

- Creación automática de recetas
- Respuestas a preguntas culinarias

**Datos enviados:**

- Listas de ingredientes
- Mensajes de chat
- Preferencias alimentarias (contexto)
- **NINGÚN dato personal**

**Proveedor:** OpenAI L.L.C.

- **Destinatario:** OpenAI L.L.C., USA
- **Base legal:** Art. 49 Abs. 1 lit. a RGPD (consentimiento)
- **Duración:** Máximo 30 días en OpenAI

**Nota importante:** Los contenidos generados por IA son automáticos. No asumimos responsabilidad por su exactitud, integridad o idoneidad para la salud.

**Aviso importante sobre recetas generadas por IA:**

Los sistemas de IA pueden cometer errores. Por favor, revise cuidadosamente todas las recetas generadas por IA antes de prepararlas. Especialmente si tiene alergias, intolerancias o requisitos dietéticos especiales, debe verificar dos veces la lista de ingredientes y las instrucciones.

No asumimos responsabilidad por las consecuencias para la salud que surjan del uso de recetas generadas por IA. La responsabilidad de revisar las recetas y decidir si una receta es adecuada para sus necesidades individuales recae únicamente en usted.

### 3.5 Pagos (Apple)

**Suscripción:** 5,99 €/mes vía Apple In-App Purchase

Datos gestionados por Apple:

- Apple ID
- Información de pago
- Historial de compras

**Nota:** No recibimos datos de pago, solo confirmación de transacción de Apple. Para más información, consulte la Política de Privacidad de Apple.

### 3.6 Registro de errores y crash (Sentry)

Usamos **Sentry** de Functional Software, Inc. para mejorar la estabilidad de la app.

**Datos enviados en caso de crashes o errores:**

- Información del dispositivo (modelo, versión iOS)
- Versión de la app y número de build
- Stack traces (registros técnicos de errores)
- Marca de tiempo del error
- Capturas de pantalla en el momento del error (opcional)
- Acciones del usuario antes del error (breadcrumbs)
- **NINGÚN dato personal** (nombres, correos, etc.)

**Proveedor:** Functional Software, Inc. (Sentry)

- **Destinatario:** Functional Software, Inc., USA
- **Base legal:** Art. 6 Abs. 1 lit. f RGPD (interés legítimo)
- **Duración:** 30 días en Sentry
- **Transferencia de datos:** UE/USA, conforme al RGPD

**Propósito:** Detección y resolución de errores técnicos para mejorar la estabilidad de la app.

Para más información: [Política de Privacidad de Sentry](https://sentry.io/privacy/)

### 3.7 Almacenamiento local

**UserDefaults (no sensible):**

- Idioma de la app, modo oscuro
- Estado de onboarding
- Sugerencias de menú (caché)

**Keychain (cifrado):**

- Tokens de acceso y actualización
- ID de usuario, correo electrónico

**Eliminación:** Automáticamente realizada por iOS al desinstalar la app

---

## 4. Transferencia de datos a terceros países

Los siguientes proveedores pueden procesar datos fuera de la Unión Europea:

| Proveedor | Propósito | Ubicación | Base Legal |
|-----------|-----------|-----------|------------|
| **Supabase Inc.** | Base de datos y autenticación | UE/USA | Art. 6 Abs. 1 lit. b RGPD |
| **OpenAI L.L.C.** | Generación de recetas con IA | USA | Art. 49 Abs. 1 lit. a RGPD |
| **Apple Inc.** | Compras in-app y suscripciones | USA | Decisión de adecuación de la UE |
| **Functional Software, Inc. (Sentry)** | Seguimiento de errores y crash reporting | USA/UE | Art. 6 Abs. 1 lit. f RGPD |

**Todas las transferencias de datos se realizan cifradas vía HTTPS/TLS.**

---

## 5. Medidas técnicas y organizativas

Para proteger sus datos, implementamos las siguientes medidas de seguridad:

- **Cifrado:** TLS/HTTPS para todas las transferencias de datos
- **Protección de contraseñas:** Hash bcrypt con salt
- **Control de acceso:** Row Level Security (RLS) en la base de datos
- **Seguridad de tokens:** Almacenamiento seguro en iOS Keychain
- **Registro de eliminación:** Al eliminar una cuenta solo se guarda un hash del id de usuario, durante tres años
- **Minimización de datos:** Sin seguimiento, publicidad o perfilado
- **Estrategia de respaldo:** Copias diarias de la base de datos, conservadas 7 días. Sirven para restaurar el servicio tras una caída y no para recuperar una cuenta eliminada.

---

## 6. Derechos según RGPD

Tiene los siguientes derechos respecto a sus datos personales:

- **Acceso (Art. 15):** Recibir información sobre sus datos almacenados
- **Rectificación (Art. 16):** Corregir datos inexactos o incompletos
- **Supresión (Art. 17):** Eliminar su cuenta y datos asociados
- **Portabilidad (Art. 20):** En la app, en Ajustes, puede descargar un archivo JSON. Contiene correo, nombre, usuario, alergias, dieta, preferencias de sabor, aversiones, notas y recetas.
- **Oposición (Art. 21):** Oponerse a un procesamiento específico de datos
- **Reclamación (Art. 77):** Presentar una reclamación ante una autoridad supervisora

**Para ejercer sus derechos:**

Contáctenos en **datenschutz@culinaai.com**.  
Procesaremos su solicitud sin demora indebida.

---

## 7. Duración de conservación

| Tipo de Datos | Período de Retención | Método de Eliminación |
|---------------|----------------------|----------------------|
| Cuenta, perfil y correo | Hasta que elimine la cuenta en la app | Inmediatamente, con la cuenta |
| Recetas, menús, favoritos, valoraciones, fotos | Hasta que elimine la cuenta en la app | Inmediatamente, con la cuenta |
| Alergias, dieta, sabor, aversiones, notas | Hasta que elimine la cuenta en la app | Inmediatamente, con la cuenta |
| Mensajes de chat | Solo en memoria durante la sesión | Al cerrar la app. No hay copia del chat en el servidor. |
| Informes de fallos (Sentry) | 30 días | Eliminados por Sentry. Sin correo ni id de usuario. |
| Copias de la base de datos | 7 días | La copia caduca. Una cuenta eliminada no se restaura desde ella. |
| Registro de eliminación | 3 años | Solo un hash del id de usuario, la hora y que usted pidió la eliminación. Sin nombre, correo ni recetas. Después se borra solo. |

---

## 8. Protección de menores

**Requisito de edad:** El uso de la app está permitido para personas de **16 años o más**.

Los usuarios menores de 16 años deben tener el consentimiento de los padres o tutores de acuerdo con el Art. 8 RGPD.

---

## 9. Sin publicidad ni seguimiento

**Nos abstenemos completamente de usar:**

- Cookies o tecnologías de seguimiento similares
- Google Analytics o herramientas de análisis comparables
- Publicidad, redes publicitarias o perfilado de usuarios
- Plugins de redes sociales o rastreadores externos

**✅ Sus datos personales nunca se venderán ni se usarán con fines publicitarios.**

---

## 10. Eliminación de cuenta

Puede eliminar su cuenta en cualquier momento siguiendo estos pasos:

1. Abra **Configuración** en la app
2. Seleccione **"Eliminar cuenta"**
3. Confirme la eliminación

**Los datos eliminados incluyen:**

- Cuenta de usuario y datos de autenticación
- Todas las recetas, menús y favoritos guardados
- Preferencias alimentarias y configuraciones personales
- Valoraciones y notas

**Importante:**

- Las suscripciones de Apple deben cancelarse por separado en la configuración de su cuenta de Apple ID
- Queda un registro de eliminación: solo un hash del id de usuario, la hora y que usted pidió la eliminación. Sin nombre, correo ni recetas. Se conserva 3 años y luego se borra.
- Una copia de la base de datos puede contener la cuenta hasta 7 días. Las copias no se usan para recuperar una cuenta eliminada.
- La eliminación es permanente e irreversible

---

## 11. Cambios en esta política de privacidad

Nos reservamos el derecho de modificar esta Política de Privacidad en caso de cambios legales o técnicos.

La versión más reciente está siempre disponible en la app y en **https://culinaai.com/datenschutz**.

Los usuarios serán informados de cualquier cambio significativo dentro de la app.

---

## 12. Contacto

**Consultas de protección de datos:** datenschutz@culinaai.com  
**Soporte técnico:** support@culinaai.com  
**Consultas generales:** kontakt@culinaai.com

---

## 13. Ley aplicable y jurisdicción

Esta Política de Privacidad y todas las actividades de procesamiento de datos relacionadas se rigen exclusivamente por la ley alemana.

**Lugar de jurisdicción:** Alemania

**Marco legal aplicable:**

- **RGPD** – Reglamento General de Protección de Datos
- **BDSG** – Ley Federal Alemana de Protección de Datos
- **TMG** – Ley de Telemedios
- **UWG** – Ley contra la Competencia Desleal
- **BGB** – Código Civil Alemán

---

**Fecha:** 04. Noviembre 2025  
**Versión:** 1.0
