using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Persistence;
using BillLineEntity = InprotechKaizen.Model.Accounting.Billing.BillLine;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class BillLinePersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly ILogger<BillLinePersistence> _logger;

        public BillLinePersistence(IDbContext dbContext, ILogger<BillLinePersistence> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }
        
        public Stage Stage => Stage.SaveBillLines;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            var lineNo = (short) 1;
            foreach (var billLine in model.BillLines)
            {
                AddBillLine((int)model.ItemEntityId, (int)model.ItemTransactionId, lineNo, billLine);

                billLine.ItemLineNo = lineNo;

                lineNo++;
            }

            await _dbContext.SaveChangesAsync();

            return true;
        }

        void AddBillLine(int itemEntityId, int itemTransactionId, short lineNo, BillLine billLine)
        {
            var shortNarrative = billLine.SplitNarrative().ShortNarrative;
            var longNarrative = billLine.SplitNarrative().LongNarrative;
            var billLineEntity = _dbContext.Set<BillLineEntity>().Add(new BillLineEntity
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                ItemLineNo = lineNo,
                CaseReference = billLine.CaseRef,
                WipCode = billLine.WipCode,
                WipTypeId = billLine.WipTypeId,
                CategoryCode = billLine.CategoryCode,
                UnitsPerHour = billLine.UnitsPerHour,
                Value = billLine.Value,
                ForeignValue = billLine.ForeignValue,
                TaxCode = billLine.TaxCode,
                LocalTax = billLine.LocalTax,
                NarrativeId = billLine.NarrativeId,
                ShortNarrative = shortNarrative,
                LongNarrative = longNarrative,
                DisplaySequence = billLine.DisplaySequence,
                PrintTime = billLine.PrintTime,
                PrintDate = billLine.PrintDate?.Date,
                PrintName = billLine.PrintName,
                PrintTotalUnits = billLine.PrintTotalUnits,
                PrintChargeOutRate = billLine.PrintChargeOutRate,
                PrintChargeCurrency = billLine.PrintChargeCurrency,
                GeneratedFromTaxCode = billLine.GeneratedFromTaxCode
                                               .NullIfEmptyOrWhitespace(),
                IsHiddenForDraft = billLine.IsHiddenForDraft
            });

            _logger.Trace($"InsertBillLine lineNo={lineNo}", billLineEntity);
        }
    }
}
