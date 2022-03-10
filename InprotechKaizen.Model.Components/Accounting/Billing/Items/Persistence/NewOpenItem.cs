using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class NewOpenItem : INewDraftBill
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly IClassicUserResolver _classicUserResolver;
        readonly ILogger<NewOpenItem> _logger;
        readonly Func<DateTime> _now;

        static readonly Dictionary<ItemType, TransactionType> ItemTypeTransactionTypeMap = new()
        {
            { ItemType.CreditNote, TransactionType.CreditNote },
            { ItemType.InternalCreditNote, TransactionType.InternalCreditNote },
            { ItemType.DebitNote, TransactionType.Bill },
            { ItemType.InternalDebitNote, TransactionType.InternalBill }
        };

        public NewOpenItem(IDbContext dbContext,
                           ILastInternalCodeGenerator lastInternalCodeGenerator,
                           IClassicUserResolver classicUserResolver,
                           ILogger<NewOpenItem> logger,
                           Func<DateTime> now)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _classicUserResolver = classicUserResolver;
            _logger = logger;
            _now = now;
        }

        public Stage Stage => Stage.Preprocess;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));

            if (model.ItemEntityId == null) throw new ArgumentException($"{nameof(model.ItemEntityId)} must have a value.");
            
            await CreateTransactionHeader(userIdentityId, (int)model.ItemEntityId, model, result);
            
            return true;
        }
        
        async Task CreateTransactionHeader(int userIdentityId, int entityId, OpenItemModel model, SaveOpenItemResult result)
        {
            var entryDate = _now();
            var transactionType = ItemTypeTransactionTypeMap[(ItemType)model.ItemType];
            var transactionId = _lastInternalCodeGenerator.GenerateLastInternalCode("TRANSACTIONHEADER");
            var classicUserId = await _classicUserResolver.Resolve(userIdentityId);

            var transactionHeader = _dbContext.Set<TransactionHeader>()
                                              .Add(new TransactionHeader
                                              {
                                                  EntityId = entityId,
                                                  Source = SystemIdentifier.TimeAndBilling,
                                                  TransactionStatus = TransactionStatus.Draft,
                                                  TransactionType = transactionType,
                                                  TransactionDate = model.ItemDate,
                                                  TransactionId = transactionId,
                                                  UserLoginId = classicUserId,
                                                  IdentityId = userIdentityId,
                                                  StaffId = model.StaffId,
                                                  EntryDate = entryDate
                                              });

            await _dbContext.SaveChangesAsync();

            // to pull LogDateTimeStamp that is populated by the triggers
            _dbContext.Reload(transactionHeader);

            result.TransactionId = model.ItemTransactionId = transactionHeader.TransactionId;
            result.LogDateTimeStamp = model.LogDateTimeStamp = transactionHeader.LogDateTimeStamp;

            _logger.Trace($"{nameof(CreateTransactionHeader)}", transactionHeader);
        }
    }
}
