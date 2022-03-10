using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace Inprotech.Web.Images
{
    public interface IImageService
    {
        ResizedImage ResizeImage(byte[] image, int? maxWidth, int? maxHeight);
    }

    public class ImageService : IImageService
    {
        public ResizedImage ResizeImage(byte[] image, int? maxWidth, int? maxHeight)
        {
            var img = Image.FromStream(new MemoryStream(image));

            if (maxWidth == null || maxHeight == null || img.Height < maxHeight && img.Width < maxWidth)
            {
                return new ResizedImage
                {
                    Image = image,
                    OriginalWidth = img.Width,
                    OriginalHeight = img.Height
                };
            }

            var scaleHeight = img.Height;
            var scaleWidth = img.Width;

            if (scaleHeight > maxHeight)
            {
                scaleHeight = maxHeight.Value;
                scaleWidth = img.Width * scaleHeight / img.Height;
            }
            if (scaleWidth > maxWidth)
            {
                scaleWidth = maxWidth.Value;
                scaleHeight = img.Height * scaleWidth / img.Width;
            }

            using (var newImage = new Bitmap(scaleWidth, scaleHeight))
            using (var graphics = Graphics.FromImage(newImage))
            {
                graphics.SmoothingMode = SmoothingMode.HighSpeed;
                graphics.PixelOffsetMode = PixelOffsetMode.HighSpeed;
                graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                graphics.DrawImage(img, new Rectangle(0, 0, scaleWidth, scaleHeight));

                var imageStream = new MemoryStream();
                newImage.Save(imageStream, ImageFormat.Png);

                return new ResizedImage
                {
                    Image = imageStream.ToArray(),
                    OriginalWidth = img.Width,
                    OriginalHeight = img.Height
                };
            }
        }
    }
}
