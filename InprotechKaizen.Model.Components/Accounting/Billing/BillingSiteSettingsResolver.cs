using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Policy;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Accounting.Billing
{
    public enum SettingsResolverScope
    {
        IncludeUserSpecificSettings,
        WithoutUserSpecificSettings
    }

    public class BillingSiteSettingsScope
    {
        public SettingsResolverScope Scope { get; set; } = SettingsResolverScope.WithoutUserSpecificSettings;

        public int UserIdentityId { get; set; }

        public string Culture { get; set; }
    }

    public interface IBillingSiteSettingsResolver
    {
        Task<BillingSiteSettings> Resolve(BillingSiteSettingsScope settingsScope, IDictionary<string, object> options = null);
    }

    public class BillingSiteSettingsResolver : IBillingSiteSettingsResolver
    {
        static int? _cachedChangeAdministrator;
        static string _cachedAlertTemplateCode;
        static bool _isDebitNoteChangeNotifierActive;
        readonly IBillReviewSettingsResolver _billReviewSettingsResolver;

        readonly IDbContext _dbContext;
        readonly ILifetimeScopeCache _lifetimeScopeCache;
        readonly IEntities _entities;
        readonly ISiteControlReader _siteControlReader;
        readonly ISiteCurrencyFormat _siteCurrencyFormat;

        public BillingSiteSettingsResolver(IDbContext dbContext,
                                           ISiteCurrencyFormat siteCurrencyFormat,
                                           ISiteControlReader siteControlReader,
                                           IBillReviewSettingsResolver billReviewSettingsResolver,
                                           ILifetimeScopeCache lifetimeScopeCache,
                                           IEntities entities)
        {
            _dbContext = dbContext;
            _siteCurrencyFormat = siteCurrencyFormat;
            _siteControlReader = siteControlReader;
            _billReviewSettingsResolver = billReviewSettingsResolver;
            _lifetimeScopeCache = lifetimeScopeCache;
            _entities = entities;
        }

        public async Task<BillingSiteSettings> Resolve(BillingSiteSettingsScope settingsScope, IDictionary<string, object> options = null)
        {
            var cacheKey = settingsScope.Scope == SettingsResolverScope.WithoutUserSpecificSettings
                ? "site"
                : $"user-{settingsScope.UserIdentityId}";

            var settings = await _lifetimeScopeCache.GetOrAddAsync(
                                                           this,
                                                           cacheKey,
                                                           async x => await ResolveInternal(settingsScope));

            if (options != null)
            {
                foreach (var item in options)
                    settings.Options[item.Key] = item.Value;
            }

            return settings;
        }

        async Task<BillingSiteSettings> ResolveInternal(BillingSiteSettingsScope settingsScope)
        {
            var isc = _siteControlReader.ReadMany<int?>(
                                                        SiteControls.HomeNameNo,
                                                        SiteControls.DNChangeAdministrator,
                                                        SiteControls.WIPProfitCentreSource,
                                                        SiteControls.PreserveConsolidate,
                                                        SiteControls.BillSaveAsPDF,
                                                        SiteControls.BillDateFutureRestriction);

            var bsc = _siteControlReader.ReadMany<bool>(
                                                        SiteControls.BillingRestrictManualPayout,
                                                        SiteControls.BillRenewalDebtor,
                                                        SiteControls.BillDateOnlyFromToday,
                                                        SiteControls.BillDatesForwardOnly,
                                                        SiteControls.InterEntityBilling,
                                                        SiteControls.BillLinesGroupedByTaxCode,
                                                        SiteControls.ApportionAdjustment,
                                                        SiteControls.SellRateOnlyforNewWIP,
                                                        SiteControls.BillWriteUpForExchRate,
                                                        SiteControls.VATusesbillexchangerate,
                                                        SiteControls.WIPSplitMultiDebtor,
                                                        SiteControls.BillAllWIP,
                                                        SiteControls.BillSpellCheckAutomatic,
                                                        SiteControls.EntityRestrictionByCurrency,
                                                        SiteControls.DiscountAutoAdjustment,
                                                        SiteControls.EnterOpenItemNo,
                                                        SiteControls.BillLineTax,
                                                        SiteControls.ChargeVariableFee,
                                                        SiteControls.TAXREQUIRED,
                                                        SiteControls.WIPWriteDownRestricted,
                                                        SiteControls.EntityDefaultsFromCaseOffice,
                                                        SiteControls.CopyToCopiesSuppressed,
                                                        SiteControls.SuppressBillToPrompt);

            var ssc = _siteControlReader.ReadMany<string>(
                                                          SiteControls.DNChangeReminderTemplate,
                                                          SiteControls.BillCheckBeforeDrafting,
                                                          SiteControls.BillCheckBeforeFinalise,
                                                          SiteControls.BillWriteUpExchReason,
                                                          SiteControls.TaxCodeforEUbilling);

            var localCurrency = _siteCurrencyFormat.Resolve();

            var preserveConsolidate = isc.Get(SiteControls.PreserveConsolidate);
            if (preserveConsolidate == 0)
            {
                preserveConsolidate = null;
            }

            var billDateOnlyFromToday = bsc.Get(SiteControls.BillDateOnlyFromToday);
            var billDateRestriction = billDateOnlyFromToday
                ? isc.Get(SiteControls.BillDateFutureRestriction) switch
                {
                    1 => BillDateRestriction.OnlyFutureBillDateWithinSamePeriodAsTodayAllowed,
                    2 => BillDateRestriction.OnlyFutureBillDateWithinAnyOpenPeriodAllowed,
                    _ => BillDateRestriction.OnlyFutureBillDateWithinCurrentOpenPeriodAllowed
                }
                : BillDateRestriction.PastAndFutureBillDatesWithinCurrentOpenPeriodAllowed;

            var billWriteUpExchangeReason = ssc.Get(SiteControls.BillWriteUpExchReason);
            var billWriteUpForExchangeRate = bsc.Get(SiteControls.BillWriteUpForExchRate);
            var chargeVariableFee = bsc.Get(SiteControls.ChargeVariableFee);

            var canReviewBillInEmailDraft = false;
            IEnumerable<BillEntity> entities = null;
            IEnumerable<ReasonEntity> reasonList = null;
            IEnumerable<WipChangeReason> wipChangeReasonList = null;

            if (settingsScope.Scope == SettingsResolverScope.IncludeUserSpecificSettings)
            {
                canReviewBillInEmailDraft = (await _billReviewSettingsResolver.Resolve(settingsScope.UserIdentityId)).CanReviewBillInEmailDraft;

                var staffIdFromUserIdentity = await (from u in _dbContext.Set<User>()
                                                     where u.Id == settingsScope.UserIdentityId
                                                     select u.NameId).SingleAsync();

                entities = await GetEntities(staffIdFromUserIdentity);
                wipChangeReasonList = await GetWipChangeReasons(settingsScope.Culture);
                reasonList = await GetReasons();
            }

            return new BillingSiteSettings
            {
                HomeNameNo = isc.Get(SiteControls.HomeNameNo).GetValueOrDefault(),
                HomeCurrency = localCurrency.LocalCurrencyCode,
                LocalCurrencyCode = localCurrency.LocalCurrencyCode,
                LocalDecimalPlaces = localCurrency.LocalDecimalPlaces,

                AutoDiscountAdjustment = bsc.Get(SiteControls.DiscountAutoAdjustment),

                BillAllWIP = bsc.Get(SiteControls.BillAllWIP),
                BillDateRestriction = billDateRestriction,
                BillDateForwardOnly = bsc.Get(SiteControls.BillDatesForwardOnly),
                BillLinesGroupedByTaxCode = bsc.Get(SiteControls.BillLinesGroupedByTaxCode),
                BillLineTax = bsc.Get(SiteControls.BillLineTax),
                BillRenewalDebtor = bsc.Get(SiteControls.BillRenewalDebtor),
                BillRestrictManualPayout = bsc.Get(SiteControls.BillingRestrictManualPayout),
                BillSpellCheckAutomatic = bsc.Get(SiteControls.BillSpellCheckAutomatic),
                BillWriteUpExchReason = billWriteUpExchangeReason,
                BillWriteUpForExchRate = billWriteUpForExchangeRate,

                ChangeReminderActive = await IsDebitNoteChangeNotifierActive(
                                                                             isc.Get(SiteControls.DNChangeAdministrator),
                                                                             ssc.Get(SiteControls.DNChangeReminderTemplate)),
                ChargeVariableFee = chargeVariableFee,

                EnterOpenItem = bsc.Get(SiteControls.EnterOpenItemNo),
                EntityDefaultsFromCaseOffice = bsc.Get(SiteControls.EntityDefaultsFromCaseOffice),
                EntityRestrictionByCurrency = bsc.Get(SiteControls.EntityRestrictionByCurrency),

                IsApportionAdjustmentAllowed = bsc.Get(SiteControls.ApportionAdjustment),
                IsBillWriteUpConfigurationValid = await IsBillWriteUpConfigurationValid(billWriteUpExchangeReason, billWriteUpForExchangeRate, chargeVariableFee),
                IsCopyToSuppressed = bsc.Get(SiteControls.CopyToCopiesSuppressed),
                InterEntityBilling = bsc.Get(SiteControls.InterEntityBilling),

                PreserveConsolidate = preserveConsolidate,

                SavePdfToPath = isc.Get(SiteControls.BillSaveAsPDF) switch
                {
                    (int) BillSaveAsPdfSetting.GenerateOnPrintThenAttachToCase => true,
                    (int) BillSaveAsPdfSetting.GenerateOnFinaliseThenAttachToCase => true,
                    _ => false
                },

                BillSaveAsPdfSetting = (BillSaveAsPdfSetting) (isc.Get(SiteControls.BillSaveAsPDF) ?? 0),

                SellRateOnlyforNewWIP = bsc.Get(SiteControls.SellRateOnlyforNewWIP),

                ShouldWarnIfDraftBillForSameCaseExist = ssc.Get(SiteControls.BillCheckBeforeDrafting) == "D",
                ShouldWarnIfUnpostedTimeExistOnBillFinalisation = (ssc.Get(SiteControls.BillCheckBeforeFinalise) ?? string.Empty).IgnoreCaseContains("T"),
                ShouldWarnIfNonIncludedDebitWipExistOnBillFinalisation = (ssc.Get(SiteControls.BillCheckBeforeFinalise) ?? string.Empty).IgnoreCaseContains("W"),
                ShouldWarnIfDraftBillForSameCaseExistOnBillFinalisation = (ssc.Get(SiteControls.BillCheckBeforeFinalise) ?? string.Empty).IgnoreCaseContains("D"),

                TaxCodeforEUbilling = ssc.Get(SiteControls.TaxCodeforEUbilling),
                TaxRequired = bsc.Get(SiteControls.TAXREQUIRED),

                VATUsesBillExchRate = bsc.Get(SiteControls.VATusesbillexchangerate),

                WIPProfitCentreSource = isc.Get(SiteControls.WIPProfitCentreSource) ?? 0,
                WipWriteDownRestricted = bsc.Get(SiteControls.WIPWriteDownRestricted),
                WIPSplitMultiDebtor = bsc.Get(SiteControls.WIPSplitMultiDebtor),
                SuppressBillToPrompt = bsc.Get(SiteControls.SuppressBillToPrompt),

                CanReviewBillInEmailDraft = canReviewBillInEmailDraft,
                Scope = settingsScope.Scope,
                Entities = entities,
                ReasonList = reasonList,
                WipChangeReasonList = wipChangeReasonList
            };
        }

        async Task<IEnumerable<BillEntity>> GetEntities(int nameId)
        {
            return (await _entities.Get(nameId))
                .Select(_ => new BillEntity
                {
                    EntityKey = _.Id,
                    EntityName = _.DisplayName,
                    IsDefault = _.IsDefault
                });
        }

        async Task<IEnumerable<ReasonEntity>> GetReasons()
        {
            return await _dbContext.Set<TableCode>()
                                   .Where(_ => _.TableTypeId == (short)TableTypes.NameAddressChangeReason)
                                   .Select(_ => new ReasonEntity
                                   {
                                       Id = _.Id,
                                       Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, null),
                                       UserCode = _.UserCode, TypeId = _.TableTypeId
                                   }).ToArrayAsync();
        }

        public async Task<IEnumerable<WipChangeReason>> GetWipChangeReasons(string culture)
        {
            return await (from r in _dbContext.Set<Reason>()
                          where r.UsedBy != null && ((int)r.UsedBy & (int)KnownApplicationUsage.Billing) == (int)KnownApplicationUsage.Billing
                          select new WipChangeReason
                          {
                              ReasonKey = r.Code,
                              ReasonDescription = DbFuncs.GetTranslation(r.Description, null, r.DescriptionTId, culture)
                          }).ToArrayAsync();
        }

        async Task<bool> IsDebitNoteChangeNotifierActive(int? changeAdministrator, string alertTemplate)
        {
            if (changeAdministrator == null || string.IsNullOrWhiteSpace(alertTemplate))
            {
                return false;
            }

            if (_cachedAlertTemplateCode == alertTemplate && _cachedChangeAdministrator == changeAdministrator)
            {
                return _isDebitNoteChangeNotifierActive;
            }

            _cachedAlertTemplateCode = alertTemplate;
            _cachedChangeAdministrator = changeAdministrator;
            _isDebitNoteChangeNotifierActive = await _dbContext.Set<Name>().AsNoTracking().AnyAsync(n => n.Id == changeAdministrator) &&
                                               await _dbContext.Set<AlertTemplate>().AsNoTracking().AnyAsync(a => a.AlertTemplateCode == alertTemplate);

            return _isDebitNoteChangeNotifierActive;
        }

        async Task<bool> IsBillWriteUpConfigurationValid(string billWriteUpExchangeReason, bool billWriteUpForExchangeRate, bool chargeVariableFee)
        {
            if (string.IsNullOrEmpty(billWriteUpExchangeReason) || !billWriteUpForExchangeRate) return true;

            if (!chargeVariableFee)
            {
                return !await _dbContext.Set<BillRule>().AnyAsync(_ => _.RuleTypeId == BillRuleType.MinimumWipValue);
            }

            return false;
        }
    }

    public class BillingSiteSettings
    {
        public SettingsResolverScope Scope { get; set; }
        public int HomeNameNo { get; set; }
        public string LocalCurrencyCode { get; set; }
        public int LocalDecimalPlaces { get; set; }
        public string DateFormat { get; set; }
        public bool BillRenewalDebtor { get; set; }
        public bool ChangeReminderActive { get; set; }
        public bool InterEntityBilling { get; set; }
        public BillDateRestriction BillDateRestriction { get; set; }
        public bool BillDateForwardOnly { get; set; }
        public bool BillRestrictManualPayout { get; set; }
        public bool BillLinesGroupedByTaxCode { get; set; }
        public bool BillLineTax { get; set; }
        public bool IsApportionAdjustmentAllowed { get; set; }
        public bool SellRateOnlyforNewWIP { get; set; }
        public bool BillWriteUpForExchRate { get; set; }
        public string BillWriteUpExchReason { get; set; }
        public bool VATUsesBillExchRate { get; set; }
        public int? PreserveConsolidate { get; set; }
        public int WIPProfitCentreSource { get; set; }
        public bool WIPSplitMultiDebtor { get; set; }
        public bool SuppressBillToPrompt { get; set; }
        public bool BillAllWIP { get; set; }
        public string HomeCurrency { get; set; }
        public bool EntityRestrictionByCurrency { get; set; }
        public bool BillSpellCheckAutomatic { get; set; }
        public bool AutoDiscountAdjustment { get; set; }
        public bool EnterOpenItem { get; set; }
        public bool ChargeVariableFee { get; set; }
        public bool SavePdfToPath { get; set; }
        public BillSaveAsPdfSetting BillSaveAsPdfSetting { get; set; }

        public string TaxCodeforEUbilling { get; set; }
        public bool TaxRequired { get; set; }
        public bool WipWriteDownRestricted { get; set; }

        public bool EntityDefaultsFromCaseOffice { get; set; }
        public bool IsCopyToSuppressed { get; set; }
        public bool IsBillWriteUpConfigurationValid { get; set; }

        public bool CanReviewBillInEmailDraft { get; set; }
        public bool ShouldWarnIfDraftBillForSameCaseExist { get; set; }
        public bool ShouldWarnIfUnpostedTimeExistOnBillFinalisation { get; set; }
        public bool ShouldWarnIfNonIncludedDebitWipExistOnBillFinalisation { get; set; }
        public bool ShouldWarnIfDraftBillForSameCaseExistOnBillFinalisation { get; set; }

        public IEnumerable<BillEntity> Entities { get; set; }
        public IEnumerable<ReasonEntity> ReasonList { get; set; }

        public IEnumerable<WipChangeReason> WipChangeReasonList { get; set;}

        public Dictionary<string, object> Options = new Dictionary<string, object>();
    }

    public enum BillDateRestriction
    {
        OnlyFutureBillDateWithinCurrentOpenPeriodAllowed,
        OnlyFutureBillDateWithinSamePeriodAsTodayAllowed,
        OnlyFutureBillDateWithinAnyOpenPeriodAllowed,
        PastAndFutureBillDatesWithinCurrentOpenPeriodAllowed
    }

    public enum BillSaveAsPdfSetting
    {
        NotSet,

        /// <summary>
        /// PDF created for use by DMS;
        /// The PDF files are saved in the directory specified under the 'DocMgmt Directory' Site Control
        /// </summary>
        GenerateThenSaveToDms = 1,

        /// <summary>
        /// The PDF file is generated on printing the invoice, then attached to Case/Name.
        /// The PDF files are saved in the directory specified under the 'Bill PDF Directory' Site Control
        /// </summary>
        GenerateOnPrintThenAttachToCase = 2,

        /// <summary>
        /// The PDF file is generated finalising the invoice, then attached to Case/Name.
        /// The PDF files are saved in the directory specified under the 'Bill PDF Directory' Site Control
        /// </summary>
        GenerateOnFinaliseThenAttachToCase = 3
    }

    public enum BillGenerationType
    {
        GenerateOnly,
        GenerateThenSendToDms,
        GenerateThenAttachToCase
    }

    public class BillEntity
    {
        public int EntityKey { get; set; }
        public string EntityName { get; set; }
        public bool? IsDefault { get; set; }
    }

    public class ReasonEntity
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string UserCode { get; set; }
        public short TypeId { get; set; }
    }

    public class WipChangeReason
    {
        public string ReasonKey { get; set; }
        public string ReasonDescription { get; set; }
    }

    public static class AdditionalBillingOptions
    {
        public static readonly string SendFinalisedBillToReviewer = nameof(SendFinalisedBillToReviewer);

        public static readonly string BillGenerationTracking = nameof(BillGenerationTracking);
    }
}