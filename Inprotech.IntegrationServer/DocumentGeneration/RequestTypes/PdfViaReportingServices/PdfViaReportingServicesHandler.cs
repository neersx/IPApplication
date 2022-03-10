using System;
using System.Data.Entity;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using Inprotech.Integration.Reports;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.PdfViaReportingServices
{
    public class PdfViaReportingServicesHandler : IHandleDocGenRequest
    {
        readonly IDbContext _dbContext;
        readonly IDocumentGenerator _documentGenerator;
        readonly IFileSystem _fileSystem;
        readonly IBackgroundProcessLogger<PdfViaReportingServicesHandler> _logger;
        readonly IPdfReportRequestResolver _pdfReportRequestResolver;
        readonly IDeliveryDestinationResolver _deliveryDestinationResolver;
        readonly IReportClient _reportClient;
        readonly IStorageLocationResolver _storageLocationResolver;

        public PdfViaReportingServicesHandler(IBackgroundProcessLogger<PdfViaReportingServicesHandler> logger,
                                              IPdfReportRequestResolver pdfReportRequestResolver,
                                              IDeliveryDestinationResolver deliveryDestinationResolver,
                                              IStorageLocationResolver storageLocationResolver,
                                              IReportClient reportClient,
                                              IFileSystem fileSystem,
                                              IDbContext dbContext,
                                              IDocumentGenerator documentGenerator)
        {
            _logger = logger;
            _pdfReportRequestResolver = pdfReportRequestResolver;
            _deliveryDestinationResolver = deliveryDestinationResolver;
            _storageLocationResolver = storageLocationResolver;
            _reportClient = reportClient;
            _fileSystem = fileSystem;
            _dbContext = dbContext;
            _documentGenerator = documentGenerator;
        }
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);
        }
        
        public async Task<DocGenProcessResult> Handle(DocGenRequest docGenRequest)
        {
            if (docGenRequest == null) throw new ArgumentNullException(nameof(docGenRequest));

            /*
             In the special case of 'PDF via Reporting Services', the IWS behavior is to resolve a 'Report Output Path' from IWS DocGenService configuration
             The 'PDF via Reporting Services' letter type cannot have a DeliveryMethod defined and its Delivery Letter is non-mandatory.
             If the Delivery Letter's Delivery Method is defined, resolve destination output here (new behaviour) instead of Report Output Path.  
               
             For other Document Types if they have a Deliver Letter defined and is intended to be a Save as Draft Email delivery type, the initial request 
             must also have the 'Save as Draft Email' delivery type set - classic docgen server behavior. 
             Its deliver destination are also resolved in the first request rather than in the subsequent request.

             For the sake of behaviour consistency, deliver destination are resolved in the first request.
             */

            var deliverLetter = await (from next in _dbContext.Set<Document>()
                                       join current in _dbContext.Set<Document>() on next.Id equals current.DeliverLetterId into c1
                                       from current in c1
                                       where current.Id == docGenRequest.LetterId
                                       select new
                                       {
                                           next.Id,
                                           next.DeliveryMethodId
                                       }).SingleOrDefaultAsync();
            
            var reportDefinition = await _pdfReportRequestResolver.Resolve(docGenRequest);

            var destination = await _deliveryDestinationResolver.Resolve(docGenRequest.Id, 
                                                                         docGenRequest.CaseId, 
                                                                         deliverLetter?.Id ?? docGenRequest.LetterId.GetValueOrDefault());

            if (string.IsNullOrWhiteSpace(destination.FileName))
            {
                destination.FileName = KnownReportComponents.GetFileNameFromReportDefinition(reportDefinition);
            }

            if (string.IsNullOrWhiteSpace(destination.DirectoryName))
            {
                destination.DirectoryName = _storageLocationResolver.UniqueDirectory(fileNameOrPath: "reporting-services");
            }
          
            var output = Path.Combine(destination.DirectoryName, destination.FileName);
            
            _logger.Trace($"Output resolved to {output}");

            using (var ms = _fileSystem.OpenWrite(output, true))
            {
                var contentResult = await _reportClient.GetReportAsync(reportDefinition, ms);

                if (contentResult.HasError)
                {
                    _logger.Warning($"Docgen Request ({docGenRequest.Id}) {docGenRequest.LetterName} production failed with '{contentResult.Exception.Message}'");

                    return new DocGenProcessResult
                    {
                        ErrorMessage = contentResult.Exception.Message,
                        Result = KnownStatuses.Failed
                    };
                }

                _logger.Trace($"PDF generated to {output}");
            }

            if (deliverLetter != null)
            {
                using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
                {
                    _logger.Trace("Enqueue PDF via Reporting Services deliver request");

                    await _documentGenerator.QueueDocument(docGenRequest.Id, (current, next) =>
                    {
                        next.LetterNo = deliverLetter.Id;
                        next.DeliveryMethodId = deliverLetter.DeliveryMethodId;
                        next.FileName = output;
                    });

                    tcs.Complete();
                }
            }
            else
            {
                _logger.Trace($"No delivery letter found for {docGenRequest.Id}.");
            }

            return new DocGenProcessResult 
            { 
                FileName = output, 
                Result = KnownStatuses.Success
            };
        }
    }
}