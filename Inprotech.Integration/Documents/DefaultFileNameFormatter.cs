using System;

namespace Inprotech.Integration.Documents
{
    public interface IDefaultFileNameFormatter
    {
        string Format(Document document);
    }

    public class DefaultFileNameFormatter : IDefaultFileNameFormatter
    {
        public string Format(Document document)
        {
            if(document == null) throw new ArgumentNullException("document");

            return string.Format(
                                 "{0:yyyyMMdd} {1}{2}" + document.FileExtension(),
                                 document.MailRoomDate,
                                 document.DocumentDescription,
                                 PageCountFormat(document.PageCount));
        }

        static string PageCountFormat(int? pageCount)
        {
            if(pageCount == null || pageCount == 1) return string.Empty;

            return string.Format(" ({0} pages)", pageCount);
        }
    }
}