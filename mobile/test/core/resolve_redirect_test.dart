import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/router/routes.dart';

void main() {
  group('signed out', () {
    test('may use role select, login and sign-up', () {
      for (final location in [
        Routes.roleSelect,
        Routes.consumerLogin,
        Routes.consumerSignup,
        Routes.vendorLogin,
        Routes.vendorSignup,
      ]) {
        expect(resolveRedirect(role: null, location: location), isNull, reason: location);
      }
    });

    test('is sent to role select from anything protected', () {
      for (final location in [Routes.consumerHome, Routes.vendorHome, Routes.vendorOnboarding, '/nowhere']) {
        expect(resolveRedirect(role: null, location: location), Routes.roleSelect, reason: location);
      }
    });
  });

  group('a customer', () {
    test('may use the customer area', () {
      expect(resolveRedirect(role: UserRole.consumer, location: Routes.consumerHome), isNull);
    });

    test('is sent home from the vendor area', () {
      for (final location in [Routes.vendorHome, Routes.vendorOnboarding]) {
        expect(resolveRedirect(role: UserRole.consumer, location: location), Routes.consumerHome, reason: location);
      }
    });

    test('skips the sign-in screens', () {
      for (final location in [Routes.roleSelect, Routes.consumerLogin, Routes.vendorSignup]) {
        expect(resolveRedirect(role: UserRole.consumer, location: location), Routes.consumerHome, reason: location);
      }
    });
  });

  group('a vendor', () {
    test('may use the vendor area, including onboarding', () {
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.vendorHome), isNull);
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.vendorOnboarding), isNull);
    });

    test('is sent home from the customer area', () {
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.consumerHome), Routes.vendorHome);
    });

    test('skips the sign-in screens', () {
      for (final location in [Routes.roleSelect, Routes.vendorLogin, Routes.consumerSignup]) {
        expect(resolveRedirect(role: UserRole.vendor, location: location), Routes.vendorHome, reason: location);
      }
    });
  });

  group('a vendor and their stall', () {
    test('with no stall yet is taken to onboarding from the home screen and the sign-in screens', () {
      for (final location in [Routes.vendorHome, Routes.roleSelect, Routes.vendorLogin, Routes.vendorSignup]) {
        expect(
          resolveRedirect(role: UserRole.vendor, location: location, vendorHasStall: false),
          Routes.vendorOnboarding,
          reason: location,
        );
      }
    });

    test('with no stall yet cannot reach any other vendor screen', () {
      for (final location in [Routes.vendorDashboard, Routes.vendorAnalytics, Routes.vendorProfile, Routes.vendorStatusCreate]) {
        expect(
          resolveRedirect(role: UserRole.vendor, location: location, vendorHasStall: false),
          Routes.vendorOnboarding,
          reason: location,
        );
      }
    });

    test('with a stall may use every vendor screen', () {
      for (final location in [
        Routes.vendorHome,
        Routes.vendorDashboard,
        Routes.vendorAnalytics,
        Routes.vendorProfile,
        Routes.vendorStatusCreate,
        Routes.vendorStatus(3),
        Routes.vendorStall(1),
      ]) {
        expect(resolveRedirect(role: UserRole.vendor, location: location, vendorHasStall: true), isNull, reason: location);
      }
    });

    test('a customer cannot reach vendor screens and a vendor cannot reach customer ones', () {
      expect(resolveRedirect(role: UserRole.consumer, location: Routes.vendorDashboard), Routes.consumerHome);
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.consumerStatus(1), vendorHasStall: true), Routes.vendorHome);
    });

    test('with no stall yet may stay on onboarding', () {
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.vendorOnboarding, vendorHasStall: false), isNull);
    });

    test('with a stall leaves onboarding for the home screen', () {
      expect(
        resolveRedirect(role: UserRole.vendor, location: Routes.vendorOnboarding, vendorHasStall: true),
        Routes.vendorHome,
      );
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.vendorHome, vendorHasStall: true), isNull);
    });

    test('whose stall is not known yet is left where they are', () {
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.vendorHome), isNull);
      expect(resolveRedirect(role: UserRole.vendor, location: Routes.vendorOnboarding), isNull);
    });

    test('is never sent to onboarding if they are a customer', () {
      expect(
        resolveRedirect(role: UserRole.consumer, location: Routes.vendorOnboarding, vendorHasStall: false),
        Routes.consumerHome,
      );
    });
  });

  test('each role has one home and one login', () {
    expect(Routes.homeFor(UserRole.consumer), Routes.consumerHome);
    expect(Routes.homeFor(UserRole.vendor), Routes.vendorHome);
    expect(Routes.loginFor(UserRole.consumer), Routes.consumerLogin);
    expect(Routes.loginFor(UserRole.vendor), Routes.vendorLogin);
  });
}
