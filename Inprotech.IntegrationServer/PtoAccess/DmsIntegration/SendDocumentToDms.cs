using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration;

namespace Inprotech.IntegrationServer.PtoAccess.DmsIntegration
{
    public interface IMoveDocumentToDmsFolder
    {
        Task MoveToDms(int caseId, int docId);
    }

    public class MoveDocumentToDmsFolder : IMoveDocumentToDmsFolder
    {
        readonly IResolveDmsLocationForDataSourceType _locationResolver;
        readonly IWriteDocumentAndMetadataToDestination _documentWriter;
        readonly IBuildXmlMetadata _metadataBuilder;
        readonly IFileHelpers _fileHelpers;
        readonly ILoadCaseAndDocuments _loader;
        readonly IResolveStorageLocationForPtoAccessDocument _docStorageLocationResolver;

        public MoveDocumentToDmsFolder(IResolveDmsLocationForDataSourceType locationResolver,
            IWriteDocumentAndMetadataToDestination documentWriter,
            IBuildXmlMetadata metadataBuilder, IFileHelpers fileHelpers,
            ILoadCaseAndDocuments loader,
            IResolveStorageLocationForPtoAccessDocument docStorageLocationResolver)
        {
            if (locationResolver == null) throw new ArgumentNullException("locationResolver");
            _locationResolver = locationResolver;
            if(documentWriter == null) throw new ArgumentNullException("documentWriter");
            _documentWriter = documentWriter;
            if(metadataBuilder == null) throw new ArgumentNullException("metadataBuilder");
            _metadataBuilder = metadataBuilder;
            if(fileHelpers == null) throw new ArgumentNullException("fileHelpers");
            _fileHelpers = fileHelpers;
            if(loader == null) throw new ArgumentNullException("loader");
            _loader = loader;
            if(docStorageLocationResolver == null) throw new ArgumentNullException("docStorageLocationResolver");
            _docStorageLocationResolver = docStorageLocationResolver;
        }
        
        public async Task MoveToDms(int caseId, int docId)
        {
            var caseAndDoc = _loader.GetCaseAndDocumentsFor(caseId, docId);
            var @case = caseAndDoc.Case;
            var document = caseAndDoc.Documents.Single();
            if (!@case.CorrelationId.HasValue) return;

            var destinationFilePath = _locationResolver.ResolveDestinationPath(document);
            var sourceDocumentFilePath = _docStorageLocationResolver.Resolve(document);
            
            using (var docFileStream = _fileHelpers.OpenRead(sourceDocumentFilePath))
            using (var metadata = _metadataBuilder.Build(@case.CorrelationId.Value, document))
            {
                await _documentWriter.Write(docFileStream, metadata, destinationFilePath);
            }
            _fileHelpers.DeleteFile(sourceDocumentFilePath);
        }
    }
}
