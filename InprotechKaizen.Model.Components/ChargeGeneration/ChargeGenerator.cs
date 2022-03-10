using System;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.ChargeGeneration
{
    public interface IChargeGenerator
    {
        void QueueChecklistQuestionCharge(Case @case, short checklistType, int checklistCriteria, short? questionId, dynamic rate, dynamic checklistData);
    }

    public class ChargeGenerator : IChargeGenerator
    {
        readonly ISiteControlReader _siteControlReader;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public ChargeGenerator(ISiteControlReader siteControlReader, IDbContext dbContext, ISecurityContext securityContext)
        {
            _siteControlReader = siteControlReader;
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public void QueueChecklistQuestionCharge(Case @case, short checklistType, int checklistCriteria, short? questionId, dynamic rate, dynamic checklistData)
        {
            var wipSplitMultiDebtor = _siteControlReader.Read<bool>(SiteControls.WIPSplitMultiDebtor);
            var checklistItem = Queryable.SingleOrDefault<ChecklistItem>(_dbContext.Set<ChecklistItem>(), v => v.CriteriaId == checklistCriteria && v.QuestionId == questionId);
            if (wipSplitMultiDebtor)
            {
                var allDebtors = rate.RateTypeId == KnownRateType.RenewalRate ?
                    Queryable.Where<CaseName>(_dbContext.Set<CaseName>(), v => v.CaseId == @case.Id && v.NameTypeId == KnownNameTypes.RenewalsDebtor).ToList() :
                    Queryable.Where<CaseName>(_dbContext.Set<CaseName>(), v => v.CaseId == @case.Id && v.NameTypeId == KnownNameTypes.Debtor).ToList();

                foreach (var debtor in allDebtors)
                {
                    @case.PendingRequests.Add(new CaseActivityRequest(@case, DateTime.Now, _securityContext.User.UserName)
                    {
                        ProgramId = KnownPrograms.WebApps,
                        QuestionId = questionId,
                        ActivityType = (short?) TableTypes.SystemActivity,
                        ActivityCode = KnownSystemActivity.Charges,
                        RateId = rate.RateId,
                        PayFeeCode = checklistItem?.PayFeeCode,
                        EstimateFlag = checklistItem?.EstimateFlag,
                        DirectPayFlag = checklistItem?.DirectPayFlag,
                        EnteredQuantity = (int?) checklistData.CountValue,
                        EnteredAmount = (decimal?) checklistData.AmountValue,
                        Processed = 0,
                        TransactionFlag = 0,
                        ChecklistType = checklistType,
                        SeparateDebtorFlag = 1m,
                        Debtor = debtor.NameId,
                        BillPercentage = debtor.BillingPercentage,
                        IdentityId = _securityContext.User.Id
                    });
                }
            }
            else
            {
                @case.PendingRequests.Add(new CaseActivityRequest(@case, DateTime.Now, _securityContext.User.UserName)
                {
                    ProgramId = KnownPrograms.WebApps,
                    QuestionId = questionId,
                    ActivityType = (short?) TableTypes.SystemActivity,
                    ActivityCode = KnownSystemActivity.Charges,
                    RateId = rate.RateId,
                    PayFeeCode = checklistItem?.PayFeeCode,
                    EstimateFlag = checklistItem?.EstimateFlag,
                    DirectPayFlag = checklistItem?.DirectPayFlag,
                    EnteredQuantity = (int?) checklistData.CountValue,
                    EnteredAmount = (decimal?) checklistData.AmountValue,
                    Processed = 0,
                    TransactionFlag = 0,
                    ChecklistType = checklistType,
                    SeparateDebtorFlag = 0m,
                    IdentityId = _securityContext.User.Id
                });
            }
        }
    }
}
