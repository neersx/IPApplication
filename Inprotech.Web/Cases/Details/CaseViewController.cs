using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Cases.Details
{
    public class CaseViewPermissionsData
    {
        public bool DisplayRichTextFormat { get; set; }
        public bool CanViewOtherNumbers { get; set; }
        public bool KeepSpecHistory { get; set; }
        public bool CanMaintainCase { get; set; }
        public bool CanRequestCaseFile { get; set; }
        public bool CanCreateCaseFile { get; set; }
        public bool CanUpdateCaseFile { get; set; }
        public bool CanDeleteCaseFile { get; set; }
        public int FileLocationWhenMoved { get; set; }
        public int NameId { get; set; }
        public string DisplayName { get; set; }
        public bool CanGenerateWordDocument { get; set; }
        public bool CanGeneratePdfDocument { get; set; }
        public bool CanViewCaseAttachments { get; set; }
        public bool CanAccessDocumentsFromDms { get; set; }
    }

    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IImportanceLevelResolver _importanceLevelResolver;
        readonly IEventNotesResolver _eventNotesResolver;
        readonly IConfigurationSettings _appSettings;
        readonly ICaseEmailTemplate _caseEmailTemplate;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IListPrograms _listCasePrograms;
        readonly ISubjectSecurityProvider _subjectSecurityProvider;
        readonly ICaseAuthorization _caseAuthorization;

        public CaseViewController(ISecurityContext securityContext,
                                  ISiteControlReader siteControlReader,
                                  IImportanceLevelResolver importanceLevelResolver,
                                  IEventNotesResolver eventNotesResolver,
                                  IConfigurationSettings appSettings,
                                  ICaseEmailTemplate caseEmailTemplate,
                                  ITaskSecurityProvider taskSecurityProvider,
                                  IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IListPrograms listCasePrograms,
                                  ISubjectSecurityProvider subjectSecurityProvider, 
                                  ICaseAuthorization caseAuthorization)
        {
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
            _importanceLevelResolver = importanceLevelResolver;
            _eventNotesResolver = eventNotesResolver;
            _appSettings = appSettings;
            _caseEmailTemplate = caseEmailTemplate;
            _taskSecurityProvider = taskSecurityProvider;
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _listCasePrograms = listCasePrograms;
            _subjectSecurityProvider = subjectSecurityProvider;
            _caseAuthorization = caseAuthorization;
        }

        [HttpGet]
        [Route("caseview")]
        public async Task<CaseViewPermissionsData> GetCaseViewPermissions()
        {
            return new CaseViewPermissionsData
            {
                DisplayRichTextFormat = _siteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting),
                CanViewOtherNumbers = !_securityContext.User.IsExternalUser || !string.IsNullOrEmpty(_siteControlReader.Read<string>(SiteControls.ClientNumberTypesShown)),
                KeepSpecHistory = _siteControlReader.Read<bool?>(SiteControls.KEEPSPECIHISTORY) ?? true,
                CanMaintainCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify),
                CanRequestCaseFile = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking) && _siteControlReader.Read<bool>(SiteControls.RFIDSystem),
                CanCreateCaseFile = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Create),
                CanUpdateCaseFile = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Modify),
                CanDeleteCaseFile = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Delete),
                FileLocationWhenMoved = _siteControlReader.Read<int>(SiteControls.FileLocationWhenMoved),
                NameId = _securityContext.User.Name.Id,
                DisplayName = _securityContext.User.Name.FormattedWithDefaultStyle(),
                CanGenerateWordDocument = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateMsWordDocument),
                CanGeneratePdfDocument = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreatePdfDocument) && _siteControlReader.Read<bool>(SiteControls.PDFFormFilling),
                CanViewCaseAttachments = _subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments),
                CanAccessDocumentsFromDms = _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms)
            };
        }

        [HttpGet]
        [Route("importance-levels-note-types")]
        public async Task<dynamic> GetCaseImportanceLevelsAndNoteTypes()
        {
            var defaultImportanceLevel = _importanceLevelResolver.Resolve();
            var importanceLevelOptions = (await _importanceLevelResolver.GetImportanceLevels()).Select(_ => new
            {
                Code = _.LevelNumeric,
                _.Description
            });

            if (_securityContext.User.IsExternalUser)
            {
                importanceLevelOptions = importanceLevelOptions.Where(_ => _.Code >= defaultImportanceLevel);
            }

            return new
            {
                ImportanceLevel = defaultImportanceLevel,
                ImportanceLevelOptions = importanceLevelOptions.OrderByDescending(_ => _.Code),
                RequireImportanceLevel = _securityContext.User.IsExternalUser,
                EventNoteTypes = _eventNotesResolver.EventNoteTypesWithDefault(),
                CanAddCaseAttachments = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create)
            };
        }

        [HttpGet]
        [Route("caseId")]
        public async Task<int> GetCaseReference(string caseRef)
        {
            if (string.IsNullOrWhiteSpace(caseRef)) throw new ArgumentException("Value cannot be null or whitespace.", nameof(caseRef));

            var @case = _dbContext.Set<Case>().SingleOrDefault(_ => _.Irn == caseRef.Trim());

            if (@case == null)
            {
                throw new InvalidOperationException("Case not found or update case permission not available");
            }

            var hasPermission = await _caseAuthorization.Authorize(@case.Id, AccessPermissionLevel.Select);

            if (!hasPermission.Exists)
            {
                throw new InvalidOperationException("Case not found or update case permission not available");
            }

            if (hasPermission.IsUnauthorized)
            {
                throw new DataSecurityException(hasPermission.ReasonCode.CamelCaseToUnderscore());
            }

            return @case.Id;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseId:int}/support-email")]
        public async Task<dynamic> Support(int caseId)
        {
            var emailTemplate = await _caseEmailTemplate.ForCase(caseId);
            if (string.IsNullOrWhiteSpace(emailTemplate.RecipientEmail))
            {
                emailTemplate.RecipientEmail = _appSettings[KnownAppSettingsKeys.ContactUsEmailAddress];
            }

            return new
            {
                Uri = emailTemplate.TryCreateMailtoUri(out Uri mailto) ? mailto : new Uri("mailto")
            };
        }

        [HttpGet]
        [Route("program")]
        public async Task<string> GetProgram(string programId)
        {
            var pg = !string.IsNullOrEmpty(programId) ? programId : _listCasePrograms.GetDefaultCaseProgram();
            if (string.IsNullOrEmpty(pg)) return null;

            var culture = _preferredCultureResolver.Resolve();
            return await (from p in _dbContext.Set<Program>()
                          where p.Id == pg
                          select DbFuncs.GetTranslation(p.Name, null, p.Name_TID, culture)).SingleAsync();
        }
    }
}