using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public interface IDebitOrCreditNotes
    {
        Task<IEnumerable<DebitOrCreditNote>> Retrieve(int userIdentityId, string culture, int entityId, int transactionId);
        Task<IEnumerable<DebitOrCreditNote>> MergedCreditItems(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys, int firstEntityId, int firstTransactionId);
        Task<IEnumerable<CreditItem>> AvailableCredits(int userIdentityId, string culture, int entityId, int[] caseIds, int[] debtorIds);
        Task<IEnumerable<CreditItem>> MergedAvailableCredits(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys);
    }

    public class DebitOrCreditNotes : IDebitOrCreditNotes
    {
        readonly IDbContext _dbContext;

        string[] _compatibilityFieldsMap;

        public DebitOrCreditNotes(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<DebitOrCreditNote>> Retrieve(int userIdentityId, string culture, int entityId, int transactionId)
        {
            return ReverseSignIfCreditNotes(await ExecuteAsync(userIdentityId, culture, null, entityId, transactionId));
        }

        public async Task<IEnumerable<DebitOrCreditNote>> MergedCreditItems(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys, int firstEntityId, int firstTransactionId)
        {
            if (mergeXmlKeys == null) throw new ArgumentNullException(nameof(mergeXmlKeys));

            return ReverseSignIfCreditNotes(await ExecuteAsync(userIdentityId, culture, mergeXmlKeys.ToString(), firstEntityId, firstTransactionId));
        }

        public async Task<IEnumerable<CreditItem>> AvailableCredits(int userIdentityId, string culture, int entityId, int[] caseIds, int[] debtorIds)
        {
            return await ExecuteAsync(userIdentityId, culture, firstEntityId: entityId, caseIds: caseIds, debtorIds: debtorIds);
        }

        public async Task<IEnumerable<CreditItem>> MergedAvailableCredits(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys)
        {
            if (mergeXmlKeys == null) throw new ArgumentNullException(nameof(mergeXmlKeys));

            return ResetAppliedCreditItems(await ExecuteAsync(userIdentityId, culture, mergeXmlKeys: mergeXmlKeys.ToString()));
        }

        async Task<IEnumerable<DebitOrCreditNote>> ExecuteAsync(int userIdentityId, string culture, string mergeXmlKeys, int firstEntityId, int firstTransactionId)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetDebitNotes,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnUserIdentityId", userIdentityId },
                                                                            { "@psCulture", culture },
                                                                            { "@pnItemEntityNo", firstEntityId },
                                                                            { "@pnItemTransNo", firstTransactionId },
                                                                            { "@psMergeXMLKeys", mergeXmlKeys }
                                                                        });

            var debitOrCreditNotes = new List<DebitOrCreditNote>();
            var debitOrCreditNoteTax = new List<DebitOrCreditNoteTax>();
            var creditItems = new List<CreditItem>();

            using var dr = await command.ExecuteReaderAsync();

            while (await dr.ReadAsync())
            {
                debitOrCreditNotes.Add(BuildDebitOrCreditNoteFromRawData(dr));
            }

            if (await dr.NextResultAsync())
            {
                while (await dr.ReadAsync())
                {
                    _compatibilityFieldsMap ??= Enumerable.Range(0, dr.FieldCount)
                                                          .Select(i => dr.GetName(i))
                                                          .ToArray();

                    debitOrCreditNoteTax.Add(BuildDebitOrCreditNoteTaxFromRawData(dr, _compatibilityFieldsMap));
                }
            }

            if (await dr.NextResultAsync())
            {
                while (await dr.ReadAsync())
                {
                    creditItems.Add(BuildCreditItemFromRawData(dr));
                }
            }

            foreach (var debitOrCreditNote in debitOrCreditNotes)
            {
                debitOrCreditNote.Taxes
                                 .AddRange(from tax in debitOrCreditNoteTax
                                           where tax.OpenItemNo == debitOrCreditNote.OpenItemNo
                                           select tax);

                debitOrCreditNote.CreditItems
                                 .AddRange(from creditItem in creditItems
                                           where creditItem.AccountDebtorId == debitOrCreditNote.DebtorNameId
                                           select creditItem);
            }

            return debitOrCreditNotes;
        }

        async Task<IEnumerable<CreditItem>> ExecuteAsync(int userIdentityId, string culture, 
                                                         string mergeXmlKeys = null, 
                                                         int? firstEntityId = null, int? firstTransactionId = null, 
                                                         int[] caseIds = null, int[] debtorIds = null)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GetBillCredits,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnUserIdentityId", userIdentityId },
                                                                            { "@psCulture", culture },
                                                                            { "@pnItemEntityNo", firstEntityId },
                                                                            { "@pnItemTransNo", firstTransactionId },   
                                                                            { "@psCaseKeyCSVList", IdsToCsv(caseIds) },
                                                                            { "@psDebtorKeyList", IdsToCsv(debtorIds) },
                                                                            { "@psMergeXMLKeys", mergeXmlKeys }
                                                                        });

            var creditItems = new List<CreditItem>();

            using var dr = await command.ExecuteReaderAsync();

            while (await dr.ReadAsync())
            {
                creditItems.Add(BuildCreditItemFromRawData(dr));
            }

            return creditItems;
        }

        static DebitOrCreditNote BuildDebitOrCreditNoteFromRawData(IDataRecord dr)
        {
            return new()
            {
                DebtorNameId = dr.GetField<int>("DebtorNameNo"),
                DebtorName = dr.GetField<string>("DebtorName"),
                OpenItemNo = dr.GetField<string>("OpenItemNo"),
                BillPercentage = dr.GetField<decimal?>("BillPercentage") ?? 0,
                Status = dr.GetField<int>("Status"),
                LocalValue = dr.GetField<decimal?>("LocalValue") ?? 0,
                LocalBalance = dr.GetField<decimal?>("LocalBalance") ?? 0,
                Currency = dr.GetField<string>("Currency"),
                ForeignValue = dr.GetField<decimal?>("ForeignValue"),
                ForeignBalance = dr.GetField<decimal?>("ForeignBalance"),
                ExchangeRate = dr.GetField<decimal?>("ExchRate"),
                AreCreditsAvailable = dr.GetField<decimal?>("CreditsAvailable"),
                IsPrinted = dr.GetField<bool>("PrintedFlag"),
                LocalTakenUp = dr.GetField<decimal?>("LocalTakenUp") ?? 0,
                ForeignTakenUp = dr.GetField<decimal?>("ForeignTakenUp"),
                ExchangeRateVariance = dr.GetField<decimal?>("ExchVariance"),
                ForeignTaxAmount = dr.GetField<decimal?>("ForeignTaxAmt"),
                LogDateTimeStamp = dr.GetField<DateTime?>("LogDateTimeStamp")
            };
        }

        static DebitOrCreditNoteTax BuildDebitOrCreditNoteTaxFromRawData(IDataRecord dr, string[] availableFields)
        {
            return new DebitOrCreditNoteTax
            {
                OpenItemNo = dr.GetField<string>("OpenItemNo"),
                DebtorNameId = dr.GetField<int>("DebtorNameNo"),
                TaxCode = dr.GetField<string>("TaxCode"),
                TaxDescription = dr.GetField<string>("TaxDescription"),
                Currency = availableFields.Contains("Currency")
                    ? dr.GetField<string>("Currency")
                    : null,
                TaxRate = dr.GetField<decimal?>("TaxRate"),
                TaxableAmount = dr.GetField<decimal?>("TaxableAmount") ?? 0,
                TaxAmount = dr.GetField<decimal>("TaxAmount"),
                ForeignTaxableAmount = availableFields.Contains("ForeignTaxableAmount")
                    ? dr.GetField<decimal>("ForeignTaxableAmount")
                    : 0,
                ForeignTaxAmount = availableFields.Contains("ForeignTaxAmount")
                    ? dr.GetField<decimal>("ForeignTaxAmount")
                    : 0
            };
        }

        static CreditItem BuildCreditItemFromRawData(IDataRecord dr)
        {
            return new CreditItem
            {
                BestFitScore = dr.GetField<int>("BestFitScore"),
                ItemEntityId = dr.GetField<int>("ItemEntityNo"),
                ItemTransactionId = dr.GetField<int>("ItemTransNo"),
                AccountEntityId = dr.GetField<int>("AcctEntityNo"),
                AccountDebtorId = dr.GetField<int>("AcctDebtorNo"),
                OpenItemNo = dr.GetField<string>("OpenItemNo"),
                ItemDate = dr.GetField<DateTime>("ItemDate"),
                LocalBalance = dr.GetField<decimal>("LocalBalance"),
                Currency = dr.GetField<string>("Currency"),
                ExchangeRate = dr.GetField<decimal?>("ExchRate"),
                ForeignBalance = dr.GetField<decimal?>("ForeignBalance"),
                IsForcedPayOut = dr.GetField<decimal>("ForcedPayOut") == 1,
                ReferenceText = dr.GetField<string>("ReferenceText"),
                CaseRef = dr.GetField<string>("IRN"),
                CaseId = dr.GetField<int?>("CaseKey"),
                ItemType = dr.GetField<int>("ItemType"),
                PayPropertyTypeKey = dr.GetField<string>("PayPropertyTypeKey"),
                PayPropertyName = dr.GetField<string>("PayPropertyName"),
                PayForWip = dr.GetField<string>("PayForWIP"),
                LocalBalanceOriginal = dr.GetField<decimal>("LocalBalance"),
                ForeignBalanceOriginal = dr.GetField<decimal?>("ForeignBalance"),
                LocalSelected = dr.GetField<decimal>("LocalSelected"),
                ForeignSelected = dr.GetField<decimal>("ForeignSelected"),
                IsLocked = dr.GetField<decimal>("IsLocked") == 1
            };
        }

        static IEnumerable<DebitOrCreditNote> ReverseSignIfCreditNotes(IEnumerable<DebitOrCreditNote> debitOrCreditNoteItems)
        {
            var items = debitOrCreditNoteItems.ToArray();

            if (items.Sum(_ => _.LocalValue) < 0)
            {
                foreach (var item in items)
                    item.ReverseSigns();
            }

            return items;
        }

        static IEnumerable<CreditItem> ResetAppliedCreditItems(IEnumerable<CreditItem> creditItems)
        {
            var items = creditItems.ToArray();

            foreach (var creditItem in items)
            {
                // to reset as they should have been applied.
                creditItem.LocalSelected = 0;
                creditItem.ForeignSelected = 0;
                creditItem.IsForcedPayOut = false;
            }

            return items;
        }

        static string IdsToCsv(int[] ids)
        {
            return ids == null
                ? null
                : string.Join(",", ids);
        }
    }
}
