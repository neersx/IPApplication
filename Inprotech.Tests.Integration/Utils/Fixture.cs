using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Inprotech.Tests.Integration.Utils
{
    internal static class Fixture
    {
        static readonly object SyncRoot = new object();
        static readonly Random Rand = new Random();
        static readonly char[] ExtendedCharSet;
        static readonly char[] CharSet;
        static readonly char[] UriSafeCharSet;
        static readonly char[] AlphaNumericCharSet;
        static readonly char[] AlphaOnlyCharSet;

        static Fixture()
        {
            var list = new List<char>();
            for (int i = char.MinValue; i <= char.MaxValue; i++)
            {
                var c = Convert.ToChar(i);
                if (char.IsLetterOrDigit(c))
                    list.Add(c);

                if (list.Count >= 512)
                    break;
            }

            ExtendedCharSet = list.ToArray();
            CharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`1234567890-=~!@#$%^&*()_+[];',./{}:\"<>?\\".ToArray();
            UriSafeCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~[]@!$'()*+,`.".ToArray();
            AlphaNumericCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".ToArray();
            AlphaOnlyCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToArray();
        }

        internal static DateTime Today()
        {
            return new DateTime(2000, 1, 1);
        }

        internal static DateTime PastDate()
        {
            return new DateTime(1999, 1, 1);
        }

        internal static string DateStringFromToday(int add = 0)
        {
            return DateTime.Today.AddDays(add).ToString("yyyy-MM-dd");
        }

        internal static string Prefix(string str = null, Type type = null)
        {
            if (str == null)
                str = string.Empty;

            if (type == null)
            {
                var stackTrace = new StackTrace();
                type = stackTrace.GetFrame(1).GetMethod().DeclaringType;
            }

            return $"#{Hash(type.FullName).Substring(0, 5)}_{str}";
        }

        internal static string String(int length, int lines = 1)
        {
            var chars = length <= 2 ? ExtendedCharSet : CharSet;

            return string.Join($"{Environment.NewLine}", Enumerable.Repeat(new string(Enumerable.Repeat(chars, length)
                                                   .Select(s => s[Rand.Next(s.Length)]).ToArray()), lines));
        }

        internal static string UriSafeString(int length)
        {
            var chars = length <= 2 ? ExtendedCharSet : UriSafeCharSet;
            
            return new string(Enumerable.Repeat(chars, length)
                                        .Select(s => s[Rand.Next(s.Length)]).ToArray());
        }

        internal static string AlphaNumericString(int length, IEnumerable<string> ignores = null)
        {
            for (var i = 0; i < 62; i++)
            {
                var output = new string(Enumerable.Repeat(AlphaNumericCharSet, length)
                                                  .Select(s => s[Rand.Next(s.Length)]).ToArray());

                if (ignores == null)
                    return output;

                if (ignores.Contains(output) == false)
                    return output;
            }

            return null;
        }
        
        internal static string String(int length, IEnumerable<string> ignores)
        {
            const int maxRetry = 256;

            for (var i = 0; i < maxRetry; i++)
            {
                var output = String(length);
                if (ignores.Contains(output) == false)
                    return output;
            }

            return null;
        }
        
        internal static int Integer()
        {
            return AcquireLockAndGenerateRandom();
        }

        internal static short Short(short? maxValue = null)
        {
            return (short) AcquireLockAndGenerateRandom(maxValue ?? short.MaxValue);
        }

        public static bool Boolean()
        {
            return Convert.ToBoolean(Short() % 2);
        }

        internal static byte[] Image(int width, int height, Color colour)
        {
            // generate image
            var image = new Bitmap(width, height);
            var imageData = Graphics.FromImage(image);
            imageData.DrawLine(new Pen(colour), 0, 0, width, height);

            //Convert to byte array
            var memoryStream = new MemoryStream();
            byte[] bitmapData;

            using (memoryStream)
            {
                image.Save(memoryStream, ImageFormat.Png);
                bitmapData = memoryStream.ToArray();
            }
            return bitmapData;
        }

        static string Hash(string input)
        {
            using (var sha1 = new SHA1Managed())
            {
                var hash = sha1.ComputeHash(Encoding.UTF8.GetBytes(input));
                var sb = new StringBuilder(hash.Length*2);

                foreach (var b in hash)
                {
                    sb.Append(b.ToString("x2"));
                }

                return sb.ToString();
            }
        }

        static int AcquireLockAndGenerateRandom(int max = int.MaxValue)
        {
            lock (SyncRoot)
                return Rand.Next(1, max);
        }
    }
}