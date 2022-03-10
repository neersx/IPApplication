using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemTaxPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly ILogger<OpenItemTaxPersistence> _logger;

        public OpenItemTaxPersistence(IDbContext dbContext, ILogger<OpenItemTaxPersistence> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public Stage Stage => Stage.SaveOpenItemTax;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (!settings.TaxRequired) return true;
            
            if (result == null) throw new ArgumentNullException(nameof(result));

            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null || model.AccountEntityId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)}, {nameof(model.ItemTransactionId)} and {nameof(model.AccountEntityId)} must all have a value.");
            }

            foreach (var debitOrCreditNote in model.DebitOrCreditNotes)
            {
                foreach (var tax in debitOrCreditNote.Taxes)
                {
                    AddOpenItemTax((int)model.ItemEntityId, 
                                   (int)model.ItemTransactionId, 
                                   (int)model.AccountEntityId, 
                                   debitOrCreditNote.DebtorNameId, 
                                   tax);
                }
            }
                
            await _dbContext.SaveChangesAsync();

            return true;
        }

        void AddOpenItemTax(int itemEntityId, int itemTransactionId, int accountEntityId, int debtorNameId, DebitOrCreditNoteTax tax)
        {
            var openItemTax = _dbContext.Set<OpenItemTax>().Add(new OpenItemTax
            {
                ItemEntityId = itemEntityId,
                ItemTransactionId = itemTransactionId,
                AccountEntityId = accountEntityId,
                AccountDebtorId = debtorNameId,
                TaxCode = tax.TaxCode,
                TaxRate = tax.TaxRate,
                TaxableAmount = tax.TaxableAmount,
                TaxAmount = tax.TaxAmount,
                ForeignTaxableAmount = tax.ForeignTaxableAmount,
                ForeignTaxAmount = tax.ForeignTaxAmount,
                Currency = !string.IsNullOrWhiteSpace(tax.Currency) && tax.ForeignTaxAmount != null
                    ? tax.Currency
                    : null
            });
            
            _logger.Trace("InsertOpenItemTax", openItemTax);
        }
    }
}
