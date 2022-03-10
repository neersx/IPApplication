using System;
using System.IO;
using System.Text;
using Aspose.Words;
using Aspose.Words.Saving;

namespace Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public interface IConvertWordDocToHtml
    {
        string Convert(string filePath, string imagesFolder);
    }

    public class ConvertWordDocToHtml : IConvertWordDocToHtml
    {
        public string Convert(string filePath, string imagesFolder)
        {
            if (filePath == null) throw new ArgumentNullException(nameof(filePath));
            if (imagesFolder == null) throw new ArgumentNullException(nameof(imagesFolder));

            var doc = new Document(filePath);

            using (var stream = new MemoryStream())
            {
                var options = new HtmlSaveOptions(SaveFormat.Html)
                {
                    ImagesFolder = imagesFolder,
                    ExportHeadersFooters = false
                };

                doc.Save(stream, options);
                var res = Encoding.UTF8.GetString(stream.ToArray());

                return res;
            }
        }
    }
}