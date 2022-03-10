using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.PostSourceUpdate;
using InprotechKaizen.Model.Components.Cases.Comparison;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Web.CaseComparison
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    public class CompareCaseController : ApiController
    {
        readonly ICaseComparer _caseComparer;
        readonly ICaseImageComparison _caseImageComparison;
        readonly IComparisonUpdater _comparisonUpdater;
        readonly ICpaXmlProvider _cpaXmlProvider;
        readonly IDbContext _dbContext;
        readonly IIndex<DataSourceType, IDuplicateCasesFinder> _duplicateCasesFinders;
        readonly IIndex<DataSourceType, ISourceUpdatedHandler> _postUpdateHandlers;
        readonly ISourceCaseRejection _sourceCaseRejection;
        readonly IIndex<DataSourceType, ISourceCaseUrlFormatter> _sourceCaseUrlFormatter;

        public CompareCaseController(IDbContext dbContext,
                                     ICaseComparer caseComparer,
                                     ICpaXmlProvider cpaXmlProvider,
                                     IComparisonUpdater comparisonUpdater,
                                     IIndex<DataSourceType, ISourceUpdatedHandler> postUpdateHandlers,
                                     ISourceCaseRejection sourceCaseRejection,
                                     ICaseImageComparison caseImageComparison,
                                     IIndex<DataSourceType, IDuplicateCasesFinder> duplicateCasesFinder,
                                     IIndex<DataSourceType, ISourceCaseUrlFormatter> sourceCaseUrlFormatter)
        {
            _dbContext = dbContext;
            _caseComparer = caseComparer;
            _cpaXmlProvider = cpaXmlProvider;
            _comparisonUpdater = comparisonUpdater;
            _postUpdateHandlers = postUpdateHandlers;
            _sourceCaseRejection = sourceCaseRejection;
            _caseImageComparison = caseImageComparison;
            _duplicateCasesFinders = duplicateCasesFinder;
            _sourceCaseUrlFormatter = sourceCaseUrlFormatter;
        }

        [HttpGet]
        [Route("api/casecomparison/n/{notificationId}/case/{caseId}")]
        [Route("api/casecomparison/n/{notificationId}/case/{caseId}/{systemCode}")]
        [RequiresCaseAuthorization]
        public async Task<CompareCaseResult> Compare(int notificationId, int caseId, string systemCode = "USPTO.PrivatePAIR")
        {
            var cpaXml = await _cpaXmlProvider.For(notificationId);
            var rejectability = await _sourceCaseRejection.CheckRejectability(notificationId);

            var @case = await _dbContext.Set<Case>()
                                        .Include(c => c.OfficialNumbers)
                                        .Include(c => c.OfficialNumbers.Select(_ => _.NumberType))
                                        .Include(c => c.CaseEvents)
                                        .Include(c => c.CaseNames)
                                        .Include(c => c.CaseNames.Select(_ => _.Name))
                                        .Include(c => c.CaseNames.Select(_ => _.NameType))
                                        .Include(c => c.CaseNames.Select(_ => _.Address))
                                        .Include(c => c.CaseNames.Select(_ => _.Address.Country))
                                        .Include(c => c.OpenActions)
                                        .Include(c => c.OpenActions.Select(_ => _.Criteria))
                                        .Include(c => c.RelatedCases)
                                        .Include(c => c.RelatedCases.Select(_ => _.Relation))
                                        .Include(c => c.RelatedCases.Select(_ => _.Relation.FromEvent))
                                        .Include(c => c.CaseTexts.Select(_=>_.LanguageValue))
                                        .SingleOrDefaultAsync(c => c.Id == caseId);

            var r = await _caseComparer.Compare(@case, cpaXml, systemCode);

            r.CaseImage = _caseImageComparison.Compare(caseId, notificationId);

            r.Rejectable = rejectability.CanReject;

            r.RejectionResetable = rejectability.CanReverseReject;

            var source = ExternalSystems.DataSource(systemCode);
            if (_duplicateCasesFinders.TryGetValue(source, out var duplicateCasesFinder))
            {
                r.HasDuplicates = await duplicateCasesFinder.AreDuplicatesPresent(notificationId);
            }

            if (r.Case != null && _sourceCaseUrlFormatter.TryGetValue(source, out var urlFormatter))
            {
                r.Case.SourceLink = urlFormatter.Format(r, IsCpaSso());
            }

            return new CompareCaseResult
            {
                ViewData = r,
                RawCpaXml = cpaXml
            };
        }

        [HttpPost]
        [PreallocateSessionAccessToken]
        [Route("api/casecomparison/savechanges")]
        [RequiresAccessTo(ApplicationTask.SaveImportedCaseData)]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyPath = "saveData.CaseId")]
        [AppliesToComponent(KnownComponents.CaseComparison)]
        public async Task<dynamic> SaveChanges(CaseComparisonSave saveData)
        {
            if (saveData == null) throw new ArgumentNullException(nameof(saveData));

            await _comparisonUpdater.ApplyChanges(saveData);

            var comparedData = await Compare(saveData.NotificationId, saveData.CaseId, saveData.SystemCode);

            var source = ExternalSystems.DataSource(saveData.SystemCode);
            if (_postUpdateHandlers.TryGetValue(source, out var handler))
            {
                await handler.Handle(saveData.CaseId, comparedData.RawCpaXml);
            }

            return new
            {
                Success = true,
                comparedData.ViewData
            };
        }

        bool IsCpaSso()
        {
            return (string) Request.GetOwinContext().Environment[nameof(AuthCookieData.AuthMode)] == AuthenticationModeKeys.Sso;
        }

        public class CompareCaseResult
        {
            public dynamic ViewData { get; set; }

            [JsonIgnore]
            public string RawCpaXml { get; set; }
        }
    }
}