#!/bin/bash

# 1. Leer versión actual desde pubspec.yaml
VERSION_LINE=$(grep '^version:' pubspec.yaml)
VERSION=$(echo "$VERSION_LINE" | cut -d ' ' -f2)
CURRENT_VERSION_NAME=$(echo "$VERSION" | cut -d '+' -f1) # Esto es el versionName (ej. 1.0.0)
CURRENT_BUILD_NUMBER=$(echo "$VERSION" | cut -d '+' -f2)   # Esto es el versionCode (ej. 16)

# Extraer las dos primeras partes del versionName (ej. "1.0" de "1.0.0" o "1.0.17")
# Esto asegura que siempre tomamos la parte "major.minor"
# Si el formato es solo "1.0", esto devolverá "1.0". Si es "1.0.0", devolverá "1.0".
# Si el formato es "1", esto devolverá "1". En ese caso, lo forzamos a "1.0".
BASE_VERSION_NAME=""
if [[ "$CURRENT_VERSION_NAME" =~ ^([0-9]+\.[0-9]+)(\.[0-9]+)?$ ]]; then
    BASE_VERSION_NAME="${BASH_REMATCH[1]}" # Captura 1.0 de 1.0.0 o 1.0.17
else
    # Fallback si el formato no es el esperado, intenta extraer las dos primeras partes
    MAJOR_VERSION=$(echo "$CURRENT_VERSION_NAME" | cut -d '.' -f1)
    MINOR_VERSION=$(echo "$CURRENT_VERSION_NAME" | cut -d '.' -f2)
    if [[ -n "$MAJOR_VERSION" && -n "$MINOR_VERSION" ]]; then
        BASE_VERSION_NAME="${MAJOR_VERSION}.${MINOR_VERSION}"
    elif [[ -n "$MAJOR_VERSION" ]]; then
        BASE_VERSION_NAME="${MAJOR_VERSION}.0" # Si solo hay major, asume minor 0
    else
        BASE_VERSION_NAME="1.0" # Valor por defecto si no se puede parsear
    fi
fi


# 2. Incrementar el número de compilación (versionCode) automáticamente
NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
echo "Número de compilación (versionCode) actual: $CURRENT_BUILD_NUMBER"
echo "Nuevo número de compilación (versionCode): $NEW_BUILD_NUMBER"

# 3. Derivar el nuevo número de versión (versionName)
# El nuevo versionName será BASE_VERSION_NAME.NEW_BUILD_NUMBER
# Esto asegura que la parte final del versionName siempre coincida con el versionCode
NEW_VERSION_NAME="${BASE_VERSION_NAME}.${NEW_BUILD_NUMBER}"

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
