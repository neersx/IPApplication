using System;
using System.Collections.Generic;
using System.Linq;
using System.Transactions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IPolicingStatusReader
    {
        string Read(int caseId);

        IDictionary<int, string> ReadMany(IEnumerable<int> caseIds);
    }

    public class PolicingStatusReader : IPolicingStatusReader
    {
        public const string Error = "Error";
        public const string Running = "Running";
        public const string Pending = "Pending";
        public const string OnHold = "OnHold";
        public const string Complete = "Complete";

        readonly IDbContext _dbContext;

        public PolicingStatusReader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public string Read(int caseId)
        {
            var result = ReadMany(new[] { caseId });

            if (!result.ContainsKey(caseId))
                return null;

            return result[caseId];
        }

        /* ReadMany method is an optmized version of below algorithm. Please update the comment whenever the code changes.
        var policing =
            _dbContext.Set<PolicingRequest>()
                .Where(p => p.IsSystemGenerated == 1 && p.CaseId == caseId)
                .ToArray();

        if (!policing.Any())
            return null;

        var pol = policing.Where(p => p.OnHold >= 1 && p.OnHold <= 4).ToArray();
        if (pol.Any())
        {
            var startTime = pol.Min(p => p.DateEntered);
            var error =
                _dbContext.Set<PolicingError>()
                    .Any(_ => _.StartDateTime >= startTime && _.CaseId == caseId);

            if (error)
                return Error;

            if (pol.Any(p => p.OnHold != 1))
                return Running;
        }

        if (policing.Any(p => p.OnHold == 0 || p.OnHold == 1))
            return Pending;

        if (policing.Any(p => p.OnHold == 9))
            return OnHold;
         */
        public IDictionary<int, string> ReadMany(IEnumerable<int> caseIds)
        {
            if (caseIds == null)
                return new Dictionary<int, string>();

            using (_dbContext.BeginTransaction(IsolationLevel.ReadUncommitted))
            {
                var policing = _dbContext.Set<PolicingRequest>()
                    .Where(p => p.IsSystemGenerated == 1 && p.CaseId.HasValue && caseIds.Contains(p.CaseId.Value))
                    .GroupJoin(_dbContext.Set<PolicingError>(), k1 => k1.CaseId, k2 => k2.CaseId,
                        (i1, i2) =>
                            new
                            {
                                Policing = new { i1.DateEntered, i1.CaseId, i1.OnHold },
                                Errors = i2.Select(e => new { e.StartDateTime })
                            })
                    .GroupBy(p => p.Policing.CaseId.Value)
                    .Select(g => new { g.Key, MinStartDate = g.Min(p => p.Policing.DateEntered), Grouping = g })
                    .ToArray();

                var remaining = caseIds;
                var errors = policing.Where(p => p.Grouping.Any(g => g.Policing.OnHold >= 1 && g.Policing.OnHold <= 4))
                    .ToDictionary(p => p.Key, p =>
                    {
                        if (
                            p.Grouping.Any(
                                g => g.Errors.Any(e => e != null && e.StartDateTime >= p.MinStartDate)))
                        {
                            return Error;
                        }

                        if (p.Grouping.Any(g => g.Policing.OnHold != 1))
                        {
                            return Running;
                        }

                        return Pending;
                    });

                remaining = remaining.Except(errors.Keys);

                var pendingOnHold = policing.Where(
                    p => remaining.Contains(p.Key) && p.Grouping.Any(g => g.Policing.OnHold == 0 || g.Policing.OnHold == 9))
                    .ToDictionary(p => p.Key, p => p.Grouping.Any(g => g.Policing.OnHold == 0) ? Pending : OnHold);

                remaining = remaining.Except(pendingOnHold.Keys);

                var nulls = remaining.ToDictionary(c => c, c => (string)null);

                return errors.Concat(pendingOnHold).Concat(nulls).ToDictionary(k => k.Key, v => v.Value);
            }
        }
    }
}