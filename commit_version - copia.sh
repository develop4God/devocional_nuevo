#!/bin/bash

# 1. Leer versión actual desde pubspec.yaml
VERSION_LINE=$(grep '^version:' pubspec.yaml)
VERSION=$(echo "$VERSION_LINE" | cut -d ' ' -f2)
VERSION_NUMBER=$(echo "$VERSION" | cut -d '+' -f1)
BUILD_NUMBER=$(echo "$VERSION" | cut -d '+' -f2)

# 2. Incrementar el número de compilación
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$VERSION_NUMBER+$NEW_BUILD_NUMBER"

# 3. Reemplazar versión en pubspec.yaml
sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# 4. Agregar cambios al staging
git add .

# 5. Mensaje de commit
read -p "Mensaje del commit: " COMMIT_MESSAGE
git commit -m "$COMMIT_MESSAGE"

# 6. Crear tag con la nueva versión
git tag "v$NEW_VERSION"

# 7. Hacer push del commit y del tag
git push origin main
git push origin "v$NEW_VERSION"

# 8. Confirmación
echo "✅ Commit y tag creados con versión: $NEW_VERSION"
