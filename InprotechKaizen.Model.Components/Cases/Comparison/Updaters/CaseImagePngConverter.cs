using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IConvertImagesToPng
    {
        Stream Convert(Stream source);
    }

    public class CaseImagePngConverter : IConvertImagesToPng
    {
        public Stream Convert(Stream source)
        {
            var bm = Image.FromStream(source);
            var ms = new MemoryStream();
            bm.Save(ms, ImageFormat.Png);
            ms.Position = 0;
            return ms;
        }
    }
}