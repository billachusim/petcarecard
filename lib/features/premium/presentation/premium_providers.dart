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
    });
    return const PremiumState(isPremium: false, isLoading: true);
  }

  Future<void> _initIAP() async {
    final isUnlocked = await _repository.isPremiumUnlocked();

    final purchaseStream = _iap.purchaseStream;
    _subscription = purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Store error: ${error.toString()}',
        );
      },
    );

    final bool available = await _iap.isAvailable();
    if (!available) {
      state = state.copyWith(
        isPremium: isUnlocked,
        isLoading: false,
        isStoreAvailable: false,
      );
      return;
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails({productId});

    ProductDetails? details;
    if (response.productDetails.isNotEmpty) {
      details = response.productDetails.firstWhere(
        (element) => element.id == productId,
        orElse: () => response.productDetails.first,
      );
    }

    state = state.copyWith(
      isPremium: isUnlocked,
      isLoading: false,
      isStoreAvailable: true,
      productDetails: details,
    );
  }

  Future<void> buyLifetime() async {
    if (state.productDetails == null) {
      state = state.copyWith(
        errorMessage: 'Store product details not loaded. Please try again in a moment.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: state.productDetails!);

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start purchase: $e',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      await _iap.restorePurchases();
    } catch (e) {
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
