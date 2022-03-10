using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/documents")]
    public class DocumentsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public DocumentsPicklistController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        [RequiresCaseAuthorization(PropertyPath = "options.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "options.NameKey")]
        public async Task<PagedResults<DocumentPicklistItem>> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                     CommonQueryParameters queryParameters = null, string search = "", [ModelBinder(BinderType = typeof(JsonQueryBinder),
                                                                         Name = "options")]
                                                                     DocumentGenerationOptions options = null)
        {
            if (options != null)
            {
                if (options.CaseKey == null && options.NameKey == null && (options.InproDocOnly || options.PdfOnly))
                {
                    throw new ArgumentNullException(nameof(options));
                }

                if (options.Legacy && options.InproDocOnly)
                {
                    throw new ArgumentException(nameof(options));
                }
            }

            return Helpers.GetPagedResults(await MatchingItems(options, search),
                                           queryParameters,
                                           x => x.Value, x => x.Template, search);
        }

        async Task<IEnumerable<DocumentPicklistItem>> MatchingItems(DocumentGenerationOptions options, string search)
        {
            var usedByFilter = options?.CaseKey != null ? LetterConsumers.Cases : options?.NameKey != null ? LetterConsumers.Names : LetterConsumers.NotSet;
            var excludeDocumentTypeFilter = options?.Legacy == true ? LetterConsumers.InproDoc : options?.InproDocOnly == true ? LetterConsumers.DgLib : LetterConsumers.NotSet;
            var documentTypeFilter = options?.InproDocOnly == true ? DocumentType.Word : options?.PdfOnly == true ? DocumentType.PDF : DocumentType.NotSet;

            var culture = _preferredCultureResolver.Resolve();
            var availableDocs = options?.CaseKey != null
                ? from l in _dbContext.Set<Document>()
                  join c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>() on options.CaseKey.Value equals c.Id into c1
                  from c in c1.DefaultIfEmpty()
                  where (c == null || l.CountryCode == c.CountryId || l.CountryCode == null || c.CountryId == null)
                        && (c == null || l.PropertyType == c.PropertyTypeId || l.PropertyType == null || c.PropertyTypeId == null)
                  select l
                : _dbContext.Set<Document>().AsQueryable();

            if (usedByFilter != LetterConsumers.NotSet)
            {
                availableDocs = availableDocs.Where(l => (l.ConsumersMask & (int) usedByFilter) > 0);
            }

            if (excludeDocumentTypeFilter != LetterConsumers.NotSet)
            {
                availableDocs = availableDocs.Where(l => (l.ConsumersMask & (int) excludeDocumentTypeFilter) == 0);
            }

            if (documentTypeFilter != DocumentType.NotSet)
            {
                availableDocs = availableDocs.Where(l => l.DocumentType == (int) documentTypeFilter);
            }

            var documents = from document in availableDocs
                            select new
                            {
                                document.Id,
                                document.Code,
                                Name = DbFuncs.GetTranslation(document.Name, null, document.NameTId, culture),
                                document.Template,
                                document.AddAttachment
                            };

            IEnumerable<dynamic> interim;
            if (string.IsNullOrEmpty(search))
            {
                interim = documents.OrderBy(d => d.Name);
            }
            else
            {
                interim = MatchDocumentNumber(search, documents) ?? MatchDocumentCodeOrDescription(search, documents);
            }

            return interim.Select(doc => new DocumentPicklistItem(doc.Id, doc.Code, doc.Name, doc.Template) {AddAttachment = doc.AddAttachment});
        }

        IEnumerable<dynamic> MatchDocumentCodeOrDescription(string search, IEnumerable<dynamic> documents)
        {
            var i = StringComparison.CurrentCultureIgnoreCase;

            return from d in documents
                   where d.Code == search ||
                         d.Name.IndexOf(search, i) > -1 ||
                         (d.Code ?? string.Empty).IndexOf(search, i) > -1 ||
                         (d.Template ?? string.Empty).IndexOf(search, i) > -1 ||
                         d.Id.ToString().StartsWith(search)
                   orderby d.Name, d.Code, d.Template, d.Id
                   select d;
        }

        IEnumerable<dynamic> MatchDocumentNumber(string search, IEnumerable<dynamic> documents)
        {
            int id;
            IEnumerable<dynamic> result = new dynamic[0];
            if (int.TryParse(search, out id))
            {
                // only return if numeric search returns single item
                result = documents.Where(_ => _.Id == id).ToArray();
            }

            return result.Any() ? result : null;
        }

        public class DocumentGenerationOptions
        {
            public bool Legacy { get; set; }
            public bool InproDocOnly { get; set; }
            public bool PdfOnly { get; set; }
            public int? CaseKey { get; set; }
            public int? NameKey { get; set; }
        }

        public class DocumentPicklistItem
        {
            public DocumentPicklistItem(int key, string code, string description, string template)
            {
                Key = key;
                Code = code;
                Value = description;
                Template = template;
            }

            [PicklistKey]
            [DisplayName(@"Letter Number")]
            [DisplayOrder(3)]
            public int Key { get; set; }

            [DisplayName(@"Code")]
            [PicklistCode]
            [DisplayOrder(1)]
            public string Code { get; set; }

            [PicklistDescription]
            [DisplayOrder(0)]
            public string Value { get; set; }

            [DisplayName(@"Template")]
            [DisplayOrder(2)]
            public string Template { get; set; }

            public bool? AddAttachment { get; set; }

            public static DocumentPicklistItem Build(dynamic doc)
            {
                var r = new DocumentPicklistItem(doc.Id, doc.Code, doc.Name, doc.Template);
                return r;
            }
        }
    }
}