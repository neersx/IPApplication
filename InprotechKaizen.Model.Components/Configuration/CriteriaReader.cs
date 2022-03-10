using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Configuration
{
    public interface ICriteriaReader
    {
        bool TryGetScreenCriteriaId(int caseId, string programId, out int? screenCriteriaId);
        bool TryGetEventControl(int caseId, string action, out int? criteriaId);
        bool TryGetNameScreenCriteriaId(int nameId, string programId, out int? screenCriteriaId);
    }

    public class CriteriaReader : ICriteriaReader
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISecurityContext _securityContext;

        public CriteriaReader(IDbContext dbContext, ISecurityContext securityContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _now = now;
        }

        public bool TryGetScreenCriteriaId(int caseId, string programId, out int? screenCriteriaId)
        {
            return TryGetCriteria(caseId, CriteriaPurposeCodes.WindowControl, programId, out screenCriteriaId);
        }

        public bool TryGetEventControl(int caseId, string action, out int? criteriaId)
        {
            if (string.IsNullOrWhiteSpace(action)) throw new ArgumentNullException(nameof(action));

            return TryGetCriteria(caseId, CriteriaPurposeCodes.EventsAndEntries, action, out criteriaId);
        }

        public bool TryGetNameScreenCriteriaId(int nameId, string programId, out int? screenCriteriaId)
        {
            return TryGetNameCriteria(nameId, CriteriaPurposeCodes.WindowControl, programId, out screenCriteriaId);
        }

        bool TryGetCriteria(int caseId, string purposeCode, string genericParam, out int? criteriaId)
        {
            var now = _now();

            var profileId = _securityContext.User.Profile?.Id;

            var r = _dbContext.Set<Case>()
                              .Where(c => c.Id == caseId)
                              .Select(c => new
                              {
                                  c.Irn,
                                  CriteriaId = DbFuncs.GetCriteriaNo(c.Id, purposeCode, genericParam, now, profileId)
                              })
                              .SingleOrDefault();

            if (r != null)
            {
                criteriaId = r.CriteriaId;
                return true;
            }

            criteriaId = null;
            return false;
        }

        bool TryGetNameCriteria(int nameId, string purposeCode, string genericParam, out int? criteriaId)
        {
            var profileId = _securityContext.User.Profile?.Id;

            var r = _dbContext.Set<Name>()
                              .Where(c => c.Id == nameId)
                              .Select(c => new
                              {
                                  c.Id,
                                  CriteriaId = DbFuncs.GetCriteriaNoForName(c.Id, purposeCode, genericParam, profileId)
                              })
                              .SingleOrDefault();

            if (r != null)
            {
                criteriaId = r.CriteriaId;
                return true;
            }

            criteriaId = null;
            return false;
        }
    }
}