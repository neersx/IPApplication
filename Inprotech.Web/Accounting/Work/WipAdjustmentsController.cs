using System;
using System.Collections.Generic;
using System.Data.Entity;
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
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Accounting.Work
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting/wip-adjustments")]
    public class WipAdjustmentsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly IWipAdjustments _wipAdjustments;

        public WipAdjustmentsController(IDbContext dbContext,
                                       ISiteControlReader siteControlReader,
                                       ISecurityContext securityContext,
                                       IPreferredCultureResolver preferredCultureResolver,
                                       IWipAdjustments wipAdjustments)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _wipAdjustments = wipAdjustments;
        }

        [HttpGet]
        [Route("view-support")]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<dynamic> GetViewSupportData()
        {
            var culture = _preferredCultureResolver.Resolve();

            var localCurrency = _siteControlReader.Read<string>(SiteControls.CURRENCY);

            var sc = _siteControlReader.ReadMany<bool>(
                                                       SiteControls.ProductRecordedOnWIP,
                                                       SiteControls.WIPSplitMultiDebtor,
                                                       SiteControls.TransferAssociatedDiscount,
                                                       SiteControls.WIPWriteDownRestricted,
                                                       SiteControls.RestrictOnWIP);

            var reasons = await _wipAdjustments.GetReasons(culture);

            var writeDownLimit = await (from u in _dbContext.Set<User>()
                                        where u.Id == _securityContext.User.Id
                                        select u.WriteDownLimit)
                .SingleAsync();

            return new
            {
                ReasonSupportCollection = reasons,
                LocalCurrency = localCurrency,
                ProductRecordedOnWIP = sc[SiteControls.ProductRecordedOnWIP],
                SplitWipMultiDebtor = sc[SiteControls.WIPSplitMultiDebtor],
                TransferAssociatedDiscount = sc[SiteControls.TransferAssociatedDiscount],
                WipWriteDownRestricted = sc[SiteControls.WIPWriteDownRestricted],
                RestrictOnWIP = sc[SiteControls.RestrictOnWIP],
                WriteDownLimit = writeDownLimit
            };
        }

        [HttpGet]
        [RequiresCaseAuthorization(PropertyName = "caseId")]
        [Route("case-has-multiple-debtors")]
        public async Task<bool> CaseHasMultipleDebtors(int? caseId)
        {
            return await _wipAdjustments.CaseHasMultipleDebtors(caseId);
        }

        [HttpGet]
        [Route("wip-defaults")]
        [RequiresCaseAuthorization(PropertyName = "caseKey")]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<dynamic> GetDefaultWipInformation(int? caseKey, string activityKey)
        {
            return await _wipAdjustments.GetWipDefaults(caseKey, activityKey);
        }

        [HttpGet]
        [Route("staff-profit-centre")]
        [RequiresNameAuthorization(PropertyName = "nameKey")]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<dynamic> GetStaffProfitCenter(int nameKey)
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _wipAdjustments.GetStaffProfitCenter(nameKey, culture);
        }

        [HttpGet]
        [Route("validate")]
        public async Task<dynamic> ValidateItemDate(string itemDate)
        {
            if (!DateTime.TryParseExact(itemDate, "yyyy-MM-dd", DateTimeFormatInfo.InvariantInfo, DateTimeStyles.None, out var parsedItemDate))
            {
                throw new BadRequestException($"{nameof(itemDate)} is required in yyyy-MM-dd format");
            }

            return await _wipAdjustments.ValidateItemDate(parsedItemDate);
        }

        [HttpGet]
        [Route("adjust-item")]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<dynamic> ItemForAdjustment(int entityKey, int transKey, int wipSeqKey)
        {
            var userId = _securityContext.User.Id;

            var culture = _preferredCultureResolver.Resolve();

            return await _wipAdjustments.GetItemToAdjust(userId, culture, entityKey, transKey, wipSeqKey);
        }

        [HttpPost]
        [Route("adjust-item")]
        [AppliesToComponent(KnownComponents.Wip)]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<ChangeSetEntry<AdjustWipItemDto>> ItemForAdjustment([FromBody] ChangeSetEntry<AdjustWipItemDto> dto)
        {
            var userId = _securityContext.User.Id;

            var culture = _preferredCultureResolver.Resolve();

            await _wipAdjustments.AdjustItems(userId, culture, new[] { dto });

            return dto;
        }

        [HttpGet]
        [Route("split-item")]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<dynamic> ItemToSplit(int entityKey, int transKey, int wipSeqKey)
        {
            var userId = _securityContext.User.Id;

            var culture = _preferredCultureResolver.Resolve();

            return await _wipAdjustments.GetItemToSplit(userId, culture, entityKey, transKey, wipSeqKey);
        }

        [HttpPost]
        [Route("split-item")]
        [AppliesToComponent(KnownComponents.Wip)]
        [RequiresAccessTo(ApplicationTask.AdjustWip)]
        public async Task<IEnumerable<ChangeSetEntry<SplitWipItem>>> ItemToSplit([FromBody] ChangeSetEntry<SplitWipItem>[] dto)
        {
            if (dto == null) throw new ArgumentNullException(nameof(dto));

            var userId = _securityContext.User.Id;

            var culture = _preferredCultureResolver.Resolve();

            await _wipAdjustments.SplitItems(userId, culture, dto);

            return dto;
        }
    }

    public class AdjustWipItemDto : AdjustWipItem
    {
        /// <summary>
        ///     TODO: POST-WIP-AND-BILLING-SILVERLIGHT-REMOVAL
        ///     - workaround for data transfer from old web AdjustWipService
        /// </summary>
        public int WIPSeqKey
        {
            get => WipSeqNo;
            set => WipSeqNo = value;
        }

        public bool AdjustDiscount { get; set; }
    }
}