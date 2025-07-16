#!/bin/bash

# 1. Leer versión actual desde pubspec.yaml
VERSION_LINE=$(grep '^version:' pubspec.yaml)
VERSION=$(echo "$VERSION_LINE" | cut -d ' ' -f2)
CURRENT_VERSION_NAME=$(echo "$VERSION" | cut -d '+' -f1) # Esto es el versionName (ej. 1.0.0)
CURRENT_BUILD_NUMBER=$(echo "$VERSION" | cut -d '+' -f2)   # Esto es el versionCode (ej. 16)

# Extraer componentes del versionName actual (asumiendo formato X.Y.Z)
# Esto tomará "1" de "1.0.0" y "0" de "1.0.0"
MAJOR_VERSION=$(echo "$CURRENT_VERSION_NAME" | cut -d '.' -f1)
MINOR_VERSION=$(echo "$CURRENT_VERSION_NAME" | cut -d '.' -f2)
# La tercera parte (patch) del versionName será reemplazada por el nuevo BUILD_NUMBER

# 2. Incrementar el número de compilación (versionCode) automáticamente
NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
echo "Número de compilación (versionCode) actual: $CURRENT_BUILD_NUMBER"
echo "Nuevo número de compilación (versionCode): $NEW_BUILD_NUMBER"

# 3. Derivar el nuevo número de versión (versionName)
# El nuevo versionName será MAJOR.MINOR.NEW_BUILD_NUMBER
# Esto asegura que la parte final del versionName siempre coincida con el versionCode
NEW_VERSION_NAME="${MAJOR_VERSION}.${MINOR_VERSION}.${NEW_BUILD_NUMBER}"

echo "Número de versión (versionName) actual: $CURRENT_VERSION_NAME"
echo "Nuevo número de versión (versionName) derivado: $NEW_VERSION_NAME"

# 4. Construir la nueva cadena de versión completa
NEW_FULL_VERSION="$NEW_VERSION_NAME+$NEW_BUILD_NUMBER"

# 5. Reemplazar versión en pubspec.yaml
echo "Actualizando pubspec.yaml a version: $NEW_FULL_VERSION"
sed -i "s/^version: .*/version: $NEW_FULL_VERSION/" pubspec.yaml

# 6. Agregar cambios al staging
git add .

# 7. Mensaje de commit
read -p "Mensaje del commit: " COMMIT_MESSAGE
git commit -m "$COMMIT_MESSAGE"

# 8. Crear tag con la nueva versión
git tag "v$NEW_FULL_VERSION"

# 9. Hacer push del commit y del tag
git push origin main
git push origin "v$NEW_FULL_VERSION"

# 10. Confirmación
echo "✅ Commit y tag creados con versión: $NEW_FULL_VERSION"
