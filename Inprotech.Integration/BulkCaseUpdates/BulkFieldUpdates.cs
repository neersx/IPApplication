using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.Properties;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkFieldUpdates
    {
        Task BulkUpdateCases(BulkCaseUpdatesArgs request);
        int AddBackgroundProcess(BackgroundProcessSubType subType);
    }

    public class BulkFieldUpdates : IBulkFieldUpdates
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IBulkFieldUpdateHandler _bulkFieldUpdateHandler;
        readonly Func<DateTime> _now;
        readonly IBatchedSqlCommand _batchedSqlCommand;

        public BulkFieldUpdates(IDbContext dbContext, ISecurityContext securityContext,
                                IBulkFieldUpdateHandler bulkFieldUpdateHandler,
                                Func<DateTime> now, IBatchedSqlCommand batchedSqlCommand)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _bulkFieldUpdateHandler = bulkFieldUpdateHandler;
            _now = now;
            _batchedSqlCommand = batchedSqlCommand;
        }

        public int AddBackgroundProcess(BackgroundProcessSubType subType)
        {
            var process = new BackgroundProcess
            {
                IdentityId = _securityContext.User.Id,
                ProcessType = BackgroundProcessType.GlobalCaseChange.ToString(),
                Status = (int)StatusType.Started,
                StatusDate = _now(),
                ProcessSubType = subType != BackgroundProcessSubType.NotSet ? subType.ToString() : null
            };
            _dbContext.Set<BackgroundProcess>().Add(process);
            _dbContext.SaveChanges();
            return process.Id;
        }

        public async Task BulkUpdateCases(BulkCaseUpdatesArgs request)
        {
            var process = _dbContext.Set<BackgroundProcess>().FirstOrDefault(_ => _.Id == request.ProcessId);

            if (process == null)
            {
                return;
            }

            try
            {
                using (var tcs = CreateTransactionScope(TimeSpan.Zero))
                {
                    _dbContext.SetCommandTimeOut(TimeSpan.Zero.Seconds);
                    var unAuthorizedCases = new List<int>();
                    var hasInvalidCasesForGoodsClass = false;
                    var count = 0;
                    const int recordsPicked = 1000;
                    var cases = request.CaseIds.Skip(0).Take(recordsPicked).ToArray();
                    while (cases.Any())
                    {
                        var selectedCases = await _bulkFieldUpdateHandler.GetCases(cases);
                        unAuthorizedCases.AddRange(selectedCases.UnauthorizedCases);

                        await AddGlobalCaseChangeResults(selectedCases.AuthorizedCases, process.Id);
                        await AddGlobalCaseChangeResults(selectedCases.UnauthorizedCases, process.Id);

                        var casesToBeUpdated = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().Where(c => selectedCases.AuthorizedCases.Contains(c.Id));
                        var bulkUpdateResult = await _bulkFieldUpdateHandler.Update(casesToBeUpdated, request);

                        if (bulkUpdateResult.HasInvalidCasesForGoodsWithClass)
                        {
                            hasInvalidCasesForGoodsClass = true;
                        }
                        count++;
                        cases = request.CaseIds.Skip(recordsPicked * count).Take(recordsPicked).ToArray();
                    }

                    process.Status = (int)StatusType.Completed;
                    if (hasInvalidCasesForGoodsClass)
                    {
                        process.StatusInfo = process.StatusInfo + Environment.NewLine + string.Format(Alerts.InvalidCasesForGoodsAndServicesWithClass,request.SaveData.CaseText.Class);
                    }
                    if (unAuthorizedCases.Any())
                    {
                        process.StatusInfo = Alerts.UnAuthorisedCases + Environment.NewLine + string.Join(", ", unAuthorizedCases); 
                    }
                    await _dbContext.SaveChangesAsync();
                    tcs.Complete();
                    _dbContext.SetCommandTimeOut(null);
                }
            }
            catch (Exception exception)
            {
                process.Status = (int)StatusType.Error;
                process.StatusInfo = Alerts.BulkUpdate_Fails;
                await _dbContext.SaveChangesAsync();
                throw;
            }
        }

        async Task AddGlobalCaseChangeResults(int[] cases, int processId)
        {
            if(!cases.Any()) return;
            var caseList = string.Join(",", cases.Select(_ => _));
            var parameters = new Dictionary<string, object>
            {
                {"@processId", processId }
            };

            var insertCommand = new StringBuilder(@"
            INSERT INTO GLOBALCASECHANGERESULTS(PROCESSID, CASEID)
		    SELECT @processId, CASEID
            FROM CASES where CASEID in (" + caseList+ ")");

            await _batchedSqlCommand.ExecuteAsync(insertCommand.ToString(), parameters);
        }
        
        public TransactionScope CreateTransactionScope(TimeSpan timeout)
        {
            var oSystemType = typeof(global::System.Transactions.TransactionManager);
            var oCachedMaxTimeout = 
                oSystemType.GetField("_cachedMaxTimeout", 
                                     System.Reflection.BindingFlags.NonPublic | 
                                     System.Reflection.BindingFlags.Static);
            var oMaximumTimeout = 
                oSystemType.GetField("_maximumTimeout", 
                                     System.Reflection.BindingFlags.NonPublic | 
                                     System.Reflection.BindingFlags.Static);
            if (oCachedMaxTimeout != null) oCachedMaxTimeout.SetValue(null, true);
            if (oMaximumTimeout != null) oMaximumTimeout.SetValue(null, timeout);
            return new TransactionScope(TransactionScopeOption.RequiresNew, timeout, TransactionScopeAsyncFlowOption.Enabled);
        }
    }
}
