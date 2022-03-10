using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IDraftWipManagementCommands
    {
        Task<(IEnumerable<RemappedWipItems> RemappedWipItems, IEnumerable<ApplicationAlert> Alerts)> CopyDraftWip(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys, int itemEntityId, int itemTransactionId);
    }

    public class DraftWipManagementCommands : IDraftWipManagementCommands
    {
        readonly IDbContext _dbContext;
        readonly IApplicationAlerts _applicationAlerts;

        public DraftWipManagementCommands(IDbContext dbContext, IApplicationAlerts applicationAlerts)
        {
            _dbContext = dbContext;
            _applicationAlerts = applicationAlerts;
        }

        public async Task<(IEnumerable<RemappedWipItems> RemappedWipItems, IEnumerable<ApplicationAlert> Alerts)> CopyDraftWip(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys, int itemEntityId, int itemTransactionId)
        {
            if (mergeXmlKeys == null) throw new ArgumentNullException(nameof(mergeXmlKeys));

            var remappedWipItems = new List<RemappedWipItems>();

            try
            {
                using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.CopyDraftWip, new Parameters
                {
                    { "@pnUserIdentityId", userIdentityId },
                    { "@psCulture", culture },
                    { "@psMergeXMLKeys", mergeXmlKeys.ToString() },
                    { "@pnMergeIntoEntityNo", itemEntityId },
                    { "@pnMergeIntoTransNo", itemTransactionId }
                });

                using var dr = await command.ExecuteReaderAsync();
                {
                    while (await dr.ReadAsync())
                    {
                        remappedWipItems.Add(new RemappedWipItems
                        {
                            EntityId = dr.GetField<int>("OriginalEntityNo"),
                            TransactionId = dr.GetField<int>("OriginalTransNo"),
                            WipSeqNo = dr.GetField<short>("OriginalWIPSeqNo"),
                            NewWipSeqNo = dr.GetField<short>("NewWIPSeqNo")
                        });
                    }
                }
            }
            catch (SqlException sqlException)
            {
                if (_applicationAlerts.TryParse(sqlException.Message, out var applicationAlerts))
                {
                    return (remappedWipItems, applicationAlerts);
                }

                throw;
            }

            return (remappedWipItems, Enumerable.Empty<ApplicationAlert>());
        }
    }

    public class RemappedWipItems
    {
        public int EntityId { get; set; }
        public int TransactionId { get; set; }
        public short WipSeqNo { get; set; }
        public short NewWipSeqNo { get; set; }
    }
}
