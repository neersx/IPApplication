using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Innography.PrivatePair;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public interface IDocumentDownload
    {
        Task<Activity> DownloadIfRequired(ApplicationDownload application, LinkInfo info, string serviceId);
    }

    public class DocumentDownload : IDocumentDownload
    {
        readonly IArtifactsLocationResolver _artifactsLocationResolver;
        readonly IPrivatePairService _service;
        readonly IFileSystem _fileSystem;
        readonly IFileNameExtractor _fileNameExtractor;
        readonly IDocumentValidation _documentValidation;

        public DocumentDownload(IArtifactsLocationResolver artifactsLocationResolver, IPrivatePairService service, IFileSystem fileSystem, IFileNameExtractor fileNameExtractor, IDocumentValidation documentValidation)
        {
            _artifactsLocationResolver = artifactsLocationResolver;
            _service = service;
            _fileSystem = fileSystem;
            _fileNameExtractor = fileNameExtractor;
            _documentValidation = documentValidation;
        }

        public async Task<Activity> DownloadIfRequired(ApplicationDownload application, LinkInfo info, string serviceId)
        {
            var documentName = _fileNameExtractor.AbsoluteUriName(info.Link);
            var filePath = _artifactsLocationResolver.ResolveFiles(application, documentName);

            if (info.LinkType == LinkTypes.Pdf && await _documentValidation.MarkIfAlreadyProcessed(application, info))
                return DefaultActivity.NoOperation();

            if (info.Status == "error")
            {
                throw new InnographyIntegrationException(new JObject
                {
                    { "StatusCode", new JValue((int)HttpStatusCode.NoContent) },
                    { "ReasonPhrase", info.Message },
                    { "RequestUrl", info.Link }
                });
            }

            if (!_fileSystem.Exists(filePath))
            {
                var fileData = await _service.DownloadDocumentData(serviceId, info);
                if (fileData == null)
                    throw new ArgumentException($"Downloaded document {info.Link} is invalid for service {serviceId}");
                await WriteFile(filePath, fileData);
            }

            return DefaultActivity.NoOperation();
        }

        async Task WriteFile(string filePath, byte[] data)
        {
            _fileSystem.EnsureFolderExists(filePath);
            _fileSystem.DeleteFile(filePath);

            using (var stream = _fileSystem.OpenWrite(filePath))
            {
                await stream.WriteAsync(data, 0, data.Length);
                stream.Close();
            }
        }
    }
}