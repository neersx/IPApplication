using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.IPPlatform.FileApp.Post
{
    public interface IUploadTrademarkImage
    {
        Task Upload(TrademarkImage trademarkImage, FileSettings fileSettings);
    }

    public class UploadTrademarkImage : IUploadTrademarkImage
    {
        readonly IFileApiClient _fileApiClient;
        readonly IFileImageStorageHandler _fileImageStorageHandler;

        public UploadTrademarkImage(IFileApiClient fileApiClient, IFileImageStorageHandler fileImageStorageHandler)
        {
            _fileApiClient = fileApiClient;
            _fileImageStorageHandler = fileImageStorageHandler;
        }

        public async Task Upload(TrademarkImage trademarkImage, FileSettings fileSettings)
        {
            if (trademarkImage == null) throw new ArgumentNullException(nameof(trademarkImage));
            if (fileSettings == null) throw new ArgumentNullException(nameof(fileSettings));

            var token = await _fileApiClient.Put<TrademarkImageUploadToken>(fileSettings.CasesBlobApi(trademarkImage.CaseId));

            var fileName = Uri.EscapeDataString(SafeFileName(trademarkImage.CaseReference + "-" + trademarkImage.ImageDescription) + ".png");

            var blob = _fileImageStorageHandler.Create(new Uri(token.BaseUri + "/" + fileName + token.SasToken));

            blob.Properties.ContentType = trademarkImage.ContentType;

            using (var imageStream = new MemoryStream(trademarkImage.Image))
            {
                imageStream.Position = 0;
                await blob.UploadFromStreamAsync(imageStream);
            }

            await _fileApiClient.Put<dynamic>(fileSettings.CasesBlobValidateApi(token.Uid));
        }

        static string SafeFileName(string fileName)
        {
            return Path.GetInvalidFileNameChars()
                       .Aggregate(fileName, (current, c) => current.Replace(c.ToString(), string.Empty));
        }
    }

    public class TrademarkImageUploadToken
    {
        /// <summary>
        ///     The impending id to be set to the image, e.g. imageUID
        /// </summary>
        public Guid Uid { get; set; }

        public string SasToken { get; set; }

        public string BaseUri { get; set; }
    }
}