// lib/blocs/devocionales_event.dart

abstract class DevocionalesEvent {}

class LoadDevocionales extends DevocionalesEvent {}

class ChangeVersion extends DevocionalesEvent {
  final String version;
  
  ChangeVersion(this.version);
}

class ToggleFavorite extends DevocionalesEvent {
  final String devocionalId;
  
  ToggleFavorite(this.devocionalId);
}