using System;
using System.IO;
using System.Text;
using Aspose.Pdf;

namespace Inprotech.Web.Accounting.VatReturns
{
    public interface IPdfDocument
    {
        void Generate(Stream stream, string title, string templateContent);
    }

    public class PdfDocument : IPdfDocument
    {
        public void Generate(Stream stream, string title, string templateContent)
        {
            if (string.IsNullOrWhiteSpace(templateContent)) throw new ArgumentException("message", nameof(templateContent));

            byte[] inputBytes = Encoding.UTF8.GetBytes(templateContent);
            var inputStream = new MemoryStream(inputBytes);
            var doc = new Document(inputStream, new HtmlLoadOptions());

            doc.Info.Title = title;
            doc.Save(stream, SaveFormat.Pdf);
        }
    }
}