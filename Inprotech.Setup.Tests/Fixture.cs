using System;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;

namespace Inprotech.Setup.Tests
{
    public static class Fixture
    {
        const string Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        static readonly object SyncRoot = new object();
        static readonly Random Random = new Random();
        static readonly Random Rng = new Random();

        public static DateTime Monday => new DateTime(2013, 12, 2, 0, 0, 0);

        public static DateTime Tuesday => Monday.AddDays(1);

        public static int Integer()
        {
            return AcquireLockAndGenerateRandom();
        }

        public static long Long()
        {
            return Convert.ToInt64(Integer());
        }

        public static string String()
        {
            return String(null);
        }

        public static string RandomString(int size)
        {
            var buffer = new char[size];

            for (var i = 0; i < size; i++)
                buffer[i] = Chars[Rng.Next(Chars.Length)];

            return new string(buffer);
        }

        public static string String(string prefix)
        {
            return (prefix ?? "String") + AcquireLockAndGenerateRandom().ToString(CultureInfo.InvariantCulture);
        }

        public static short Short(short? maxValue = null)
        {
            return (short) AcquireLockAndGenerateRandom(maxValue ?? short.MaxValue);
        }

        public static decimal Decimal(bool allowNegative = false, byte precision = 2)
        {
            var isNegative = allowNegative;
            if (allowNegative)
            {
                isNegative = AcquireLockAndGenerateRandom(2) == 2;
            }

            return new decimal(Integer(), Integer(), Integer(), isNegative, precision);
        }

        static int AcquireLockAndGenerateRandom(int max = int.MaxValue)
        {
            lock (SyncRoot)
            {
                return Random.Next(1, max);
            }
        }

        public static string UniqueName()
        {
            return Guid.NewGuid().ToString();
        }

        public static DateTime TodayUtc()
        {
            return new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        }

        public static DateTime Today()
        {
            return new DateTime(2000, 1, 1);
        }

        public static DateTime FutureDate()
        {
            return new DateTime(2000, 2, 1);
        }

        public static DateTime PastDate()
        {
            return new DateTime(1999, 12, 1);
        }

        public static DateTime Date(string iso8601DateStr)
        {
            return DateTime.ParseExact(iso8601DateStr, "yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        public static DateTime Date()
        {
            var next = AcquireLockAndGenerateRandom(50000);
            var start = new DateTime(1995, 1, 1);
            return start.AddDays(next);
        }

        public static DateTime From(DayOfWeek day)
        {
            if (day == DayOfWeek.Sunday)
            {
                return Monday.AddDays(6);
            }

            return Monday.AddDays((int) day - 1);
        }

        public static byte[] RandomBytes(int size)
        {
            var buffer = new byte[size];
            new RNGCryptoServiceProvider().GetNonZeroBytes(buffer);
            return buffer;
        }

        public static bool Boolean()
        {
            return Convert.ToBoolean(Short() % 2);
        }

        public static T Enum<T>()
        {
            var values = typeof(T).GetEnumValues();

            var len = values.Length;

            var pos = AcquireLockAndGenerateRandom(len) - 1;

            return (T) values.GetValue(pos);
        }

        public static short EnsureUnique(this short value, params short[] existing)
        {
            var e = existing.Concat(new[] {value}).Distinct().ToArray();

            var i = AcquireLockAndGenerateRandom(short.MaxValue);

            while (e.Contains((short) i))
                i = AcquireLockAndGenerateRandom(short.MaxValue);

            return (short) i;
        }

        public static int EnsureUnique(this int value, params int[] existing)
        {
            var e = existing.Concat(new[] {value}).Distinct().ToArray();

            var i = AcquireLockAndGenerateRandom();

            while (e.Contains(i))
                i = AcquireLockAndGenerateRandom();

            return i;
        }
    }
}