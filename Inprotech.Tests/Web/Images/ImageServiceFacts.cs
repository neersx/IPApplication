using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using Inprotech.Web.Images;
using Xunit;

namespace Inprotech.Tests.Web.Images
{
    public class ImageServiceFacts
    {
        static byte[] GetPngData(int width, int height)
        {
            // generate image
            var image = new Bitmap(width, height);
            var imageData = Graphics.FromImage(image);
            imageData.DrawLine(new Pen(Color.Beige), 0, 0, width, height);

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

        [Fact]
        public void DoesNotResizeIfImageFitsWithinConstraints()
        {
            var f = new ImageServiceFixture();
            var image = GetPngData(100, 100);
            var result = f.Subject.ResizeImage(image, 100, 100);
            Assert.Equal(image, result.Image);
            Assert.Equal(100, result.OriginalWidth);
            Assert.Equal(100, result.OriginalHeight);
        }

        [Fact]
        public void ResizesTheImageHeightIfItDoesntFit()
        {
            var f = new ImageServiceFixture();
            var image = GetPngData(50, 100);
            var result = f.Subject.ResizeImage(image, 50, 50);
            var resultImage = Image.FromStream(new MemoryStream(result.Image));

            Assert.Equal(50, resultImage.Height);
            Assert.Equal(25, resultImage.Width);
            Assert.Equal(100, result.OriginalHeight);
            Assert.Equal(50, result.OriginalWidth);
        }

        [Fact]
        public void ResizesTheImageWidthIfItDoesntFit()
        {
            var f = new ImageServiceFixture();
            var image = GetPngData(100, 50);
            var result = f.Subject.ResizeImage(image, 50, 50);
            var resultImage = Image.FromStream(new MemoryStream(result.Image));

            Assert.Equal(50, resultImage.Width);
            Assert.Equal(25, resultImage.Height);
            Assert.Equal(100, result.OriginalWidth);
            Assert.Equal(50, result.OriginalHeight);
        }

        [Fact]
        public void ResizesWidthAndHeightIfItDoesntFit()
        {
            var f = new ImageServiceFixture();
            var image = GetPngData(200, 100);
            var result = f.Subject.ResizeImage(image, 50, 50);
            var resultImage = Image.FromStream(new MemoryStream(result.Image));

            Assert.Equal(50, resultImage.Width);
            Assert.Equal(25, resultImage.Height);
            Assert.Equal(200, result.OriginalWidth);
            Assert.Equal(100, result.OriginalHeight);
        }
    }

    public class ImageServiceFixture : IFixture<ImageService>
    {
        public ImageServiceFixture()
        {
            Subject = new ImageService();
        }

        public ImageService Subject { get; }
    }
}