using System;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.TempStorage;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseIdsResolver
    {
        string[] Resolve(SelectedCasesNotificationOptions filterOptions);
    }

    public class CaseIdsResolver : ICaseIdsResolver
    {
        readonly IDbContext _dbContext;

        public CaseIdsResolver(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public string[] Resolve(SelectedCasesNotificationOptions filterOptions)
        {
            if (filterOptions == null) throw new ArgumentNullException("filterOptions");
            if (string.IsNullOrWhiteSpace(filterOptions.Caselist) && filterOptions.Ts == null)
                throw new ArgumentException("Either case list or temporary storage id must be provided");

            var caseIds = (filterOptions.Caselist ?? string.Empty).Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries);
            if (!caseIds.Any())
            {
                caseIds = _dbContext.Set<TempStorage>()
                    .Single(_ => _.Id == filterOptions.Ts)
                    .Value.Split(',');
            }

            return caseIds;
        }
    }
}