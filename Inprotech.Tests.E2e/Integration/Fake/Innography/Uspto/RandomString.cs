using System;

namespace Inprotech.Tests.E2e.Integration.Fake.Innography.Uspto
{
    public static class RandomString
    {
        const string Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        static readonly Random Rng = new Random();

        public static string Next(int size)
        {
            var buffer = new char[size];

            for (var i = 0; i < size; i++)
                buffer[i] = Chars[Rng.Next(Chars.Length)];

            return new string(buffer);
        }
    }
}