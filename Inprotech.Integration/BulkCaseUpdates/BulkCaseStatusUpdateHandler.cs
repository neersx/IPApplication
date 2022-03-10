using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.GlobalCaseChange;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkCaseStatusUpdateHandler
    {
        Task UpdateCaseStatusAsync(BulkUpdateData data,
                                   IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, IQueryable<GlobalCaseChangeResults> gncCases);

        Task<IEnumerable<int>> GetRestrictedCasesForStatus(int[] cases, string statusCode);
    }

    public class BulkCaseStatusUpdateHandler : IBulkCaseStatusUpdateHandler
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _now;
        readonly IBatchedSqlCommand _batchedSqlCommand;
        readonly ISiteControlReader _siteControlReader;

        public BulkCaseStatusUpdateHandler(IDbContext dbContext, 
                                           ISecurityContext securityContext,
                                           Func<DateTime> now, 
                                           IBatchedSqlCommand batchedSqlCommand,
                                           ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _now = now;
            _batchedSqlCommand = batchedSqlCommand;
            _siteControlReader = siteControlReader;
        }

        public async Task UpdateCaseStatusAsync(BulkUpdateData data, 
                                         IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, IQueryable<GlobalCaseChangeResults> gncCases)
        {
            if (data.CaseStatus == null && data.RenewalStatus == null) return;
            var statusData = data.CaseStatus ?? data.RenewalStatus;
            var casesUpdatedForStatus = new List<int>();
            if (statusData.ToRemove)
            {
                if (statusData.IsRenewal)
                {
                    var selectedProperties = _dbContext.Set<CaseProperty>().Where(_ => casesToBeUpdated.Any(c => c.Id == _.CaseId));
                    if (selectedProperties.Any())
                    {
                        await _dbContext.UpdateAsync(selectedProperties, _ => new CaseProperty
                        {
                            RenewalStatusId = null,
                        });
                        casesUpdatedForStatus = selectedProperties.Select(_ => _.Case.Id).ToList();
                    }
                }
                else
                {
                    
                    await _dbContext.UpdateAsync(casesToBeUpdated, _ => new InprotechKaizen.Model.Cases.Case
                    {
                        StatusCode = null
                    });
                    casesUpdatedForStatus = casesToBeUpdated.Select(_ => _.Id).ToList();
                }
            }
            else
            {
                var statusKey = short.Parse(statusData.StatusCode);
                var status = _dbContext.Set<Status>().FirstOrDefault(_ => _.Id == statusKey);
                if (status != null && status.IsConfirmationRequired)
                {
                    var confPassword = _siteControlReader.Read<string>(SiteControls.ConfirmationPasswd);
                    if (!string.Equals(confPassword, statusData.Password))
                        return;
                }
                var stopPayReason = status?.StopPayReason;
                var restrictedCases = await GetRestrictedCasesForStatus(casesToBeUpdated.Select(_ => _.Id).ToArray(), statusData.StatusCode);
                var unRestrictedCases = restrictedCases != null ? casesToBeUpdated.Where(_ => !restrictedCases.Contains(_.Id)) : casesToBeUpdated;
                var caseOldStatusList = new List<OldCaseStatus>();

                var selectedCases = from c in unRestrictedCases
                                    join s in _dbContext.Set<Status>() on statusKey equals s.Id into s1
                                    from s in s1
                                    join vs in _dbContext.Set<ValidStatus>() on
                                        new {sc = s.Id, pt = c.PropertyType.Id, ct = c.Type.Id, cn = c.Country.Id }
                                        equals new {sc = vs.StatusCode, pt = vs.PropertyType.Id, ct = vs.CaseType.Id, cn = vs.Country.Id} into vs1
                                    from vs in vs1.DefaultIfEmpty()
                                    join vsc in _dbContext.Set<ValidStatus>() on
                                        new {sc = s.Id, pt = c.PropertyType.Id, ct = c.Type.Id, cn = InprotechKaizen.Model.KnownValues.DefaultCountryCode }
                                        equals new {sc = vsc.StatusCode, pt = vsc.PropertyType.Id, ct= vsc.CaseType.Id, cn = vsc.Country.Id} into vsc1
                                    from vsc in vsc1.DefaultIfEmpty()
                                    where vsc != null || vs != null
                                    select c;

                if (selectedCases.Any())
                {
                    if (statusData.IsRenewal)
                    {
                        var selectedProperties = _dbContext.Set<CaseProperty>().Where(_ => selectedCases.Any(c => c.Id == _.CaseId));
                        caseOldStatusList.AddRange(selectedProperties.Select(_ => new OldCaseStatus
                        {
                            CaseId = _.CaseId,
                            Status = _.RenewalStatusId
                        }));

                        if (selectedProperties.Any())
                        {
                            await _dbContext.UpdateAsync(selectedProperties, _ => new CaseProperty
                            {
                                RenewalStatusId = statusKey,
                            });
                        }
                        casesUpdatedForStatus = selectedProperties.Select(_ => _.Case.Id).ToList();
                    }
                    else
                    {
                        caseOldStatusList.AddRange(selectedCases.Select(_ => new OldCaseStatus
                        {
                            CaseId = _.Id,
                            Status = _.StatusCode
                        }));
                        
                        await _dbContext.UpdateAsync(selectedCases, _ => new InprotechKaizen.Model.Cases.Case
                        {
                            StatusCode = statusKey
                        });
                        casesUpdatedForStatus = selectedCases.Select(_ => _.Id).ToList();
                    }

                    if (!string.IsNullOrEmpty(stopPayReason))
                    {
                        await _dbContext.UpdateAsync(selectedCases, _ => new InprotechKaizen.Model.Cases.Case
                        {
                            StopPayReason = stopPayReason
                        });
                    }
                    if (casesUpdatedForStatus.Any())
                    {
                        await AddActivityHistory(casesUpdatedForStatus, statusKey);
                    }

                    AddPolicingRow(caseOldStatusList, statusKey);
                }
            }

            var gncResults = gncCases.Where(_ => casesUpdatedForStatus.Contains(_.CaseId));
            await _dbContext.UpdateAsync(gncResults, _ => new GlobalCaseChangeResults
            {
                StatusUpdated = true
            });
        }

        async Task AddActivityHistory(IEnumerable<int> cases, short statusKey)
        {
            var caseList = string.Join(",", cases);

            var parameters = new Dictionary<string, object>
            {
                {"@nStatusCode", statusKey},
                {"@pnUserIdentityId", _securityContext.User.Id},
                {"@dtWhenRequested", _now()}
            };

            await _batchedSqlCommand.ExecuteAsync(@"
            Insert into ACTIVITYHISTORY
			(	CASEID,
				WHENREQUESTED,
				SQLUSER,
				PROGRAMID,
				ACTION,
				EVENTNO,
				CYCLE,
				STATUSCODE,
				IDENTITYID)
			SELECT CASEID, @dtWhenRequested, SYSTEM_USER, null, null, null, null, @nStatusCode, @pnUserIdentityId
			from CASES where CASEID in (" + caseList+ ")", parameters);
        }

        void AddPolicingRow(IEnumerable<OldCaseStatus> cases, short statusKey)
        {
            var caseRowsToPolice = cases.Where(_ => _.Status.HasValue).ToArray();
            if (!caseRowsToPolice.Any()) return;

            var policeRows = (from c in caseRowsToPolice
                             join oa in _dbContext.Set<OpenAction>().Where(_ => _.PoliceEvents == 1) on c.CaseId equals oa.CaseId into oa1
                             from oa in oa1
                             join a in _dbContext.Set<InprotechKaizen.Model.Cases.Action>() on oa.Action.Id equals a.Id into a1
                             from a in a1
                             join old in _dbContext.Set<Status>() on c.Status equals old.Id into old1
                             from old in old1.DefaultIfEmpty()
                             join s in _dbContext.Set<Status>() on statusKey equals s.Id
                             where (a.ActionType == 0 && s.RenewalFlag == 0 && s.PoliceOtherActions == 1 && old.PoliceOtherActions.HasValue && old.PoliceOtherActions == 0) ||
                                   (a.ActionType == 2 && s.RenewalFlag == 0 && s.PoliceExam == 1 && old.PoliceExam.HasValue && old.PoliceExam == 0) ||
                                   (a.ActionType == 1 && s.PoliceRenewals == 1 && old.PoliceRenewals.HasValue && old.PoliceRenewals == 0)
                            select new 
                            {
                                c.CaseId,
                                oa.ActionId,
                                oa.Cycle
                            }).ToArray();

            if (!policeRows.Any()) return;
            var count = 1;
            var now = _now();
            _dbContext.AddRange(policeRows.Select(_ => new PolicingRequest(_.CaseId)
            {
                DateEntered = now,
                SequenceNo = count,
                Name = "Status-" + now.ToString("yyyy-MM-ddTHH:mm:ss.fff") + count++,
                IsSystemGenerated = 1,
                OnHold = 0,
                Action = _.ActionId,
                CaseId = _.CaseId,
                EventCycle = _.Cycle,
                TypeOfRequest = 1,
                IdentityId = _securityContext.User.Id
            }));
        }

        public async Task<IEnumerable<int>> GetRestrictedCasesForStatus(int[] cases, string statusCode)
        {
            if (!cases.Any()) return null;

            var statusKey = short.Parse(statusCode);
            var status = _dbContext.Set<Status>().First(st => st.Id == statusKey);
            var isPreventWip = status.PreventWip.HasValue && status.PreventWip.Value;
            var isPreventBilling = status.PreventBilling.HasValue && status.PreventBilling.Value;

            if (!isPreventWip && !isPreventBilling) return null;

            IEnumerable<int> restrictedCaseList = await _dbContext.Set<Diary>().Where(d => d.Case != null
                                                                        && cases.Contains(d.Case.Id)
                                                                        && d.WipEntityId == null
                                                                        && d.TransactionId == null
                                                                        && d.IsTimer == 0
                                                                        && d.TimeValue > 0)
                                               .Select(d => d.Case.Id).Distinct().ToArrayAsync();

            if (!isPreventBilling) return restrictedCaseList;

            var restrictedForBilling = await _dbContext.Set<WorkInProgress>()
                                                       .Where(wip => wip.Case != null
                                                                     && cases.Contains(wip.Case.Id))
                                                       .Select(wip => wip.Case.Id).Distinct().ToArrayAsync();
            return restrictedCaseList.Union(restrictedForBilling);
        }

        public class OldCaseStatus
        {
            public int CaseId { get; set; }
            public short? Status { get; set; }
        }
    }
}
