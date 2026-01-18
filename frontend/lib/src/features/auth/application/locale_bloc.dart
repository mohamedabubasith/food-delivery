import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

// Events
abstract class LocaleEvent extends Equatable {
  const LocaleEvent();
  @override
  List<Object> get props => [];
}

class LoadLocale extends LocaleEvent {}

class ChangeLocale extends LocaleEvent {
  final Locale locale;
  const ChangeLocale(this.locale);
  @override
  List<Object> get props => [locale];
}

// States
class LocaleState extends Equatable {
  final Locale locale;
  const LocaleState(this.locale);
  @override
  List<Object> get props => [locale];
}

// BLoC
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'selected_locale';

  LocaleBloc() : super(const LocaleState(Locale('en'))) {
    on<LoadLocale>(_onLoadLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  Future<void> _onLoadLocale(LoadLocale event, Emitter<LocaleState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_localeKey);

    if (languageCode != null) {
      emit(LocaleState(Locale(languageCode)));
    } else {
      // Automatic detection
      final deviceLocale = ui.PlatformDispatcher.instance.locale;
      if (deviceLocale.languageCode == 'ta') {
        emit(const LocaleState(Locale('ta')));
      } else {
        emit(const LocaleState(Locale('en')));
      }
    }
  }

  Future<void> _onChangeLocale(ChangeLocale event, Emitter<LocaleState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, event.locale.languageCode);
    emit(LocaleState(event.locale));
  }
}
