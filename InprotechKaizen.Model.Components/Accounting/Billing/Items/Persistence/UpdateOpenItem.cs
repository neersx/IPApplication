using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class UpdateOpenItem : IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly IBilledItems _billedItems;
        readonly IClassicUserResolver _classicUserResolver;
        readonly ILogger<UpdateOpenItem> _logger;

        public UpdateOpenItem(IDbContext dbContext, 
                              IBilledItems billedItems,
                              IClassicUserResolver classicUserResolver,
                              ILogger<UpdateOpenItem> logger)
        {
            _dbContext = dbContext;
            _billedItems = billedItems;
            _classicUserResolver = classicUserResolver;
            _logger = logger;
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

            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            var itemEntityId = (int)model.ItemEntityId;
            var itemTransactionId = (int)model.ItemTransactionId;

            await _billedItems.Reinstate(itemEntityId, itemTransactionId, result.RequestId);

            await UpdateTransactionHeader(userIdentityId, itemEntityId, itemTransactionId, model, result);

            return !result.HasError;
        }

        async Task UpdateTransactionHeader(int userIdentityId, int entityId, int transactionId, OpenItemModel model, SaveOpenItemResult result)
        {
            var classicUserId = await _classicUserResolver.Resolve(userIdentityId);

            var transactionHeader = await (from th in _dbContext.Set<TransactionHeader>()
                                           where th.EntityId == entityId &&
                                                 th.TransactionId == transactionId
                                           select th).SingleAsync();

            transactionHeader.TransactionDate = model.ItemDate;
            transactionHeader.StaffId = model.StaffId;
            transactionHeader.IdentityId = userIdentityId;
            transactionHeader.UserLoginId = classicUserId;
            transactionHeader.Source = SystemIdentifier.TimeAndBilling;
            transactionHeader.TransactionStatus = TransactionStatus.Draft;
            
            await _dbContext.SaveChangesAsync();

            // to pull LogDateTimeStamp that is populated by the triggers
            _dbContext.Reload(transactionHeader);

            result.TransactionId = model.ItemTransactionId = transactionHeader.TransactionId;
            result.LogDateTimeStamp = model.LogDateTimeStamp = transactionHeader.LogDateTimeStamp;
            
            _logger.Trace($"{nameof(UpdateTransactionHeader)}", transactionHeader);
        }
    }
}
