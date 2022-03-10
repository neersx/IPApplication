using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public interface IFinaliseBillValidator
    {
        Task<IEnumerable<FinaliseValidationSummary>> Validate(FinaliseRequest request);
    }

    public class FinaliseBillValidator : IFinaliseBillValidator
    {
        readonly IDbContext _dbContext;
        readonly IBillingSiteSettingsResolver _billingSiteSettingsResolver;
        static readonly ItemType[] SuitableForValidation = new[] { ItemType.DebitNote, ItemType.InternalDebitNote };

        readonly Dictionary<FinaliseRequest, int[]> _caseIdsForThisOpenItemMap = new();

        public FinaliseBillValidator(IDbContext dbContext, IBillingSiteSettingsResolver billingSiteSettingsResolver)
        {
            _dbContext = dbContext;
            _billingSiteSettingsResolver = billingSiteSettingsResolver;
        }
        
        public async Task<IEnumerable<FinaliseValidationSummary>> Validate(FinaliseRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var validationSummary = new List<FinaliseValidationSummary>();

            if (await _dbContext.Set<OpenItem>().AnyAsync(_ => _.ItemEntityId == request.ItemEntityId &&
                                                               _.ItemTransactionId == request.ItemTransactionId &&
                                                               !SuitableForValidation.Contains(_.TypeId)))
            {
                return validationSummary;
            }

            var settings = await _billingSiteSettingsResolver.Resolve(new BillingSiteSettingsScope { Scope = SettingsResolverScope.WithoutUserSpecificSettings });
            
            await WarnIfDraftBillOnSameCaseExist(request, settings, validationSummary);

            await WarnIfNonIncludedDebitWipExist(request, settings, validationSummary);

            await WarnIfUnpostedTimeExist(request, settings, validationSummary);

            return validationSummary;
        }

        async Task WarnIfUnpostedTimeExist(FinaliseRequest request, BillingSiteSettings settings, List<FinaliseValidationSummary> validationSummary)
        {
            if (settings.ShouldWarnIfUnpostedTimeExistOnBillFinalisation)
            {
                var caseIdsForSelectedOpenItem = await PopulateCaseIdForSelectedOpenItem(request);

                var casesImpacted = (await (from dr in _dbContext.Set<Diary>()
                                            join c in _dbContext.Set<Case>() on dr.CaseId equals c.Id into c1
                                            from c in c1
                                            where caseIdsForSelectedOpenItem.Contains(c.Id) &&
                                                  dr.IsTimer == 0 &&
                                                  dr.WipEntityId == null &&
                                                  dr.TransactionId == null &&
                                                  dr.TimeValue > 0
                                            select new FinaliseValidationCaseImpacted
                                            {
                                                CaseId = c.Id,
                                                CaseReference = c.Irn
                                            }).ToArrayAsync()).Distinct().ToArray();

                if (casesImpacted.Length > 0)
                {
                    validationSummary.Add(new FinaliseValidationSummary
                    {
                        ErrorCode = KnownErrors.CasesOnThisBillHasUnpostedTime,
                        ErrorMessage = KnownErrors.CodeMap[KnownErrors.CasesOnThisBillHasUnpostedTime],
                        EntityId = request.ItemEntityId,
                        TransactionId = request.ItemTransactionId,
                        OpenItemNo = request.OpenItemNo,
                        IsConfirmationRequired = true,
                        CasesImpacted = casesImpacted
                    });
                }
            }
        }

        async Task WarnIfNonIncludedDebitWipExist(FinaliseRequest request, BillingSiteSettings settings, List<FinaliseValidationSummary> validationSummary)
        {
            if (settings.ShouldWarnIfNonIncludedDebitWipExistOnBillFinalisation)
            {
                var caseIdsForSelectedOpenItem = await PopulateCaseIdForSelectedOpenItem(request);

                var casesImpacted = (await (from wip in _dbContext.Set<WorkInProgress>()
                                            join c in _dbContext.Set<Case>() on wip.CaseId equals c.Id into c1
                                            from c in c1
                                            where caseIdsForSelectedOpenItem.Contains(c.Id) &&
                                                  wip.Status == TransactionStatus.Active &&
                                                  wip.LocalValue > 0
                                            select new FinaliseValidationCaseImpacted
                                            {
                                                CaseId = c.Id,
                                                CaseReference = c.Irn
                                            }).ToArrayAsync()).Distinct().ToArray();

                if (casesImpacted.Length > 0)
                {
                    validationSummary.Add(new FinaliseValidationSummary
                    {
                        ErrorCode = KnownErrors.CasesOnThisBillHasUnbilledWip,
                        ErrorMessage = KnownErrors.CodeMap[KnownErrors.CasesOnThisBillHasUnbilledWip],
                        EntityId = request.ItemEntityId,
                        TransactionId = request.ItemTransactionId,
                        OpenItemNo = request.OpenItemNo,
                        IsConfirmationRequired = true,
                        CasesImpacted = casesImpacted
                    });
                }
            }
        }

        async Task WarnIfDraftBillOnSameCaseExist(FinaliseRequest request, BillingSiteSettings settings, List<FinaliseValidationSummary> validationSummary)
        {
            if (settings.ShouldWarnIfDraftBillForSameCaseExistOnBillFinalisation)
            {
                var caseIdsForSelectedOpenItem = await PopulateCaseIdForSelectedOpenItem(request);

                var otherBilledItemReferencingSameCases = from b in _dbContext.Set<BilledItem>()
                                                          join w in _dbContext.Set<WorkInProgress>() on
                                                              new
                                                              {
                                                                  b.WipEntityId,
                                                                  b.WipTransactionId,
                                                                  b.WipSequenceNo
                                                              }
                                                              equals new
                                                              {
                                                                  WipEntityId = w.EntityId,
                                                                  WipTransactionId = w.TransactionId,
                                                                  w.WipSequenceNo
                                                              }
                                                              into w1
                                                          from w in w1
                                                          where w.CaseId != null && caseIdsForSelectedOpenItem.Contains((int)w.CaseId)
                                                          select b;

                var openItemsCollection = (await (from op in _dbContext.Set<OpenItem>()
                                                  join bi in otherBilledItemReferencingSameCases on
                                                      new
                                                      {
                                                          EntityId = op.ItemEntityId,
                                                          TransactionId = op.ItemTransactionId
                                                      }
                                                      equals new
                                                      {
                                                          bi.EntityId,
                                                          bi.TransactionId
                                                      }
                                                      into bi2
                                                  from bi in bi2
                                                  where op.Status == TransactionStatus.Draft &&
                                                        SuitableForValidation.Contains(op.TypeId) &&
                                                        (op.ItemEntityId != request.ItemEntityId || op.ItemTransactionId != request.ItemTransactionId) &&
                                                        op.OpenItemNo != request.OpenItemNo
                                                  select op.OpenItemNo).ToArrayAsync()).Distinct().ToArray();

                if (openItemsCollection.Any())
                {
                    validationSummary.Add(new FinaliseValidationSummary
                    {
                        ErrorCode = KnownErrors.OtherDraftBillsExistsForCasesOnThisBill,
                        ErrorMessage = KnownErrors.CodeMap[KnownErrors.OtherDraftBillsExistsForCasesOnThisBill],
                        EntityId = request.ItemEntityId,
                        TransactionId = request.ItemTransactionId,
                        OpenItemNo = request.OpenItemNo,
                        IsConfirmationRequired = true,
                        BillsImpacted = openItemsCollection.Distinct()
                    });
                }
            }
        }

        async Task<int[]> PopulateCaseIdForSelectedOpenItem(FinaliseRequest request)
        {
            if (_caseIdsForThisOpenItemMap.TryGetValue(request, out var r))
            {
                return r;
            }

            _caseIdsForThisOpenItemMap.Add(request, (await (from b in _dbContext.Set<BilledItem>()
                                                            join w in _dbContext.Set<WorkInProgress>() on
                                                                new
                                                                {
                                                                    b.WipEntityId,
                                                                    b.WipTransactionId,
                                                                    b.WipSequenceNo
                                                                }
                                                                equals new
                                                                {
                                                                    WipEntityId = w.EntityId,
                                                                    WipTransactionId = w.TransactionId,
                                                                    w.WipSequenceNo
                                                                }
                                                                into w1
                                                            from w in w1
                                                            where b.EntityId == request.ItemEntityId &&
                                                                  b.TransactionId == request.ItemTransactionId &&
                                                                  w.CaseId != null
                                                            select (int)w.CaseId).ToArrayAsync()).Distinct().ToArray());
            return _caseIdsForThisOpenItemMap[request];
        }
    }

    public class FinaliseValidationSummary
    {
        public string ErrorCode { get; set; }
        public string ErrorMessage { get; set; }
        public int EntityId { get; set; }
        public int TransactionId { get; set; }
        public string OpenItemNo { get; set; }
        public DateTime ItemDate { get; set; }
        public bool? IsConfirmationRequired { get; set; }
        public bool? IsError { get; set; }

        public IEnumerable<FinaliseValidationCaseImpacted> CasesImpacted { get; set; }

        public IEnumerable<string> BillsImpacted { get; set; }
    }

    public class FinaliseValidationCaseImpacted
    {
        public int CaseId { get; set; }
        public string CaseReference { get; set; }
    }

    public class FinaliseRequest
    {
        public int ItemEntityId { get; set; }
        public int ItemTransactionId { get; set; }
        public string OpenItemNo { get; set; }
    }
}
