using System;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class DebtorHistoryPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly IApplicationAlerts _applicationAlerts;
        readonly ILogger<DebtorHistoryPersistence> _logger;

        public DebtorHistoryPersistence(IDbContext dbContext, IApplicationAlerts applicationAlerts, ILogger<DebtorHistoryPersistence> logger)
        {
            _dbContext = dbContext;
            _applicationAlerts = applicationAlerts;
            _logger = logger;
        }

        public Stage Stage => Stage.PostDebtorHistoryForCreditNote;
        
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

            return !model.IsCredit() || await PostDebtorHistoryForCreditNotes(userIdentityId, culture, model, result, itemEntityId, itemTransactionId);
        }

        async Task<bool> PostDebtorHistoryForCreditNotes(int userIdentityId, string culture, OpenItemModel model, SaveOpenItemResult result, int itemEntityId, int itemTransactionId)
        {
            try
            {
                using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.PostDebtorHistory,
                                                                            new Parameters
                                                                            {
                                                                                { "@pnUserIdentityId", userIdentityId },
                                                                                { "@psCulture", culture },
                                                                                { "@pnItemEntityNo", itemEntityId },
                                                                                { "@pnItemTransNo", itemTransactionId },
                                                                                { "@pnMovementType", MovementClass.Entered },
                                                                                { "@psReasonCode", model.CreditReason },
                                                                                { "@pdtPostDate", DBNull.Value },
                                                                                { "@pnPostPeriod", DBNull.Value },
                                                                                { "@pbPostCredits", false }
                                                                            });

                await command.ExecuteNonQueryAsync();

                _logger.Trace($"{nameof(PostDebtorHistoryForCreditNotes)} CreditReason={model.CreditReason}");
            }
            catch (SqlException e)
            {
                if (_applicationAlerts.TryParse(e.Message, out var applicationAlerts))
                {
                    var alert = applicationAlerts.First();
                    result.ErrorCode = alert.AlertID;
                    result.ErrorDescription = alert.Message;

                    _logger.Warning($"{nameof(PostDebtorHistoryForCreditNotes)} alert={result.ErrorCode}/{result.ErrorDescription}");

                    return false;
                }

                throw;
            }

            return true;
        }
    }
}
