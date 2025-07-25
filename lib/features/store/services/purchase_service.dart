// lib/features/store/services/purchase_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kpss_tarih_app/features/store/data/product_ids.dart';
import 'package:kpss_tarih_app/features/store/models/user_plan.dart';

enum PurchaseStatusEnum { loading, available, unavailable, error, purchasing }

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  PurchaseStatusEnum _status = PurchaseStatusEnum.loading;
  PurchaseStatusEnum get status => _status;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // *** HATA DÜZELTMESİ: userPlan getter'ı eklendi. ***
  UserPlan _userPlan = UserPlan.free;
  UserPlan get userPlan => _userPlan;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _updateStatus(PurchaseStatusEnum.unavailable, "Mağaza şu an kullanılamıyor.");
      return;
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
          (purchaseDetailsList) => _onPurchaseUpdated(purchaseDetailsList),
      onDone: () => _subscription.cancel(),
      onError: (error) => _updateStatus(PurchaseStatusEnum.error, "Satın alma akışında bir hata oluştu: $error"),
    );

    await _loadProducts();
    await restorePurchases();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(productIds);
      if (response.error != null) {
        _updateStatus(PurchaseStatusEnum.error, response.error!.message);
        return;
      }
      _products = response.productDetails;
      _updateStatus(PurchaseStatusEnum.available);
    } catch (e) {
      _updateStatus(PurchaseStatusEnum.error, "Ürünler yüklenirken bir hata oluştu: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print("Geçmiş satın alımlar geri yüklenirken hata oluştu: $e");
    }
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    _updateStatus(PurchaseStatusEnum.purchasing);
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      if (consumableIds.contains(productDetails.id)) {
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _updateStatus(PurchaseStatusEnum.error, "Satın alma başlatılırken hata: $e");
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    bool hasActiveSubscription = false;
    bool isLifetime = false;

    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }

        if (purchase.productID == omurBoyuId) {
          isLifetime = true;
        } else if (subscriptionIds.contains(purchase.productID)) {
          hasActiveSubscription = true;
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _handleFailedPurchase(purchase);
      }
    }
    _updateUserPlan(isLifetime, hasActiveSubscription);
    _updateStatus(PurchaseStatusEnum.available);
  }

  void _updateUserPlan(bool isLifetime, bool hasActiveSubscription) {
    if (isLifetime) {
      _userPlan = UserPlan.fullPremium;
    } else if (hasActiveSubscription) {
      _userPlan = UserPlan.premium;
    } else {
      _userPlan = UserPlan.free;
    }
    notifyListeners();
  }

  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    print("Satın alma hatası: ${purchaseDetails.error?.message}");
    _errorMessage = purchaseDetails.error?.message ?? "Bilinmeyen bir hata oluştu.";
    notifyListeners();
  }

  void _updateStatus(PurchaseStatusEnum status, [String? message]) {
    _status = status;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
