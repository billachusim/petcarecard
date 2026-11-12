import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../data/repositories/providers.dart';
import '../data/premium_repository.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PremiumRepository(dbService);
});

class PremiumState {
  final bool isPremium;
  final bool isLoading;
  final bool isStoreAvailable;
  final ProductDetails? productDetails;
  final String? errorMessage;
  final String? successMessage;

  const PremiumState({
    required this.isPremium,
    this.isLoading = false,
    this.isStoreAvailable = false,
    this.productDetails,
    this.errorMessage,
    this.successMessage,
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? isLoading,
    bool? isStoreAvailable,
    ProductDetails? productDetails,
    String? errorMessage,
    String? successMessage,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      productDetails: productDetails ?? this.productDetails,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final premiumNotifierProvider = NotifierProvider<PremiumNotifier, PremiumState>(
  () => PremiumNotifier(),
);

class PremiumNotifier extends Notifier<PremiumState> {
  static const String productId = 'pet_care_card_lifetime';
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PremiumRepository get _repository => ref.read(premiumRepositoryProvider);

  @override
  PremiumState build() {
    _initIAP();
    ref.onDispose(() {
      _subscription?.cancel();
      _restoreTimer?.cancel();
    });
    return const PremiumState(isPremium: false, isLoading: true);
  }

  /// How long to wait for the store before giving up on a spinner.
  static const _storeTimeout = Duration(seconds: 10);
  static const _restoreTimeout = Duration(seconds: 20);
  Timer? _restoreTimer;

  Future<void> _initIAP() async {
    var isUnlocked = false;
    try {
      isUnlocked = await _repository.isPremiumUnlocked();
    } catch (_) {
      // Fall through as not unlocked; Restore Purchase can recover it.
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Store error: ${error.toString()}',
        );
      },
    );

    state = state.copyWith(isPremium: isUnlocked);
    await _loadProduct();
  }

  /// Loads the lifetime product. Always ends with isLoading = false, so the
  /// Premium screen never spins forever on a slow or unreachable store.
  Future<void> _loadProduct() async {
    try {
      final bool available = await _iap.isAvailable().timeout(_storeTimeout);
      if (!available) {
        state = state.copyWith(
          isLoading: false,
          isStoreAvailable: false,
          errorMessage: "The store isn't available right now. Please try again.",
        );
        return;
      }

      final ProductDetailsResponse response =
          await _iap.queryProductDetails({productId}).timeout(_storeTimeout);

      ProductDetails? details;
      if (response.productDetails.isNotEmpty) {
        details = response.productDetails.firstWhere(
          (element) => element.id == productId,
          orElse: () => response.productDetails.first,
        );
      }

      state = state.copyWith(
        isLoading: false,
        isStoreAvailable: true,
        productDetails: details,
        errorMessage: details == null
            ? "Couldn't load the price from the store. Tap Unlock to try again."
            : null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            "Couldn't reach the store. Check your connection and tap Unlock to try again.",
      );
    }
  }

  Future<void> buyLifetime() async {
    if (state.productDetails == null) {
      // Price didn't load earlier (slow store or offline): try once more.
      state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
      await _loadProduct();
      if (state.productDetails == null) return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: state.productDetails!);

    try {
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "The purchase couldn't start. Please try again.",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start purchase: $e',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    // The store only reports back when there IS something to restore, so
    // stop the spinner ourselves if nothing arrives.
    _restoreTimer?.cancel();
    _restoreTimer = Timer(_restoreTimeout, () {
      if (state.isLoading && !state.isPremium) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No previous purchase found for this Apple ID or Google account.',
        );
      }
    });
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _restoreTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore purchases: $e',
      );
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: purchaseDetails.error?.message ?? 'Purchase failed',
        );
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        _restoreTimer?.cancel();
        await _repository.setPremiumUnlocked(true);
        state = state.copyWith(
          isPremium: true,
          isLoading: false,
          successMessage: purchaseDetails.status == PurchaseStatus.restored
              ? 'Purchases successfully restored!'
              : 'Thank you! Lifetime Access Unlocked.',
        );
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        state = state.copyWith(isLoading: false);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
