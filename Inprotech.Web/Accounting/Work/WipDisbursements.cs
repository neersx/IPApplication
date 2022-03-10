using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Core;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Accounting.Work
{
    public interface IWipDisbursements
    {
        Task<dynamic> GetWipDefaults(int caseId);
        Task<dynamic> GetWipCost(WipCost wipCost);
        Task<(bool IsMultiDebtorWip, bool IsRenewalWip)> GetCaseActivityMultiDebtorStatus(int caseId, string activityKey);
        Task<ValidationErrorCollection> ValidateItemDate(DateTime date);
        Task<Disbursement> Retrieve(int userIdentityId, string culture, int transKey, string protocolKey, string protocolDateString);
        Task<bool> Save(int userIdentityId, string culture, Disbursement disbursementBaseWip);
        Task<IEnumerable<DisbursementWip>> GetSplitWipByDebtor(WipCost wipCost);
    }

    public class WipDisbursements : IWipDisbursements
    {
        readonly IApplicationAlerts _applicationAlerts;
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly IDebtorWipSplitter _debtorWipSplitter;
        readonly IPostWipCommand _postWipCommand;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IProtocolDisbursements _protocolDisbursements;
        readonly IValidatePostDates _validatePostDates;
        readonly IWipCosting _wipCosting;
        readonly IWipDebtorSelector _wipDebtorSelector;
        readonly IWipDefaulting _wipDefaulting;

        public WipDisbursements(IDbContext dbContext,
                                IPreferredCultureResolver preferredCultureResolver,
                                IWipDefaulting wipDefaulting,
                                IWipCosting wipCosting,
                                IWipDebtorSelector wipDebtorSelector,
                                IValidatePostDates validatePostDates,
                                IProtocolDisbursements protocolDisbursements,
                                IDebtorWipSplitter debtorWipSplitter,
                                IPostWipCommand postWipCommand,
                                IApplicationAlerts applicationAlerts,
                                Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _wipDefaulting = wipDefaulting;
            _wipCosting = wipCosting;
            _wipDebtorSelector = wipDebtorSelector;
            _validatePostDates = validatePostDates;
            _protocolDisbursements = protocolDisbursements;
            _debtorWipSplitter = debtorWipSplitter;
            _postWipCommand = postWipCommand;
            _applicationAlerts = applicationAlerts;
            _clock = clock;
        }

        public async Task<dynamic> GetWipDefaults(int caseId)
        {
            var wipTemplateFilter = new WipTemplateFilterCriteria
            {
                ContextCriteria = new WipTemplateFilterCriteria.ContextCriteriaFilter { CaseKey = caseId },
                WipCategory = new WipTemplateFilterCriteria.WipCategoryFilter { IsDisbursements = true },
                UsedByApplication = new WipTemplateFilterCriteria.UsedByApplicationFilter { IsWip = true }
            };

            return await _wipDefaulting.ForCase(wipTemplateFilter, caseId);
        }

        public async Task<dynamic> GetWipCost(WipCost wipCost)
        {
            if (wipCost == null) throw new ArgumentNullException(nameof(wipCost));

            return await _wipCosting.For(wipCost);
        }

        public async Task<IEnumerable<DisbursementWip>> GetSplitWipByDebtor(WipCost wipCost)
        {
            if (wipCost == null) throw new ArgumentNullException(nameof(wipCost));
            if (wipCost.TransactionDate == null) throw new ArgumentException(nameof(wipCost.TransactionDate));

            var culture = _preferredCultureResolver.Resolve();

            var splits = await _debtorWipSplitter.Split(culture, new UnpostedWip
            {
                WipCode = wipCost.WipCode,
                CaseKey = wipCost.CaseKey,
                NameKey = wipCost.NameKey,
                LocalCost = wipCost.LocalValueBeforeMargin,
                ForeignCost = wipCost.ForeignValueBeforeMargin,
                ForeignCurrency = wipCost.CurrencyCode,
                StaffKey = wipCost.StaffKey,
                TransactionDate = wipCost.TransactionDate.Value
            });

            return splits.Select(wip => new DisbursementWip
            {
                CaseKey = wip.CaseKey,
                TransDate = wip.TransactionDate,
                WIPCode = wip.WipCode,
                NameKey = wip.NameKey,
                StaffKey = wip.StaffKey.GetValueOrDefault(),
                Amount = wip.LocalCost.GetValueOrDefault(),
                ForeignAmount = wip.ForeignCost.GetValueOrDefault(),
                CurrencyCode = wip.ForeignCurrency,
                Margin = wip.MarginValue,
                ForeignMargin = wip.ForeignMargin,
                Discount = wip.DiscountValue,
                ForeignDiscount = wip.ForeignDiscount,
                NarrativeKey = wip.NarrativeKey,
                NarrativeText = wip.Narrative,
                LocalDiscountForMargin = wip.DiscountForMargin,
                ForeignDiscountForMargin = wip.ForeignDiscountForMargin,
                Quantity = wip.EnteredQuantity,
                IsSplitDebtorWip = wip.IsSplitDebtorWip,
                DebtorSplitPercentage = wip.DebtorSplitPercentage,
                LocalCost1 = wip.CostCalculation1,
                LocalCost2 = wip.CostCalculation2
            });
        }

        public async Task<(bool IsMultiDebtorWip, bool IsRenewalWip)> GetCaseActivityMultiDebtorStatus(int caseId, string activityKey)
        {
            return await _wipDebtorSelector.CaseActivityMultiDebtorStatus(caseId, activityKey);
        }

        public async Task<ValidationErrorCollection> ValidateItemDate(DateTime date)
        {
            var result = await _validatePostDates.For(date);
            if (result.isValid)
            {
                return new ValidationErrorCollection();
            }

            return new ValidationErrorCollection
            {
                ValidationErrorList = new List<ValidationError>
                {
                    new()
                    {
                        WarningCode = result.isWarningOnly ? result.code : string.Empty,
                        WarningDescription = result.isWarningOnly ? KnownErrors.CodeMap[result.code] : string.Empty,
                        ErrorCode = !result.isWarningOnly ? result.code : string.Empty,
                        ErrorDescription = !result.isWarningOnly ? KnownErrors.CodeMap[result.code] : string.Empty
                    }
                }
            };
        }

        public async Task<Disbursement> Retrieve(int userIdentityId, string culture, int transKey, string protocolKey, string protocolDateString)
        {
            return await _protocolDisbursements.Retrieve(userIdentityId, culture, transKey, protocolKey, protocolDateString);
        }

        public async Task<bool> Save(int userIdentityId, string culture, Disbursement disbursementBaseWip)
        {
            if (disbursementBaseWip == null) throw new ArgumentNullException(nameof(disbursementBaseWip));

            var validateResult = await ValidateItemDate(disbursementBaseWip.TransDate.GetValueOrDefault());
            if (validateResult.HasError) throw new Exception(validateResult.FirstErrorDescription);

            var postWipParameters = GetNewWipToPost(disbursementBaseWip).ToArray();

            try
            {
                using var transaction = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);

                await _postWipCommand.Post(userIdentityId, culture, postWipParameters);

                transaction.Complete();

                return true;
            }
            catch (Exception e)
            {
                if (_applicationAlerts.TryParse(e.Message, out var alerts))
                {
                    throw new Exception(alerts.First().Message);
                }

                throw;
            }
        }

        IEnumerable<PostWipParameters> GetNewWipToPost(Disbursement disbursementBaseWip)
        {
            var shouldSuppressPostingToGeneralLedger = true;

            foreach (var disbursementWip in disbursementBaseWip.DissectedDisbursements)
            {
                if (disbursementWip.SplitWipItems.Count > 1)
                {
                    foreach (var wipItem in disbursementWip.SplitWipItems)
                    {
                        if (disbursementWip == disbursementBaseWip.DissectedDisbursements.Last() && wipItem == disbursementWip.SplitWipItems.Last())
                        {
                            shouldSuppressPostingToGeneralLedger = false;
                        }

                        yield return NewWipToPost(disbursementBaseWip, wipItem, shouldSuppressPostingToGeneralLedger);
                    }
                }
                else
                {
                    if (disbursementWip == disbursementBaseWip.DissectedDisbursements.Last())
                    {
                        shouldSuppressPostingToGeneralLedger = false;
                    }

                    yield return NewWipToPost(disbursementBaseWip, disbursementWip, shouldSuppressPostingToGeneralLedger);
                }
            }
        }

        PostWipParameters NewWipToPost(Disbursement baseDisbursementWip, DisbursementWip dissectedDisbursementWip, bool shouldSuppressPostToGeneralLedger)
        {
            var today = _clock().Date;

            var creditWipMultiplier = baseDisbursementWip.CreditWIP ? -1 : 1;

            decimal? ReverseSignForCreditWip(decimal? value)
            {
                return value * creditWipMultiplier;
            }

            return new PostWipParameters
            {
                EntityKey = baseDisbursementWip.EntityKey,
                TransactionDate = baseDisbursementWip.TransDate ?? today,
                TransactionType = (short)TransactionType.Disbursement,
                NameKey = dissectedDisbursementWip.NameKey,
                CaseKey = dissectedDisbursementWip.CaseKey,
                StaffKey = dissectedDisbursementWip.StaffKey,
                AssociateKey = baseDisbursementWip.AssociateKey,
                InvoiceNumber = baseDisbursementWip.InvoiceNo,
                VerificationNumber = baseDisbursementWip.VerificationNo,
                WipCode = dissectedDisbursementWip.WIPCode,
                LocalValue = ReverseSignForCreditWip(dissectedDisbursementWip.Amount + dissectedDisbursementWip.Margin.GetValueOrDefault()) ?? decimal.Zero,
                ForeignValue = baseDisbursementWip.Currency != null
                    ? ReverseSignForCreditWip(dissectedDisbursementWip.ForeignAmount + dissectedDisbursementWip.ForeignMargin.GetValueOrDefault())
                    : null,
                ForeignCurrency = baseDisbursementWip.Currency,
                ExchangeRate = dissectedDisbursementWip.ExchRate,
                DiscountValue = ReverseSignForCreditWip(dissectedDisbursementWip.Discount),
                ForeignDiscount = ReverseSignForCreditWip(dissectedDisbursementWip.ForeignDiscount),
                LocalCost = ReverseSignForCreditWip(dissectedDisbursementWip.Amount),
                ForeignCost = ReverseSignForCreditWip(dissectedDisbursementWip.ForeignAmount),
                CostCalculation1 = ReverseSignForCreditWip(dissectedDisbursementWip.LocalCost1),
                CostCalculation2 = ReverseSignForCreditWip(dissectedDisbursementWip.LocalCost2),
                EnteredQuantity = dissectedDisbursementWip.Quantity,
                NarrativeKey = dissectedDisbursementWip.NarrativeKey,
                Narrative = dissectedDisbursementWip.DebitNoteText,
                MarginNo = dissectedDisbursementWip.MarginNo,
                IsDraftWip = false,
                IsCreditWip = baseDisbursementWip.CreditWIP,
                MarginValue = ReverseSignForCreditWip(dissectedDisbursementWip.Margin),
                ForeignMargin = ReverseSignForCreditWip(dissectedDisbursementWip.ForeignMargin),
                DiscountForMargin = ReverseSignForCreditWip(dissectedDisbursementWip.LocalDiscountForMargin),
                ForeignDiscountForMargin = ReverseSignForCreditWip(dissectedDisbursementWip.ForeignDiscountForMargin),
                ShouldReturnWipKey = true,
                IsBillingDiscount = false,
                ShouldSuppressCommit = true,
                ShouldSuppressPostToGeneralLedger = shouldSuppressPostToGeneralLedger,
                ProtocolKey = baseDisbursementWip.ProtocolKey,
                ProtocolDate = baseDisbursementWip.ProtocolDate,
                ProductCode = dissectedDisbursementWip.ProductKey,
                IsSplitDebtorWip = dissectedDisbursementWip.IsSplitDebtorWip,
                DebtorSplitPercentage = dissectedDisbursementWip.DebtorSplitPercentage
            };
        }
    }
}