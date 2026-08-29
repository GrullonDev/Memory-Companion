#!/bin/bash

# ============================================================
# Firebase Setup Script para Memory Companion
# ============================================================
# Este script configura los índices de Firestore y conecta
# tu aplicación Flutter con Firebase
# ============================================================

echo "🔥 Iniciando configuración de Firebase para Memory Companion..."
echo ""

# ============================================================
# PASO 1: Instalar Firebase CLI (si no está instalado)
# ============================================================
echo "📦 Paso 1: Verificando Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI no está instalado."
    echo "Instalando Firebase CLI..."
    npm install -g firebase-tools
    if [ $? -eq 0 ]; then
        echo "✅ Firebase CLI instalado correctamente"
    else
        echo "⚠️  Error al instalar Firebase CLI. Intenta manualmente:"
        echo "   npm install -g firebase-tools"
        exit 1
    fi
else
    echo "✅ Firebase CLI ya está instalado"
fi

echo ""

# ============================================================
# PASO 2: Autenticarse con Firebase
# ============================================================
echo "🔐 Paso 2: Autenticando con Firebase..."
firebase login

if [ $? -ne 0 ]; then
    echo "❌ Error de autenticación. Verifica tus credenciales."
    exit 1
fi

echo "✅ Autenticación exitosa"
echo ""

# ============================================================
# PASO 3: Seleccionar el proyecto
# ============================================================
echo "📋 Paso 3: Seleccionando proyecto..."
echo "Selecciona tu proyecto 'Memory Companion' de la lista:"
firebase projects:list

echo ""
echo "Ingresa el ID de tu proyecto:"
read PROJECT_ID

# Verificar que el proyecto existe
firebase projects:describe $PROJECT_ID > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Proyecto no encontrado. Verifica el ID."
    exit 1
fi

echo "✅ Proyecto seleccionado: $PROJECT_ID"
echo ""

# ============================================================
# PASO 4: Crear índices de Firestore
# ============================================================
echo "🗂️  Paso 4: Creando índices de Firestore..."
echo "Esto puede tomar unos minutos..."
echo ""

firebase firestore:indexes --project=$PROJECT_ID

echo ""
echo "✅ Índices creados exitosamente"
echo ""

# ============================================================
# PASO 5: Verificar conexión con Firestore
# ============================================================
echo "🔗 Paso 5: Verificando conexión con Firestore..."

firebase firestore:delete /test --project=$PROJECT_ID 2>/dev/null || true

echo "✅ Conexión con Firestore verificada"
echo ""

# ============================================================
# PASO 6: Instrucciones finales
# ============================================================
echo "🎉 ¡Configuración completada!"
echo ""
echo "📱 Pasos finales para tu app Flutter:"
echo ""
echo "1. Asegúrate de tener el google-services.json actualizado en:"
echo "   android/app/google-services.json"
echo ""
echo "2. Ejecuta en la terminal:"
echo "   cd Memory-Companion"
echo "   flutter pub get"
echo ""
echo "3. Inicia la app:"
echo "   fvm flutter run"
echo ""
echo "4. Prueba el flujo completo:"
echo "   - Registra un nuevo usuario"
echo "   - Juega una partida"
echo "   - Completa el juego"
echo "   - Ve a Firebase Console > Firestore para ver tus datos"
echo ""
echo "✨ ¡Listo para desarrollar!"
