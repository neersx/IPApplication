using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.DocumentGeneration
{
    public interface IRequestQueue
    {
        Task<DocGenRequest> NextRequest(Guid context);
        Task Completed(int id, string outputFileName = null);
        Task Failed(int id, string message);
    }

    public class RequestQueue : IRequestQueue
    {
        readonly IDbContext _dbContext;
        readonly IQueueItems _queueItems;

        public RequestQueue(IDbContext dbContext, IQueueItems queueItems)
        {
            _dbContext = dbContext;
            _queueItems = queueItems;
        }

        public async Task<DocGenRequest> NextRequest(Guid context)
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var currentlySupportedDocumentTypeForDeliveryMethods = new[] {KnownDocumentTypes.PdfViaReportingServices};
                var currentlySupportedSaveDraftEmailDocumentTypes = new short[] {KnownDocumentTypes.DeliveryOnly};

                /*
                 * Regarding ALTERNATE LETTER / LETTER SUBSTITUTE
                 * The ALTERNATELETTER is retrieved from a bestfit logic when DocGen processing the request letter:
                 * SELECT ALTERNATELETTER , ((isnull( convert( int, CASEID), 1000000 ) / 1000000 ) * 100000 ) +
                 * ((isnull( convert( int, ascii(CASECOUNTRYCODE)), 1000000 ) / 1000000 ) * 10000 ) +
                 * ((isnull( convert( int, NAMENO), 1000000 ) / 1000000 ) * 1000 ) +
                 * ((isnull( convert( int, CATEGORY), 1000000 ) / 1000000 ) * 100 ) +
                 * ((isnull( convert( int, INSTRUCTIONCODE), 1000000 ) / 1000000 ) * 10 ) +
                 * ((isnull( convert( int, LANGUAGE), 1000000 ) / 1000000 ) * 1 )
                 * FROM LETTERSUBSTITUTE
                 * WHERE  ( CASEID = -457 OR CASEID IS NULL )
                 * AND  (CASECOUNTRYCODE = 'AU' OR CASECOUNTRYCODE IS NULL)
                 * AND  ( NAMENO IS NULL ) AND  ( CATEGORY IS NULL ) AND  ( INSTRUCTIONCODE IS NULL ) AND  ( LANGUAGE IS NULL )
                 * AND  ( LETTERNO = -5302 )
                 * ORDER BY 2 ASC, 1 DESC
                 *
                 * When ALTERNATE LETTER is present in the ACTIVITY REQUEST it is taken as _the_ letter to be processed.
                 * The Firm must ensure settings are defined in the alternative letter as it replaces the current letter in all future
                 * processing in relation to this ACTIVITY REQUEST, and the idea of alternative letter is to handle different languages for another country.
                 *
                 * The logic below does not look at the ALTERNATE LETTER.
                 * Only Document Types 'Word' and 'Mail Merge' have letter substitute capability.
                 * Given that the Document Types 'PDF via Reporting Services' and 'Deliver Only' cannot have letter substitute defined against them, the current logic is safe, for now.
                 * */

                var request = await (from u in _queueItems.ForProcessing()
                                     join d in _dbContext.Set<Document>() on u.LetterNo equals d.Id into d1
                                     from d in d1
                                     join dm in _dbContext.Set<DeliveryMethod>() on u.DeliveryMethodId equals dm.Id into dm1
                                     from dm in dm1.DefaultIfEmpty()
                                     where currentlySupportedDocumentTypeForDeliveryMethods.Contains(d.DocumentType) ||
                                           dm != null && dm.Type == KnownDeliveryTypes.SaveDraftEmail && currentlySupportedSaveDraftEmailDocumentTypes.Contains(d.DocumentType)
                                     select new DocGenRequest
                                     {
                                         Id = u.Id,
                                         CaseId = (int) u.CaseId,
                                         WhenRequested = u.WhenRequested,
                                         SqlUser = u.SqlUser,
                                         LetterId = u.LetterNo,
                                         LetterName = d.Name,
                                         FileName = u.FileName,
                                         TemplateName = d.Template,
                                         DocumentType = d.DocumentType,
                                         DeliveryId = u.DeliveryMethodId,
                                         DeliveryType = dm == null ? (int?) null : dm.Type
                                     }).FirstOrDefaultAsync();

                if (request == null)
                {
                    return null;
                }
                
                await _queueItems.Hold(request.Id);

                tcs.Complete();

                request.Context = context;

                return request;
            }
        }

        public async Task Completed(int id, string outputFileName = null)
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                await _queueItems.Complete(id, outputFileName);
                
                tcs.Complete();
            }
        }

        public async Task Failed(int id, string message)
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                await _queueItems.Error(id, message);

                tcs.Complete();
            }
        }
    }
}