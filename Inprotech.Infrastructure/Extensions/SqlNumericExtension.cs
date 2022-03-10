namespace Inprotech.Infrastructure.Extensions
{
    public static class SqlNumericExtension
    {
        public static string PadRight(this int numeric, int charCount, char padWith = ' ')
        {
            return InnerPadRight(numeric, charCount, padWith);
        }

        public static string PadRight(this int? numeric, int charCount, char padWith = ' ')
        {
            return InnerPadRight(numeric, charCount, padWith);
        }

        public static string PadRight(this short numeric, int charCount, char padWith = ' ')
        {
            return InnerPadRight(numeric, charCount, padWith);
        }

        public static string PadRight(this short? numeric, int charCount, char padWith = ' ')
        {
            return InnerPadRight(numeric, charCount, padWith);
        }

        static string InnerPadRight(int? numeric, int charCount, char padWith = ' ')
        {
            return numeric.HasValue
                ? numeric.ToString().PadRight(charCount, padWith)
                : string.Empty.PadRight(charCount, padWith);
        }
    }
}