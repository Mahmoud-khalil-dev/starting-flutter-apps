import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/safe_cubit.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/features/auth/domain/repositories/auth_repository.dart';

class ResendState extends Equatable {
  const ResendState({
    this.ticksLeft = 0,
    this.sending = false,
    this.sentCount = 0,
    this.failure,
  });

  final int ticksLeft;
  final bool sending;
  final int sentCount;
  final Failure? failure;

  Duration get left => Motion.tick * ticksLeft;

  bool get canSend => ticksLeft == 0 && !sending;

  @override
  List<Object?> get props => [ticksLeft, sending, sentCount, failure];
}

/// The "send a new code" button: a cooldown of [cooldownTicks] seconds
/// after each code, one request at a time.
class ResendCodeCubit extends SafeCubit<ResendState> {
  ResendCodeCubit(this._repository, {this.cooldownTicks = 60})
    : super(const ResendState());

  final AuthRepository _repository;
  final int cooldownTicks;
  Timer? _timer;

  /// Starts the wait when a code was just sent: the caller says so, or the
  /// repository holds a fresh sign-up code. A cold open allows a send at once.
  void begin({bool justSent = false}) {
    // Always consume the flag, so a code is never counted twice.
    final fresh = _repository.takeCodeJustSent();
    if (justSent || fresh) startCooldown();
  }

  void startCooldown() {
    if (isClosed) return;
    _timer?.cancel();
    emit(ResendState(ticksLeft: cooldownTicks, sentCount: state.sentCount));
    _timer = Timer.periodic(Motion.tick, (timer) {
      final next = state.ticksLeft - 1;
      emit(ResendState(ticksLeft: next, sentCount: state.sentCount));
      if (next <= 0) timer.cancel();
    });
  }

  Future<void> resend() async {
    if (!state.canSend) return;
    emit(ResendState(sending: true, sentCount: state.sentCount));
    final result = await _repository.resendCode();
    result.fold(
      (failure) =>
          emit(ResendState(sentCount: state.sentCount, failure: failure)),
      (_) {
        // The screen may have gone while the request ran.
        if (isClosed) return;
        emit(ResendState(sentCount: state.sentCount + 1));
        startCooldown();
      },
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
