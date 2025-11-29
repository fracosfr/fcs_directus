import 'package:flutter_test/flutter_test.dart';
import 'package:fcs_directus/fcs_directus.dart';

void main() {
  group('Now dynamic variable', () {
    test('value should return \$NOW', () {
      expect(Now.value, equals(r'$NOW'));
    });

    test('offset should create correct format with positive value', () {
      expect(Now.offset(2, 'hours'), equals(r'$NOW(+2 hours)'));
      expect(Now.offset(1, 'day'), equals(r'$NOW(+1 day)'));
    });

    test('offset should create correct format with negative value', () {
      expect(Now.offset(-2, 'hours'), equals(r'$NOW(-2 hours)'));
      expect(Now.offset(-1, 'day'), equals(r'$NOW(-1 day)'));
    });

    test('subtract should create negative offset', () {
      expect(Now.subtract(1, 'day'), equals(r'$NOW(-1 day)'));
      expect(Now.subtract(2, 'weeks'), equals(r'$NOW(-2 weeks)'));
      expect(Now.subtract(6, 'months'), equals(r'$NOW(-6 months)'));
    });

    test('add should create positive offset', () {
      expect(Now.add(1, 'day'), equals(r'$NOW(+1 day)'));
      expect(Now.add(2, 'weeks'), equals(r'$NOW(+2 weeks)'));
      expect(Now.add(6, 'months'), equals(r'$NOW(+6 months)'));
    });

    group('Convenience methods - ago', () {
      test('secondsAgo should use singular/plural correctly', () {
        expect(Now.secondsAgo(1), equals(r'$NOW(-1 second)'));
        expect(Now.secondsAgo(30), equals(r'$NOW(-30 seconds)'));
      });

      test('minutesAgo should use singular/plural correctly', () {
        expect(Now.minutesAgo(1), equals(r'$NOW(-1 minute)'));
        expect(Now.minutesAgo(15), equals(r'$NOW(-15 minutes)'));
      });

      test('hoursAgo should use singular/plural correctly', () {
        expect(Now.hoursAgo(1), equals(r'$NOW(-1 hour)'));
        expect(Now.hoursAgo(24), equals(r'$NOW(-24 hours)'));
      });

      test('daysAgo should use singular/plural correctly', () {
        expect(Now.daysAgo(1), equals(r'$NOW(-1 day)'));
        expect(Now.daysAgo(7), equals(r'$NOW(-7 days)'));
      });

      test('weeksAgo should use singular/plural correctly', () {
        expect(Now.weeksAgo(1), equals(r'$NOW(-1 week)'));
        expect(Now.weeksAgo(2), equals(r'$NOW(-2 weeks)'));
      });

      test('monthsAgo should use singular/plural correctly', () {
        expect(Now.monthsAgo(1), equals(r'$NOW(-1 month)'));
        expect(Now.monthsAgo(3), equals(r'$NOW(-3 months)'));
      });

      test('yearsAgo should use singular/plural correctly', () {
        expect(Now.yearsAgo(1), equals(r'$NOW(-1 year)'));
        expect(Now.yearsAgo(5), equals(r'$NOW(-5 years)'));
      });
    });

    group('Convenience methods - from now', () {
      test('secondsFromNow should use singular/plural correctly', () {
        expect(Now.secondsFromNow(1), equals(r'$NOW(+1 second)'));
        expect(Now.secondsFromNow(30), equals(r'$NOW(+30 seconds)'));
      });

      test('minutesFromNow should use singular/plural correctly', () {
        expect(Now.minutesFromNow(1), equals(r'$NOW(+1 minute)'));
        expect(Now.minutesFromNow(30), equals(r'$NOW(+30 minutes)'));
      });

      test('hoursFromNow should use singular/plural correctly', () {
        expect(Now.hoursFromNow(1), equals(r'$NOW(+1 hour)'));
        expect(Now.hoursFromNow(48), equals(r'$NOW(+48 hours)'));
      });

      test('daysFromNow should use singular/plural correctly', () {
        expect(Now.daysFromNow(1), equals(r'$NOW(+1 day)'));
        expect(Now.daysFromNow(30), equals(r'$NOW(+30 days)'));
      });

      test('weeksFromNow should use singular/plural correctly', () {
        expect(Now.weeksFromNow(1), equals(r'$NOW(+1 week)'));
        expect(Now.weeksFromNow(4), equals(r'$NOW(+4 weeks)'));
      });

      test('monthsFromNow should use singular/plural correctly', () {
        expect(Now.monthsFromNow(1), equals(r'$NOW(+1 month)'));
        expect(Now.monthsFromNow(6), equals(r'$NOW(+6 months)'));
      });

      test('yearsFromNow should use singular/plural correctly', () {
        expect(Now.yearsFromNow(1), equals(r'$NOW(+1 year)'));
        expect(Now.yearsFromNow(5), equals(r'$NOW(+5 years)'));
      });
    });

    group('Named constants', () {
      test('yesterday should be 1 day ago', () {
        expect(Now.yesterday, equals(r'$NOW(-1 day)'));
      });

      test('tomorrow should be 1 day from now', () {
        expect(Now.tomorrow, equals(r'$NOW(+1 day)'));
      });

      test('lastWeek should be 1 week ago', () {
        expect(Now.lastWeek, equals(r'$NOW(-1 week)'));
      });

      test('nextWeek should be 1 week from now', () {
        expect(Now.nextWeek, equals(r'$NOW(+1 week)'));
      });

      test('lastMonth should be 1 month ago', () {
        expect(Now.lastMonth, equals(r'$NOW(-1 month)'));
      });

      test('nextMonth should be 1 month from now', () {
        expect(Now.nextMonth, equals(r'$NOW(+1 month)'));
      });

      test('lastYear should be 1 year ago', () {
        expect(Now.lastYear, equals(r'$NOW(-1 year)'));
      });

      test('nextYear should be 1 year from now', () {
        expect(Now.nextYear, equals(r'$NOW(+1 year)'));
      });

      test('oneHourAgo should be 1 hour ago', () {
        expect(Now.oneHourAgo, equals(r'$NOW(-1 hour)'));
      });

      test('oneHourFromNow should be 1 hour from now', () {
        expect(Now.oneHourFromNow, equals(r'$NOW(+1 hour)'));
      });
    });

    group('Integration with Filter', () {
      test('should work with Filter.field().greaterThan()', () {
        final filter = Filter.field('created_at').greaterThan(Now.daysAgo(7));
        final json = filter.toJson();
        expect(
          json,
          equals({
            'created_at': {'_gt': r'$NOW(-7 days)'},
          }),
        );
      });

      test('should work with Filter.field().lessThan()', () {
        final filter = Filter.field('expires_at').lessThan(Now.value);
        final json = filter.toJson();
        expect(
          json,
          equals({
            'expires_at': {'_lt': r'$NOW'},
          }),
        );
      });

      test('should work with Filter.field().between()', () {
        final filter = Filter.field(
          'event_date',
        ).between(Now.daysAgo(30), Now.daysFromNow(30));
        final json = filter.toJson();
        expect(
          json,
          equals({
            'event_date': {
              '_between': [r'$NOW(-30 days)', r'$NOW(+30 days)'],
            },
          }),
        );
      });

      test('should work in complex filter', () {
        final filter = Filter.and([
          Filter.field('status').equals('active'),
          Filter.field('created_at').greaterThan(Now.lastMonth),
          Filter.field('expires_at').greaterThan(Now.value),
        ]);
        final json = filter.toJson();
        expect(
          json,
          equals({
            '_and': [
              {
                'status': {'_eq': 'active'},
              },
              {
                'created_at': {'_gt': r'$NOW(-1 month)'},
              },
              {
                'expires_at': {'_gt': r'$NOW'},
              },
            ],
          }),
        );
      });
    });
  });

  group('DynamicVar', () {
    test('now should return \$NOW', () {
      expect(DynamicVar.now, equals(r'$NOW'));
    });

    test('currentTimestamp should return \$NOW', () {
      expect(DynamicVar.currentTimestamp, equals(r'$NOW'));
    });

    test('currentUser should return \$CURRENT_USER', () {
      expect(DynamicVar.currentUser, equals(r'$CURRENT_USER'));
    });

    test('currentRole should return \$CURRENT_ROLE', () {
      expect(DynamicVar.currentRole, equals(r'$CURRENT_ROLE'));
    });

    test('currentPolicies should return \$CURRENT_POLICIES', () {
      expect(DynamicVar.currentPolicies, equals(r'$CURRENT_POLICIES'));
    });
  });
}
