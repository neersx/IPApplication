using System;
using System.Drawing;
using System.IO;

namespace Inprotech.Infrastructure.SearchResults.Exporters.Utils
{
    internal static class ExportUtils
    {
        public static Image ResizeImage(byte[] data, int maxWidth, int maxHeight)
        {
            Image newImage = null;
            try
            {
                using (var stream = new MemoryStream(data))
                {
                    var fullSizeImage = Image.FromStream(stream);
                    MaintainAspectRatio(ref maxWidth, ref maxHeight, fullSizeImage);
                    newImage = fullSizeImage.GetThumbnailImage(maxWidth, maxHeight, null, IntPtr.Zero);
                    ((Bitmap)newImage).SetResolution(96f, 96f);
                    fullSizeImage.Dispose();
                }
            }
            catch
            {
                // ignored
            }
            return newImage;
        }

        public static Image ByteArrayToImage(byte[] byteArrayIn)
        {
            using(var ms = new MemoryStream(byteArrayIn))
            {
                return Image.FromStream(ms);
            }
        }

        public static void MaintainAspectRatio(ref int maxWidth, ref int maxHeight, Image fullSizeImage)
        {
            if (maxHeight == 0) { maxHeight = fullSizeImage.Height; }
            if (maxWidth == 0) { maxWidth = fullSizeImage.Width; }
            int widthImage = fullSizeImage.Width;
            if (widthImage > maxWidth)
            {
                widthImage = maxWidth;
            }
            int heightImage = fullSizeImage.Height * widthImage / fullSizeImage.Width;
            if (heightImage > maxHeight)
            {
                widthImage = fullSizeImage.Width * maxHeight / fullSizeImage.Height;
                heightImage = maxHeight;
            }
            maxHeight = heightImage;
            maxWidth = widthImage;
        }

        public static Size GetImageDimensions(string imageDimension)
        {
            int[] imageSize = { 0, 0 };
            char[] separator = { 'X', 'x' };
            var imageSizeString = imageDimension.Split(separator);
            for (int i = 0; i < imageSizeString.Length && i < 2; i++)
            {
                if (! Int32.TryParse(imageSizeString[i], out imageSize[i]))
                {
                    imageSize[i] = 0;
                }
            }
            return new Size(imageSize[1], imageSize[0]);
        }
    }

    public class MinutesConverter
    {
        string Convert(string totalMinutes)
        {
            var converted = string.Empty;
            if (string.IsNullOrEmpty(totalMinutes)) return converted;

            if (int.Parse(totalMinutes) < 0)
                converted += "-";

            converted += Math.Abs(int.Parse(totalMinutes) / 60) + ":" +
                         Math.Abs(int.Parse(totalMinutes) % 60).ToString("00");

            return converted;
        }
        public string Convert(object totalMinutes)
        {
            switch (totalMinutes)
            {
                case long totalMinutesLong:
                    return Convert(totalMinutesLong.ToString());
                case int totalMinutesInt:
                    return Convert(totalMinutesInt.ToString());
                case short totalMinutesShort:
                    return Convert(totalMinutesShort.ToString());
                default:
                    return Convert(totalMinutes.ToString());
            }
        }
    }

    public class SecondsConverter
    {
        string Convert(string totalSeconds, bool showSeconds)
        {
            var converted = string.Empty;
            if (string.IsNullOrEmpty(totalSeconds)) return converted;

            if (int.Parse(totalSeconds) < 0)
                converted += "-";

            converted += Math.Floor(decimal.Parse(totalSeconds) / 3600) + ":" +
                         Math.Floor(decimal.Parse(totalSeconds) % 3600 / 60).ToString("00") + (showSeconds ? (":" +
                        (decimal.Parse(totalSeconds) % 3600 % 60).ToString("00")) : string.Empty);
                
            return converted;
        }

        public string Convert(object totalSeconds, bool showSeconds = true)
        {
            switch (totalSeconds)
            {
                case long totalSecondsLong:
                    return Convert(totalSecondsLong.ToString(), showSeconds);
                case int totalSecondsInt:
                    return Convert(totalSecondsInt.ToString(), showSeconds);
                case short totalSecondsShort:
                    return Convert(totalSecondsShort.ToString(), showSeconds);
                default:
                    return Convert(totalSeconds.ToString(), showSeconds);
            }
        }
    }
}
