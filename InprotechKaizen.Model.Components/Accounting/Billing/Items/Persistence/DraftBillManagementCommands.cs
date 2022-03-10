using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IDraftBillManagementCommands
    {
        Task Delete(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys);

        Task Delete(int userIdentityId, string culture, int itemEntityId, string openItemNo);

        Task<FinaliseOpenItemResult> Finalise(int userIdentityId, string culture, int itemEntityId, int itemTransactionId, string enteredOpenItemXml, DateTime itemFinaliseDateOrItemDate);
    }

    public class DraftBillManagementCommands : IDraftBillManagementCommands
    {
        readonly IApplicationAlerts _applicationAlerts;
        readonly IDbContext _dbContext;

        public DraftBillManagementCommands(IDbContext dbContext, IApplicationAlerts applicationAlerts)
        {
            _dbContext = dbContext;
            _applicationAlerts = applicationAlerts;
        }

        public async Task Delete(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys)
        {
            if (mergeXmlKeys == null) throw new ArgumentNullException(nameof(mergeXmlKeys));

            await Execute(userIdentityId, culture, mergeXmlKeys);
        }

        public async Task Delete(int userIdentityId, string culture, int itemEntityId, string openItemNo)
        {
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));

            await Execute(userIdentityId, culture, itemEntityId: itemEntityId, openItemNo: openItemNo);
        }

        public async Task<FinaliseOpenItemResult> Finalise(int userIdentityId, string culture,
                                                           int itemEntityId, int itemTransactionId,
                                                           string enteredOpenItemXml,
                                                           DateTime itemFinaliseDateOrItemDate)
        {
            try
            {
                var debtorOpenItemNos = new List<DebtorOpenItemNo>();
                var reconciliationErrors = new List<string>();

                using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.FinaliseOpenItem,
                                                                            new Parameters
                                                                            {
                                                                                { "@pnUserIdentityId", userIdentityId },
                                                                                { "@psCulture", culture },
                                                                                { "@pnItemEntityNo", itemEntityId },
                                                                                { "@pnItemTransNo", itemTransactionId },
                                                                                { "@ptXMLEnteredOpenItems", enteredOpenItemXml },
                                                                                { "@pdtItemDate", itemFinaliseDateOrItemDate }
                                                                            });

                using var dr = await command.ExecuteReaderAsync();

                while (await dr.ReadAsync())
                    debtorOpenItemNos.Add(new DebtorOpenItemNo
                    {
                        DebtorId = dr.GetField<int>("DebtorNo"),
                        OpenItemNo = dr.GetField<string>("OpenItemNo"),
                        OfficeItemNoTo = dr.GetField<decimal?>("OfficeItemNoTo"),
                        OfficeDescription = dr.GetField<string>("OfficeDescription")
                    });

                await dr.NextResultAsync();

                if (await dr.NextResultAsync())
                {
                    while (await dr.ReadAsync())
                    {
                        var reconciliationErrorXml = dr.GetString(0);
                        reconciliationErrors.Add(reconciliationErrorXml);
                    }
                }

                return new FinaliseOpenItemResult(debtorOpenItemNos, reconciliationErrors);
            }
            catch (SqlException e)
            {
                if (_applicationAlerts.TryParse(e.Message, out var alerts))
                {
                    return new FinaliseOpenItemResult(alerts);
                }

                throw;
            }
        }

        async Task Execute(int userIdentityId, string culture, MergeXmlKeys mergeXmlKeys = null, int? itemEntityId = null, string openItemNo = null)
        {
            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.Billing.DeleteDraftBill, new Parameters
            {
                { "@pnUserIdentityId", userIdentityId },
                { "@psCulture", culture },
                { "@pnItemEntityNo", itemEntityId },
                { "@psItemNo", openItemNo },
                { "@psMergeXMLKeys", mergeXmlKeys?.ToString() }
            });

            await command.ExecuteNonQueryAsync();
        }
    }

    public class FinaliseOpenItemResult
    {
        public IEnumerable<DebtorOpenItemNo> DebtorOpenItemNos { get; } = new List<DebtorOpenItemNo>();
        public IEnumerable<string> ReconciliationErrors { get; } = new List<string>();
        public IEnumerable<ApplicationAlert> Alerts { get; } = new List<ApplicationAlert>();

        public FinaliseOpenItemResult(IEnumerable<ApplicationAlert> alerts)
        {
            Alerts = alerts;
        }

        public FinaliseOpenItemResult(IEnumerable<DebtorOpenItemNo> debtorOpenItemNos, IEnumerable<string> reconciliationErrors)
        {
            DebtorOpenItemNos = debtorOpenItemNos;
            ReconciliationErrors = reconciliationErrors;
        }
    }
}