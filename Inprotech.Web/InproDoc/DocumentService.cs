using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using Document = Inprotech.Web.InproDoc.Dto.Document;

namespace Inprotech.Web.InproDoc
{
    public interface IDocumentService
    {
        IEnumerable<Document> ListDocuments(string culture,
                                            int documentType,
                                            int usedBy,
                                            int? notUsedBy);
    }

    public class DocumentService : IDocumentService
    {
        readonly IDbContext _dbContext;

        public DocumentService(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<Document> ListDocuments(string culture,
                                                   int documentType,
                                                   int usedBy,
                                                   int? notUsedBy)
        {
            var usedByFilter = (LetterConsumers)usedBy;
            var notUsedByFilter = notUsedBy.HasValue ? (LetterConsumers)notUsedBy : LetterConsumers.NotSet;
            var documentTypeFilter = (DocumentType)documentType;

            var availableDocs = _dbContext.Set<InprotechKaizen.Model.Documents.Document>().AsQueryable();

            if (usedByFilter != LetterConsumers.NotSet)
            {
                availableDocs = availableDocs.Where(l => (l.ConsumersMask & (int)usedByFilter) > 0);
            }

            if (notUsedByFilter != LetterConsumers.NotSet)
            {
                availableDocs = availableDocs.Where(l => (l.ConsumersMask & (int)notUsedByFilter) == 0);
            }

            if (documentTypeFilter != DocumentType.NotSet)
            {
                availableDocs = availableDocs.Where(l => l.DocumentType == (int)documentTypeFilter);
            }

            var documents = from document in availableDocs
                            join dm in _dbContext.Set<DeliveryMethod>() on document.DeliveryMethodId equals dm.Id into dm1
                            from dm in dm1.DefaultIfEmpty()
                            select new Document
                            {
                                DocumentKey = document.Id,
                                DocumentDescription = DbFuncs.GetTranslation(document.Name, null, document.NameTId, culture),
                                DocumentCode = document.Code,
                                Template = document.Template,
                                DocumentType = (DocumentType)document.DocumentType,
                                AddAttachment = document.AddAttachment ?? false,
                                ActivityTypeKey = document.ActivityType,
                                ActivityCategoryKey = document.ActivityCategory,
                                DefaultFilePath = dm == null ? string.Empty : dm.FileDestination,
                                FileDestinationSP = dm == null ? string.Empty : dm.DestinationStoredProcedure
                            };

            return documents;
        }
    }
}