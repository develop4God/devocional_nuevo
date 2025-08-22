# Checklist para Copilot - Refactorizar y Optimizar Tests en Devocional_nuevo

> **IMPORTANTE:**  
> Antes de iniciar cualquier tarea, **lee todo el checklist hasta el final** para comprender el contexto completo y evitar errores por falta de información.

## 1. Preparación de ambiente
- [ ] Verificar que el ambiente esté configurado correctamente usando el workflow `copilot-setup-steps`.
- [ ] Si no está listo, ejecutar el workflow antes de continuar.

## 2. Creación de rama de trabajo
- [ ] Crear una nueva rama: `refactor/tests-copilot` a partir de la rama principal.

## 3. Auditoría y limpieza de tests existentes
- [ ] Revisar todos los archivos de test en `Devocional_nuevo/test/`.
- [ ] Eliminar o reescribir tests triviales, redundantes o que sólo validan getters/setters.
- [ ] Documentar los tests con comentarios breves sobre su propósito.
- [ ] Agrupar los tests por funcionalidad/módulo y asegurarse que los nombres sean descriptivos y terminen en `_test.dart`.

## 4. Desacoplar y robustecer los tests
- [ ] Refactorizar los tests para evitar acoplamiento excesivo con la implementación interna.
- [ ] Validar comportamientos y resultados esperados, no el código interno.
- [ ] Implementar mocks/fakes para dependencias externas (servicios, APIs, archivos) usando paquetes como `mockito` o `mocktail`.

## 5. Actualización y alineación con el código fuente
- [ ] Por cada cambio en funciones, clases o servicios, actualizar sus tests en el mismo commit/PR.
- [ ] Si se detecta un test roto por cambio lógico, refactorizar el test para que valide el nuevo comportamiento esperado.

## 6. Pruebas útiles y cobertura lógica
- [ ] Priorizar tests que validen lógica de negocio, casos reales de uso y errores esperados (edge cases).
- [ ] Evitar escribir tests triviales o que siempre pasen (true/false por defecto).
- [ ] Incluir al menos un test de integración por cada servicio relevante.

## 7. Ejecución y validación continua
- [ ] Ejecutar `flutter test` y corregir cualquier error o warning detectado.
- [ ] Aplicar `dart format .` y `dart analyze .` en todos los tests y código fuente.
- [ ] Ejecutar `flutter test --coverage` y verificar que la cobertura lógica supere el 80%.
- [ ] Adjuntar el reporte de cobertura y logs de ejecución exitosos.

## 8. Automatización y revisión
- [ ] Configurar el workflow de CI/CD para ejecutar los tests en cada PR y push.
- [ ] Documentar cualquier test que no pueda ser refactorizado por bugs en el código y crear un issue para seguimiento.

## 9. Confirmación y entrega
- [ ] Hacer commit de cada cambio relevante en la rama `refactor/tests-copilot`.
- [ ] Abrir un Pull Request para revisión, adjuntando evidencia de ejecución y reporte de cobertura.

---

**Notas adicionales:**
- Si algún paso requiere ayuda manual, detén el workflow y reporta el motivo.
- Mantén los mensajes de commit claros y descriptivos.
