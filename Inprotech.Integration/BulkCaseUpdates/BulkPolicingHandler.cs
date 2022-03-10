using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkPolicingHandler
    {
        Task BulkPolicingAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated,  IQueryable<GlobalCaseChangeResults> gncResults);
    }
    public class BulkPolicingHandler : IBulkPolicingHandler
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IBatchedSqlCommand _batchedSqlCommand;
        readonly IPolicingEngine _policingEngine;

        public BulkPolicingHandler(IDbContext dbContext,
                                   ISecurityContext securityContext,
                                   IBatchedSqlCommand batchedSqlCommand,
                                   IPolicingEngine policingEngine)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _batchedSqlCommand = batchedSqlCommand;
            _policingEngine = policingEngine;
        }

        public async Task BulkPolicingAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, IQueryable<GlobalCaseChangeResults> gncResults)
        {
            if (string.IsNullOrWhiteSpace(request.CaseAction))
            {
                return;
            }

            var caseAction = _dbContext.Set<Action>().FirstOrDefault(_ => _.Code == request.CaseAction);
            if (caseAction == null)
            {
                throw new ArgumentException("Case Action not found");
            }

            var batchNo = _policingEngine.CreateBatch();

            await AddPolicingRows(casesToBeUpdated.ToArray(), request.CaseAction, batchNo);

            await _policingEngine.PoliceWithoutTransaction(batchNo);

            await _dbContext.UpdateAsync(gncResults, _ => new GlobalCaseChangeResults
            {
                IsPoliced = true
            });
        }

        async Task AddPolicingRows(InprotechKaizen.Model.Cases.Case[] casesToBeUpdated, string action, int batchNo)
        {
            var caseList = string.Join(",", casesToBeUpdated.Select(_ => _.Id));
            var parameters = new Dictionary<string, object>
            {
                {"@action", action },
                {"@batchNo", batchNo },
                {"@userIdentityId", _securityContext.User.Id }
            };

            var insertCommand = new StringBuilder(@"
            declare @T TABLE (idx int identity(5000, 1), CASEID int, ACTION nvarchar(2), CYCLE smallint)

            INSERT INTO @T (CASEID, ACTION, CYCLE)
            SELECT C.CASEID, @action, ISNULL(OA.CYCLE, 1)
            FROM CASES C 
            left join OPENACTION OA on (OA.CASEID = C.CASEID and OA.ACTION = @action and POLICEEVENTS=1)
            where C.CASEID in (" + caseList + ")");

            insertCommand.Append(@"
            INSERT INTO POLICING(DATEENTERED, POLICINGNAME, POLICINGSEQNO, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION, CYCLE, TYPEOFREQUEST,
				        SQLUSER, BATCHNO, CASEID, IDENTITYID)
		    SELECT getDate(), convert(varchar, getDate(), 126) + convert(varchar, idx), idx, 1, 1, ACTION, CYCLE, 1,
                        SYSTEM_USER, @batchNo, CASEID, @userIdentityId
            FROM @T");

            await _batchedSqlCommand.ExecuteAsync(insertCommand.ToString(), parameters);
        }
    }
}
