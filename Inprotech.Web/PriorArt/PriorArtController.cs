using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class PriorArtController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IEvidenceImporter _evidenceImporter;
        readonly IExistingPriorArtMatchBuilder _existingPriorArtMatchBuilder;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IPriorArtMaintenanceValidator _priorArtMaintenanceValidator;
        readonly ISubjectSecurityProvider _subjectSecurity;

        public PriorArtController(IDbContext dbContext, IExistingPriorArtMatchBuilder existingPriorArtMatchBuilder, IEvidenceImporter evidenceImporter,
                                  ITaskSecurityProvider taskSecurityProvider, IPriorArtMaintenanceValidator priorArtMaintenanceValidator, ISubjectSecurityProvider subjectSecurity)
        {
            _dbContext = dbContext;
            _existingPriorArtMatchBuilder = existingPriorArtMatchBuilder;
            _evidenceImporter = evidenceImporter;
            _taskSecurityProvider = taskSecurityProvider;
            _priorArtMaintenanceValidator = priorArtMaintenanceValidator;
            _subjectSecurity = subjectSecurity;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("api/priorart")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        public dynamic Get(int? sourceId = null, int? caseKey = null)
        {
            var priorArtSearchViewModel = new PriorArtSearchViewModel
            {
                PriorArtSourceTableCodes = _dbContext.Set<TableCode>()
                                                     .Where(_ => _.TableTypeId == (short) TableTypes.PriorArtSource)
                                                     .Select(_ => new TableCodeItem {Id = _.Id, Name = _.Name})
                                                     .OrderBy(_ => _.Name).ToList()
            };
            priorArtSearchViewModel.HasUpdatePermission = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Modify);
            priorArtSearchViewModel.HasDeletePermission = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Delete);
            priorArtSearchViewModel.CanMaintainAttachment = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment);
            priorArtSearchViewModel.CanViewAttachment = _subjectSecurity.HasAccessToSubject(ApplicationSubject.Attachments);
            if (!sourceId.HasValue && !caseKey.HasValue) return priorArtSearchViewModel;

            if (sourceId.HasValue)
            {
                var priorArtSource = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                               .SingleOrDefault(pa => pa.Id == sourceId);

                if (priorArtSource == null) throw Exceptions.NotFound("Source not found.");

                if (caseKey.HasValue)
                {
                    var isSourceRelatedToSource = priorArtSource.CaseSearchResult.Count(c => c.CaseId == caseKey);
                    if (isSourceRelatedToSource == 0)
                    {
                        throw Exceptions.NotFound("Source not found within the requested case.");
                    }
                }

                var sourceDocumentModel = new SourceDocumentModel(priorArtSource);
                priorArtSearchViewModel.SourceDocumentData = sourceDocumentModel;
            }

            if (caseKey.HasValue)
            {
                var priorArtCaseReference = _dbContext.Set<Case>()
                                                      .SingleOrDefault(c => c.Id == caseKey);
                if (priorArtCaseReference == null) throw Exceptions.NotFound("Case not found.");
                priorArtSearchViewModel.CaseIrn = priorArtCaseReference.Irn;
            }

            priorArtSearchViewModel.CaseKey = caseKey;

            return priorArtSearchViewModel;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("api/priorart/priorArtTranslations")]
        public dynamic GetPriorArtTranslations()
        {
            return _existingPriorArtMatchBuilder.GetPriorArtTranslations();
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/includeinsourcedocument")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        public async Task<Match> IncludeInSourceDocument(ExistingPriorArtMatch model, int? caseKey)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            var priorArtId = Convert.ToInt32(model.Id);

            if (model.SourceDocumentId != null) 
            {
                if (model.SourceDocumentId == priorArtId)
                {
                    throw Exceptions.BadRequest("Cannot link a source document to self.");
                }

                var priorArtAndSourceDocument = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                                                          .Include(pa => pa.CitedPriorArt)
                                                          .Include(pa => pa.SourceDocuments)
                                                          .Where(
                                                                 pa =>
                                                                     pa.Id == model.SourceDocumentId || pa.Id == priorArtId);

                if (priorArtAndSourceDocument.Count() != 2)
                {
                    throw Exceptions.BadRequest("Either source document or prior art provided is invalid");
                }

                var sourceDocument = priorArtAndSourceDocument.Single(s => s.Id == model.SourceDocumentId);
                var priorArt = priorArtAndSourceDocument.Single(pa => pa.Id == priorArtId);

                if (!sourceDocument.IsSourceDocument) throw Exceptions.BadRequest("Not a source document.");
                if (priorArt.IsSourceDocument) throw Exceptions.BadRequest("Not a prior art.");
                if (sourceDocument.CitedPriorArt.Any(cpa => cpa.Id == priorArtId))
                {
                    throw Exceptions.BadRequest("Prior art already cited in the source document.");
                }

                sourceDocument.CitedPriorArt.Add(priorArt);

                await _dbContext.SaveChangesAsync();

                if (caseKey.HasValue)
                {
                    _evidenceImporter.AssociatePriorArtWithCase(priorArt, caseKey.Value);
                }

                return _existingPriorArtMatchBuilder.Build(
                                                           priorArt,
                                                           model.SourceDocumentId,
                                                           sourceDocument.CitedPriorArt.Any(cpa => cpa == priorArt), new SearchResultOptions(), null, caseKey);
            }
            else
            {
                var priorArt = _dbContext
                               .Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                               .Include(
                                        pa => pa.CitedPriorArt).Single(pa => pa.Id == priorArtId);

                if (priorArt.IsSourceDocument) throw Exceptions.BadRequest("Not a prior art.");

                if (caseKey.HasValue)
                {
                    _evidenceImporter.AssociatePriorArtWithCase(priorArt, caseKey.Value);
                }

                return _existingPriorArtMatchBuilder.Build(
                                                           priorArt,
                                                           model.SourceDocumentId, caseKey.HasValue, new SearchResultOptions(), null, caseKey);
            }
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/editexisting")]
        public async Task<dynamic> EditExisting(ExistingPriorArtMatch model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var priorArtId = Convert.ToInt32(model.Id);
                var priorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().SingleOrDefault(pa => pa.Id == priorArtId);

                if (priorArt != null)
                {
                    priorArt.Abstract = model.Abstract;
                    priorArt.Title = model.Title;
                    priorArt.Citation = model.Citation;
                    priorArt.Name = model.Name;
                    priorArt.City = model.City;
                    priorArt.Publisher = model.Publisher;
                    priorArt.CountryId = model.CountryCode;
                    priorArt.Kind = model.Kind;
                    priorArt.RefDocumentParts = model.RefDocumentParts;
                    priorArt.Description = model.Description;
                    priorArt.Translation = model.Translation;
                    priorArt.PublishedDate = model.PublishedDate;
                    priorArt.PriorityDate = model.PriorityDate;
                    priorArt.GrantedDate = model.GrantedDate;
                    priorArt.PtoCitedDate = model.PtoCitedDate;
                    priorArt.ApplicationFiledDate = model.ApplicationDate;
                    priorArt.Comments = model.Comments;
                }

                await _dbContext.SaveChangesAsync();
                tx.Complete();

                return new {Result = "success"};
            }
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/create")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "model.CaseKey")]
        public async Task Create(PriorArtModel model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));

            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var source = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().SingleOrDefault(pa => pa.Id == model.SourceId);
                var country = _dbContext.Set<Country>().SingleOrDefault(c => c.Id == model.CountryCode);
                var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt(model.OfficialNumber, country, model.Kind)
                {
                    Title = model.Title,
                    Abstract = model.Abstract,
                    Citation = model.Citation,
                    Name = model.Name,
                    RefDocumentParts = model.RefDocumentParts,
                    Translation = model.Translation,
                    PublishedDate = model.PublishedDate,
                    PriorityDate = model.PriorityDate,
                    GrantedDate = model.GrantedDate,
                    PtoCitedDate = model.PtoCitedDate,
                    ApplicationFiledDate = model.ApplicationFiledDate,
                    IsIpDocument = !model.IsLiterature,
                    CorrelationId = model.CorrelationId,
                    ImportedFrom = model.ImportedFrom,
                    Comments = model.Comments,
                    Description = model.Description,
                    Publisher = model.Publisher,
                    City = model.City
                };

                source?.CitedPriorArt.Add(priorArt);

                _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Add(priorArt);
                await _dbContext.SaveChangesAsync();

                if (model.CaseKey.HasValue)
                {
                    _evidenceImporter.AssociatePriorArtWithCase(priorArt, model.CaseKey.Value);
                }

                tx.Complete();
            }
        }

        [HttpGet]
        [Route("api/priorart/exists")]
        public bool ExistingPriorArt(string countryCode, string officialNumber, string kindCode)
        {
            return _priorArtMaintenanceValidator.ExistingPriorArt(countryCode, officialNumber, kindCode);
        }

        [HttpGet]
        [Route("api/priorart/literatureexists")]
        public bool ExistingLiterature(string description, string name, string title, string refDocumentParts, string publisher, string city, string countryCode)
        {
            return _priorArtMaintenanceValidator.ExistingLiterature(description, name, title, refDocumentParts, publisher, city, countryCode);
        }

        [HttpPost]
        [AppliesToComponent(KnownComponents.PriorArt)]
        [Route("api/priorart/report-citation")]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "request.CaseId")]
        public async Task CiteSourceDocument(SourceCitationRequest request)
        {
            var source = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().SingleOrDefault(_ => _.Id == request.SourceId && _.IsSourceDocument);
            if (source == null) throw Exceptions.BadRequest("Source Document does not exist.");

            using (var tx = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {   
                if (request.PriorArtId.HasValue)
                {
                    var citedPriorArt = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().SingleOrDefault(_ => _.Id == request.PriorArtId && !_.IsSourceDocument);
                    source.CitedPriorArt.Add(citedPriorArt);
                }
                else
                {
                    if (request.CaseId.HasValue)
                    {
                        var caseSearchResult = new CaseSearchResult(request.CaseId.Value, source.Id, true) {CaseFirstLinkedTo = true};
                        _dbContext.Set<CaseSearchResult>().Add(caseSearchResult);
                    }
                }
                await _dbContext.SaveChangesAsync();

                tx.Complete();
            }
        }

        public class SourceCitationRequest
        {
            public int SourceId { get; set; }
            public int? PriorArtId { get; set; }
            public int? CaseId { get; set; }
        }
    }
}