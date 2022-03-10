using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IChangeAlertGeneratorCommands
    {
        Task Generate(int userIdentityId, string culture, int itemEntityId, int itemTransactionId, int debtorId,
                      int? nameIdForCopiesTo = null,
                      bool? hasDebtorChanged = false,
                      bool? hasDebtorReferenceChanged = false,
                      bool? hasAddressChanged = false,
                      bool? hasAttentionChanged = false,
                      int? addressChangeReasonId = null);

        Task Generate(int userIdentityId, string culture, int itemEntityId, int itemTransactionId,
                      string changeItem,
                      string oldValue,
                      string newValue,
                      int? caseId,
                      string reasonCode);
    }

    public class ChangeAlertGeneratorCommands : IChangeAlertGeneratorCommands
    {
        readonly IDbContext _dbContext;

        public ChangeAlertGeneratorCommands(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task Generate(int userIdentityId, string culture, int itemEntityId, int itemTransactionId, int debtorId,
                                   int? nameIdForCopiesTo = null,
                                   bool? hasDebtorChanged = false,
                                   bool? hasDebtorReferenceChanged = false,
                                   bool? hasAddressChanged = false,
                                   bool? hasAttentionChanged = false,
                                   int? addressChangeReasonId = null)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GenerateChangeAlert,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnUserIdentityId", userIdentityId },
                                                                            { "@psCulture", culture },
                                                                            { "@pnItemEntityNo", itemEntityId },
                                                                            { "@pnItemTransKey", itemTransactionId },
                                                                            { "@pnDebtorKey", debtorId },
                                                                            { "@pnNameKey", nameIdForCopiesTo },
                                                                            { "@pbHasDebtorChanged", hasDebtorChanged },
                                                                            { "@pbHasDebtorReferenceChanged", hasDebtorReferenceChanged },
                                                                            { "@pbHasAddressChanged", hasAddressChanged },
                                                                            { "@pbHasAttentionChanged", hasAttentionChanged },
                                                                            { "@pnAddressChangeReason", addressChangeReasonId }
                                                                        });

            await command.ExecuteNonQueryAsync();
        }

        public async Task Generate(int userIdentityId, string culture, int itemEntityId, int itemTransactionId,
                                   string changeItem,
                                   string oldValue,
                                   string newValue,
                                   int? caseId,
                                   string reasonCode)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.GenerateBillChangeAlert,
                                                                        new Parameters
                                                                        {
                                                                            { "@pnUserIdentityId", userIdentityId },
                                                                            { "@psCulture", culture },
                                                                            { "@pnItemEntityNo", itemEntityId },
                                                                            { "@pnItemTransKey", itemTransactionId },
                                                                            { "@psChangedItem", changeItem },
                                                                            { "@psOldValue", oldValue },
                                                                            { "@psNewValue", newValue },
                                                                            { "@pnCaseKey", caseId },
                                                                            { "@psReasonCode", reasonCode }
                                                                        });

            await command.ExecuteNonQueryAsync();
        }
    }
}
