using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IComparisonDocumentsProvider
    {
        Task<IEnumerable<Document>> For(ApplicationDownload applicationDownload, Document[] documents);
    }

    public class ComparisonDocumentsProvider : IComparisonDocumentsProvider
    {
        readonly IBiblioStorage _biblioStorage;

        public ComparisonDocumentsProvider(IBiblioStorage biblioStorage)
        {
            _biblioStorage = biblioStorage;
        }

        public async Task<IEnumerable<Document>> For(ApplicationDownload applicationDownload, Document[] documents)
        {
            if (applicationDownload == null) throw new ArgumentNullException(nameof(applicationDownload));
            if (documents == null) throw new ArgumentNullException(nameof(documents));

            var existing = documents.Select(_ => _.DocumentObjectId).ToArray();

            return (await _biblioStorage.Read(applicationDownload))
                   .ImageFileWrappers
                   .Select(_ => _.ToAvailableDocument())
                   .Where(_ => !(existing.Contains(_.ObjectId) || existing.Contains(_.FileNameObjectId)))
                   .Select(_ => new ComparisonDocument
                   {
                       DocumentObjectId = _.FileNameObjectId ?? _.ObjectId,
                       ApplicationNumber = applicationDownload.Number,
                       DocumentCategory = _.DocumentCategory,
                       DocumentDescription = _.DocumentDescription,
                       MailRoomDate = _.MailRoomDate,
                       FileWrapperDocumentCode = _.FileWrapperDocumentCode,
                       PageCount = _.PageCount
                   })
                   .Concat(documents)
                   .OrderByDescending(_ => _.MailRoomDate);
        }
    }
}