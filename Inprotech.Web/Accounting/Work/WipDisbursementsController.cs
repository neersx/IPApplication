using System;
using System.Collections.Generic;
using System.Globalization;
using System.IdentityModel;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Work
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting/wip-disbursements")]
    [RequiresAccessTo(ApplicationTask.RecordWip, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.DisbursementDissection)]
    public class WipDisbursementsController : ApiController
    {
        readonly IEntities _entities;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControlReader;
        readonly IBestTranslatedNarrativeResolver _bestNarrativeResolver;
        readonly IWipDisbursements _wipDisbursements;

        public WipDisbursementsController(
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            IEntities entities,
            IWipDisbursements wipDisbursements,
            ISiteControlReader siteControlReader,
            IBestTranslatedNarrativeResolver bestNarrativeResolver)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _entities = entities;
            _wipDisbursements = wipDisbursements;
            _siteControlReader = siteControlReader;
            _bestNarrativeResolver = bestNarrativeResolver;
        }

        [HttpGet]
        [Route("view-support")]
        public async Task<dynamic> GetViewSupportData()
        {
            var staffManualEntryForWip = _siteControlReader.Read<int?>(SiteControls.StaffManualEntryForWip) ?? 0;

            var sc = _siteControlReader.ReadMany<bool>(
                                                       SiteControls.ProductRecordedOnWIP,
                                                       SiteControls.APProtocolNumber,
                                                       SiteControls.BillRenewalDebtor);

            var localCurrency = _siteControlReader.Read<string>(SiteControls.CURRENCY);

            var entities = (await _entities.Get(_securityContext.User.NameId))
                .Select(_ => new
                {
                    EntityKey = _.Id,
                    EntityName = _.DisplayName,
                    _.IsDefault
                });

            return new
            {
                Entities = entities,
                ProtocolEnabled = sc[SiteControls.APProtocolNumber],
                ProductRecordedOnWIP = sc[SiteControls.ProductRecordedOnWIP],
                BillRenewalDebtor = sc[SiteControls.BillRenewalDebtor],
                StaffManualEntryforWIP = staffManualEntryForWip,
                LocalCurrency = localCurrency
            };
        }

        [HttpGet]
        [Route("wip-defaults")]
        [RequiresCaseAuthorization]
        public async Task<dynamic> GetWipDefaults(int caseKey)
        {
            return await _wipDisbursements.GetWipDefaults(caseKey);
        }

        [HttpPost]
        [Route("wip-costing")]
        [RequiresCaseAuthorization(PropertyPath = "wipCost.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "wipCost.NameKey")]
        public async Task<dynamic> GetWipCost(WipCost wipCost)
        {
            if (wipCost == null) throw new ArgumentNullException(nameof(wipCost));

            return await _wipDisbursements.GetWipCost(wipCost);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("narrative")]
        public async Task<BestNarrative> DefaultNarrative(string activityKey, int? caseKey = null, int? debtorKey = null, int? staffNameId = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            return await _bestNarrativeResolver.Resolve(culture, activityKey, staffNameId ?? _securityContext.User.NameId, caseKey, !caseKey.HasValue ? debtorKey : null);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("case-activity-multiple-debtors-status")]
        public async Task<dynamic> CaseActivityMultipleDebtorStatus(int caseId, string activityKey)
        {
            var result = await _wipDisbursements.GetCaseActivityMultiDebtorStatus(caseId, activityKey);

            return new
            {
                result.IsMultiDebtorWip,
                result.IsRenewalWip
            };
        }

        [HttpGet]
        [Route("validate")]
        public async Task<dynamic> ValidateItemDate(string itemDate)
        {
            if (!DateTime.TryParseExact(itemDate, "yyyy-MM-dd", DateTimeFormatInfo.InvariantInfo, DateTimeStyles.None, out var parsedItemDate))
            {
                throw new BadRequestException($"{nameof(itemDate)} is required in yyyy-MM-dd format");
            }

            return await _wipDisbursements.ValidateItemDate(parsedItemDate);
        }

        [HttpGet]
        [Route("protocol-disbursements")]
        public async Task<Disbursement> ProtocolDisbursements(int transKey, string protocolKey, string protocolDateString)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipDisbursements.Retrieve(userId, culture, transKey, protocolKey, protocolDateString);
        }

        [HttpPost]
        [Route("")]
        [AppliesToComponent(KnownComponents.Wip)]
        public async Task<bool> Save(Disbursement disbursement)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipDisbursements.Save(userId, culture, disbursement);
        }

        [HttpPost]
        [Route("split-by-debtors")]
        [AppliesToComponent(KnownComponents.Wip)]
        [RequiresCaseAuthorization(PropertyPath = "parameters.CaseKey")]
        [RequiresNameAuthorization(PropertyPath = "parameters.NameKey")]
        public async Task<IEnumerable<DisbursementWip>> GetSplitWip(WipCost parameters)
        {
            return await _wipDisbursements.GetSplitWipByDebtor(parameters);
        }
    }
}