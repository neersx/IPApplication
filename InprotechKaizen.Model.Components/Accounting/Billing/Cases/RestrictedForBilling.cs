using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Cases
{
    public interface IRestrictedForBilling
    {
        IQueryable<CaseData> Retrieve(CaseData[] cases);

        IQueryable<CaseData> Retrieve(int[] caseIds);
    }

    public class RestrictedForBilling : IRestrictedForBilling
    {
        readonly ICaseStatusValidator _caseStatusValidator;
        readonly IDbContext _dbContext;

        public RestrictedForBilling(IDbContext dbContext, ICaseStatusValidator caseStatusValidator)
        {
            _dbContext = dbContext;
            _caseStatusValidator = caseStatusValidator;
        }

        public IQueryable<CaseData> Retrieve(CaseData[] cases)
        {
            if (cases == null) throw new ArgumentNullException(nameof(cases));

            return Retrieve(cases.Select(_ => _.CaseId).ToArray());
        }

        public IQueryable<CaseData> Retrieve(params int[] caseIds)
        {
            var caseIdArray = caseIds.ToArray();

            return from c in _caseStatusValidator.GetCasesRestrictedForBilling(caseIdArray)
                   join s in _dbContext.Set<Status>() on c.StatusCode equals s.Id into s1
                   from s in s1
                   select new CaseData
                   {
                       CaseId = c.Id,
                       CaseReference = c.Irn,
                       CaseStatus = s.Name,
                       Title = c.Title,
                       OfficialNumber = c.CurrentOfficialNumber
                   };
        }
    }
}