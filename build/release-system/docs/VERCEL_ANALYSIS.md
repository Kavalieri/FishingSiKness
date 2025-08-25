# 🚀 Estudio Vercel para Bar-Sik

## 🎯 **OBJETIVO**
Deploy automático y gratuito del build web de Bar-Sik en Vercel con actualización continua.

## 📋 **ANÁLISIS DE VERCEL PARA GODOT WEB**

### ✅ **Ventajas para Bar-Sik:**
- **Free Tier**: 100GB ancho de banda/mes + builds ilimitados
- **Deploy automático**: Conecta con GitHub → auto-deploy en cada push
- **CDN Global**: Distribución mundial automática
- **Custom Domain**: Dominio propio gratis (ej: bar-sik.vercel.app)
- **HTTPS**: SSL automático
- **Build Commands**: Personalizable para Godot exports

### 🔧 **Configuración Necesaria:**

#### **1. Estructura de Archivos:**
```
bar-sik/
├── web-deploy/          # Nueva carpeta para Vercel
│   ├── vercel.json     # Configuración
│   ├── package.json    # Build scripts
│   └── public/         # Build output
└── builds/web/latest/  # Build de Godot
    ├── index.html
    ├── index.js
    ├── index.wasm
    └── index.pck
```

#### **2. vercel.json:**
```json
{
  "buildCommand": "powershell -File ../release-system/scripts/build-web.ps1",
  "outputDirectory": "public",
  "framework": null,
  "functions": {},
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*\\.(wasm|pck))",
      "headers": [
        {
          "key": "Cross-Origin-Embedder-Policy",
          "value": "require-corp"
        },
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        }
      ]
    }
  ]
}
```

#### **3. package.json:**
```json
{
  "name": "bar-sik-web",
  "version": "0.3.0",
  "scripts": {
    "build": "cd .. && powershell -File release-system/scripts/build-web.ps1 && cp builds/web/latest/* web-deploy/public/",
    "dev": "cd .. && powershell -File release-system/scripts/build-web.ps1 -Serve"
  }
}
```

### 🚀 **Proceso de Deploy:**

#### **Setup Inicial:**
```bash
# En web-deploy/
vercel login
vercel init
vercel --prod
```

#### **Deploy Automático:**
1. **Push a main** → Vercel detecta cambios
2. **Build automático** → Ejecuta build-web.ps1
3. **Deploy automático** → Actualiza bar-sik.vercel.app
4. **Notificación** → Deploy listo en <2 minutos

### 🎮 **Beneficios Específicos para Bar-Sik:**

#### **Distribución Web Automática:**
- ✅ **URL pública**: `bar-sik.vercel.app` (o custom domain)
- ✅ **Auto-updates**: Cada commit → nueva versión live
- ✅ **Performance**: CDN + compresión automática
- ✅ **Analytics**: Métricas de uso gratuitas

#### **Testing & QA:**
- ✅ **Preview deploys**: Cada PR genera URL de testing
- ✅ **Rollback fácil**: Volver a versión anterior en 1 click
- ✅ **Logs**: Debug de builds y runtime

#### **Integración con GitHub:**
- ✅ **Status checks**: Deploy status en PRs
- ✅ **Comments automáticos**: URLs de preview en PRs
- ✅ **Branch deploys**: Testing de features

### 💡 **ESTRATEGIA RECOMENDADA:**

#### **Flujo Completo:**
1. **Desarrollo local** → `.\release-system\scripts\build-web.ps1`
2. **Push a GitHub** → Vercel auto-deploy
3. **Testing online** → bar-sik.vercel.app
4. **Release** → Builds locales + web live

#### **Casos de Uso:**
- **Demo online**: Para mostrar el juego sin descargas
- **Testing**: Probar features en web fácilmente
- **Distribución**: Alcance global sin límites
- **Marketing**: URL limpia para compartir

---

## 🚀 **IMPLEMENTACIÓN SUGERIDA:**

### **Fase 1**: Setup básico
1. Crear `web-deploy/` con configuración
2. Conectar con Vercel
3. Primer deploy manual

### **Fase 2**: Automatización
1. Integrar con GitHub Actions
2. Auto-deploy en releases
3. Preview URLs en PRs

### **Fase 3**: Optimización
1. Custom domain
2. Analytics integradas
3. Performance monitoring

---

## 💰 **COSTOS:**
- **Free Tier**: Suficiente para Bar-Sik
- **Pro ($20/mes)**: Solo si necesitas más ancho de banda
- **Sin límites de builds**: Ideal para desarrollo activo

## 🎯 **RESULTADO:**
**Bar-Sik disponible 24/7 online con updates automáticos** 🌐
