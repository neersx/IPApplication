using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IDocumentForDms
    {
        Task MoveDocumentWithItsMetadata(Document document, int inprotechCaseId);
    }

    public class DocumentForDms : IDocumentForDms
    {
        readonly IResolveDmsLocationForDataSourceType _locationResolver;
        readonly IWriteDocumentAndMetadataToDestination _documentWriter;
        readonly IBuildXmlMetadata _metadataBuilder;
        readonly IFileHelpers _fileHelpers;
        readonly IResolveStorageLocationForPtoAccessDocument _docStorageLocationResolver;
        
        public DocumentForDms(
            IResolveDmsLocationForDataSourceType locationResolver,
            IWriteDocumentAndMetadataToDestination documentWriter,
            IBuildXmlMetadata metadataBuilder, 
            IFileHelpers fileHelpers,
            IResolveStorageLocationForPtoAccessDocument docStorageLocationResolver)
        {
            _locationResolver = locationResolver;
            _documentWriter = documentWriter;
            _metadataBuilder = metadataBuilder;
            _fileHelpers = fileHelpers;
            _docStorageLocationResolver = docStorageLocationResolver;
        }

        public async Task MoveDocumentWithItsMetadata(Document document, int inprotechCaseId)
        {
            if (document == null) throw new ArgumentNullException(nameof(document));
            
            var destinationFilePath = _locationResolver.ResolveDestinationPath(document);
            var sourceDocumentFilePath = _docStorageLocationResolver.Resolve(document);

            using (var docFileStream = _fileHelpers.OpenRead(sourceDocumentFilePath))
            using (var metadata = _metadataBuilder.Build(inprotechCaseId, document))
            {
                await _documentWriter.Write(docFileStream, metadata, destinationFilePath);
            }

            _fileHelpers.DeleteFile(sourceDocumentFilePath);
        }
    }
}
