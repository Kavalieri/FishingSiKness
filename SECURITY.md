# 🔒 Security Policy - FishingSiKness

## 🛡️ Supported Versions

Este proyecto es experimental y está en desarrollo activo. Las versiones que reciben actualizaciones de seguridad son:

| Version | Supported          | Status |
| ------- | ------------------ | ------ |
| 0.1.0-alpha   | ✅ | Active Development |
| < 0.1.0   | ❌ | No Supported |

## 🚨 Reporting a Vulnerability

Si descubres una vulnerabilidad de seguridad, por favor sigue este proceso:

### ⚡ Para Vulnerabilidades Críticas
1. **NO** crees un issue público
2. Contacta directamente via [GitHub Security Advisory](https://github.com/Kavalieri/FishingSiKness/security/advisories)
3. O envía un email a: kavateuve@gmail.com con el asunto "SECURITY: FishingSiKness Vulnerability"

### 📋 Información a Incluir
- Descripción detallada de la vulnerabilidad
- Pasos para reproducirla
- Impacto potencial
- Versión afectada
- Plataforma (Windows/Android/Web)
- Si es posible, un fix sugerido

### ⏱️ Proceso de Respuesta
- **24-48 horas**: Confirmación de recepción
- **1 semana**: Evaluación inicial y clasificación
- **2 semanas**: Fix desarrollado (para vulnerabilidades confirmadas)
- **Release**: Parche publicado y vulnerability disclosed

## 🔐 Security Considerations

### 📱 Data Privacy
- **Saves locales**: Los archivos de guardado se almacenan localmente
- **No telemetry**: El juego no envía datos a servidores externos
- **No ads tracking**: Los ads (cuando se implementen) no rastrean usuarios

### 🔒 Permissions
- **Android**: Solo permisos de almacenamiento para saves
- **Windows**: No requiere permisos especiales
- **Web**: Solo localStorage para saves

### 🤖 AI Code Security
- **Code Review**: Todo el código IA pasa por revisión automática
- **No Dynamic Code**: No se ejecuta código dinámico generado
- **Static Analysis**: Testing continuo para detectar vulnerabilidades

## 🧪 Security Testing

Si quieres ayudar con security testing:

1. **Scope Permitido**:
   - ✅ Local testing en tus propios dispositivos
   - ✅ Analysis de archivos de save
   - ✅ Network analysis (cuando aplique)
   - ✅ Mobile app analysis

2. **Scope NO Permitido**:
   - ❌ Testing en infraestructura de terceros
   - ❌ Social engineering
   - ❌ DoS/DDoS attacks
   - ❌ Physical access testing

## 🙏 Hall of Fame

Contributors que han reportado vulnerabilidades responsablemente:

*¡Sé el primero en aparecer aquí!*

---

**Nota**: Este es un proyecto experimental open source. Valoramos enormemente los reports de seguridad responsables que ayuden a mejorar la seguridad para todos los usuarios.
