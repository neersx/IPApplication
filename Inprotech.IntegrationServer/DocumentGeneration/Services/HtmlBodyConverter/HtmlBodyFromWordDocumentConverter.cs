using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace Inprotech.IntegrationServer.DocumentGeneration.Services.HtmlBodyConverter
{
    public class HtmlBodyFromWordDocumentConverter : IHtmlBodyConverter
    {
        static readonly Dictionary<string, string> CommonImageMimeTypeMap =
            new Dictionary<string, string>
            {
                {"bmp", "image/bmp"},
                {"gif", "image/gif"},
                {"ico", "image/vnd.microsoft.icon"},
                {"jpeg", "image/jpeg"},
                {"jpg", "image/jpeg"},
                {"png", "image/png"},
                {"svg", "image/svg+xml"},
                {"tiff", "image/tiff"},
                {"tif", "image/tiff"},
                {"webp", "image/webp"}
            };

        readonly IConvertWordDocToHtml _convertWordDocToHtml;
        readonly IFileSystem _fileSystem;
        readonly Func<Guid> _guidFunc;

        readonly IBackgroundProcessLogger<HtmlBodyFromWordDocumentConverter> _logger;
        readonly ISettingsResolver _settingsResolver;
        readonly IStorageLocationResolver _storageLocationResolver;
        
        public HtmlBodyFromWordDocumentConverter(IBackgroundProcessLogger<HtmlBodyFromWordDocumentConverter> logger,
                                                 ISettingsResolver settingsResolver,
                                                 IConvertWordDocToHtml convertWordDocToHtml,
                                                 IStorageLocationResolver storageLocationResolver,
                                                 IFileSystem fileSystem,
                                                 Func<Guid> guidFunc)
        {
            _logger = logger;
            _settingsResolver = settingsResolver;
            _convertWordDocToHtml = convertWordDocToHtml;
            _storageLocationResolver = storageLocationResolver;
            _fileSystem = fileSystem;
            _guidFunc = guidFunc;
        }

        public Task<(string Body, IEnumerable<EmailAttachment> Attachments)> Convert(string sourceDocumentPath)
        {
            if (sourceDocumentPath == null) throw new ArgumentNullException(nameof(sourceDocumentPath));

            var settings = _settingsResolver.Resolve();

            var filePaths = Enumerable.Empty<EmailAttachment>();
            var htmlBody = settings.EmbedImagesUsing == EmbedImagesUsing.DataStream
                ? ConvertWithImagesEmbeddedInDataStream(sourceDocumentPath)
                : ConvertWithImagesEmbeddedWithContentId(sourceDocumentPath, out filePaths);

            return Task.FromResult((htmlBody, filePaths));
        }

        string ConvertWithImagesEmbeddedWithContentId(string sourceDocumentPath, out IEnumerable<EmailAttachment> filePaths)
        {
            var imagePath = _storageLocationResolver.UniqueDirectory(fileNameOrPath: "img");

            var htmlBody = _convertWordDocToHtml.Convert(sourceDocumentPath, imagePath);

            var images = new List<EmailAttachment>();

            foreach (var img in _fileSystem.Files(imagePath, "*.*"))
            {
                var base64 = System.Convert.ToBase64String(_fileSystem.ReadAllBytes(img));

                var ext = new FileInfo(img).Extension.ToLower().TrimStart('.');

                var fileAttachment = new EmailAttachment
                {
                    IsInline = true,
                    Content = base64,
                    ContentId = _guidFunc() + ext
                };

                htmlBody = htmlBody.Replace(img, "cid:" + fileAttachment.ContentId);

                images.Add(fileAttachment);
            }

            filePaths = images;

            return htmlBody;
        }

        string ConvertWithImagesEmbeddedInDataStream(string sourceDocumentPath)
        {
            var imagePath = _storageLocationResolver.UniqueDirectory(fileNameOrPath: "img");

            var htmlBody = _convertWordDocToHtml.Convert(sourceDocumentPath, imagePath);

            foreach (var img in _fileSystem.Files(imagePath, "*.*"))
            {
                var base64 = System.Convert.ToBase64String(_fileSystem.ReadAllBytes(img));

                var ext = new FileInfo(img).Extension.ToLower().TrimStart('.');

                if (!CommonImageMimeTypeMap.TryGetValue(ext, out var mimeType))
                {
                    _logger.Warning($"Conversion to HTML from {sourceDocumentPath} - encountered unknown {ext} for MIMETYPE conversion");
                    mimeType = "image/" + ext;
                }

                htmlBody = htmlBody.Replace(img, $"data:{mimeType};base64, {base64}");
            }

            return htmlBody;
        }
    }
}