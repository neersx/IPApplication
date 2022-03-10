using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using Inprotech.Contracts;
using Inprotech.Infrastructure;

namespace Inprotech.Web.BulkCaseImport
{
    public interface ICaseImportTemplates
    {
        dynamic ListAvailable();

        HttpResponseMessage Download(string template, string type);
    }

    public class CaseImportTemplates : ICaseImportTemplates
    {
        readonly IFileSystem _fileSystem;
        readonly string[] _validTypes = {"standard", "custom"};

        public CaseImportTemplates(IFileSystem fileSystem)
        {
            if (fileSystem == null) throw new ArgumentNullException(nameof(fileSystem));
            _fileSystem = fileSystem;
        }

        public dynamic ListAvailable()
        {
            return new
                   {
                       StandardTemplates = TemplatesFrom("bulkCaseImport-templates\\standard"),
                       CustomTemplates = TemplatesFrom("bulkCaseImport-templates\\custom")
                   };
        }

        public HttpResponseMessage Download(string template, string type)
        {
            if (!template.SupportedForCaseImport() || !_validTypes.Contains(type) || !_fileSystem.Exists(Path.Combine("bulkCaseImport-templates", type, template)))
            {
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.NotValidFile.ToString(), ErrorMessageFormat.None);
            }

            var result = new HttpResponseMessage(HttpStatusCode.OK)
                         {
                             Content = new StreamContent(_fileSystem.OpenRead(Path.Combine("bulkCaseImport-templates", type, template)))
                         };

            var fileName = Path.GetFileName(template);

            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.ms-excel");
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") {FileName = fileName};
            return result;
        }

        IEnumerable<string> TemplatesFrom(string path)
        {
            _fileSystem.EnsureFolderExists(path);

            return _fileSystem.Files(path, "*")
                              .Select(_ => Path.GetFileName(_))
                              .Where(_ => !string.IsNullOrWhiteSpace(_))
                              .SupportedForCaseImport();
        }
    }

    public static class CaseImportTemplatesExtension
    {
        //https://support.office.com/en-us/article/File-formats-that-are-supported-in-Excel-a28ae1d3-6d19-4180-9209-5a950d51b719

        static readonly string[] Supported =
        {
            ".xlsx",
            ".xlsm",
            ".xlsb",
            ".xltm",
            ".xltx",
            ".xlt",
            ".xls",
            ".xml", // excelml 2003
            ".xla",
            ".xlw",
            ".csv",
        };

        public static IEnumerable<string> SupportedForCaseImport(this IEnumerable<string> source)
        {
            return source
                .Where(SupportedForCaseImport)
                .OrderBy(_ => _)
                .ToArray();
        }

        public static bool SupportedForCaseImport(this string file)
        {
            if (string.IsNullOrWhiteSpace(file))
                return false;

            return Supported.Contains(Path.GetExtension(file).ToLower());
        }
    }
}