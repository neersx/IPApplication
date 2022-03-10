using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Persistence;
using BillLineModel = InprotechKaizen.Model.Accounting.Billing.BillLine;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Presentation
{
    public interface IBillLines
    {
        Task<IEnumerable<BillLine>> Retrieve(int entityId, int transactionId);
        
        Task<IEnumerable<BillLine>> Retrieve(MergeXmlKeys mergeXmlKeys);

        Task<XElement> GenerateMappedValuesXml(int userIdentityId, string culture, int billFormatId, int entityId, int debtorId, int? caseId, XElement draftBillLines);
    }

    public class BillLines : IBillLines
    {
        readonly IDbContext _dbContext;

        public BillLines(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<BillLine>> Retrieve(int entityId, int transactionId)
        {
            return await Retrieve(new OpenItemXmlKey { ItemEntityNo = entityId, ItemTransNo = transactionId });
        }

        public async Task<IEnumerable<BillLine>> Retrieve(MergeXmlKeys mergeXmlKeys)
        {
            if (mergeXmlKeys == null) throw new ArgumentNullException(nameof(mergeXmlKeys));
            
            return await Retrieve(mergeXmlKeys.OpenItemXmls.ToArray());
        }

        async Task<IEnumerable<BillLine>> Retrieve(params OpenItemXmlKey[] keySets)
        {
            var first = keySets[0];

            var billLines = _dbContext
                            .Set<BillLineModel>()
                            .Where(_ => _.ItemEntityId == first.ItemEntityNo &&
                                        _.ItemTransactionId == first.ItemTransNo);

            foreach (var keySet in keySets.Skip(1))
            {
                // TODO: review performance -- maybe use PredicateBuilder.
                var thisBillLine = _dbContext
                                   .Set<BillLineModel>()
                                   .Where(_ => _.ItemEntityId == keySet.ItemEntityNo &&
                                               _.ItemTransactionId == keySet.ItemTransNo);

                billLines = billLines.Union(thisBillLine);
            }

            var result = await billLines.Select(b => new BillLine
            {
                ItemEntityId = b.ItemEntityId,
                ItemTransactionId = b.ItemTransactionId,
                ItemLineNo = b.ItemLineNo,
                WipCode = b.WipCode,
                WipTypeId = b.WipTypeId,
                CategoryCode = b.CategoryCode,
                CaseRef = b.CaseReference,
                Value = b.Value,
                DisplaySequence = b.DisplaySequence ?? 0,
                PrintDate = b.PrintDate,
                PrintName = b.PrintName,
                PrintChargeOutRate = b.PrintChargeOutRate,
                PrintTotalUnits = b.PrintTotalUnits,
                UnitsPerHour = b.UnitsPerHour,
                NarrativeId = b.NarrativeId,
                Narrative = b.LongNarrative == null ? b.ShortNarrative : b.LongNarrative,
                ForeignValue = b.ForeignValue,
                PrintChargeCurrency = b.PrintChargeCurrency,
                PrintTime = b.PrintTime,
                LocalTax = b.LocalTax,
                GeneratedFromTaxCode = b.GeneratedFromTaxCode,
                IsHiddenForDraft = b.IsHiddenForDraft,
                TaxCode = b.TaxCode
            }).ToListAsync();

            if (result.Sum(_ => _.Value.GetValueOrDefault()) < 0)
            {
                foreach (var billLine in result)
                    billLine.ReverseSigns();
            }

            return result;
        }

        public async Task<XElement> GenerateMappedValuesXml(int userIdentityId, string culture, int billFormatId, int entityId, int debtorId, int? caseId, XElement draftBillLines)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GenerateMappedValuesXml,
                                                                        new Parameters
                                                                        {
                                                                            {"@pnUserIdentityId", userIdentityId},
                                                                            {"@psCulture", culture},
                                                                            {"@pnBillFormatKey", billFormatId },
                                                                            {"@pnEntityKey", entityId },
                                                                            {"@pnMainDebtorKey", debtorId },
                                                                            {"@pnMainCaseKey", caseId },
                                                                            {"@ptXMLBillLines", draftBillLines.ToString()}
                                                                        });

            var xml = await command.ExecuteScalarAsync() as string;

            return string.IsNullOrWhiteSpace(xml)
                ? null
                : XElement.Parse(xml);
        }
    }
}
