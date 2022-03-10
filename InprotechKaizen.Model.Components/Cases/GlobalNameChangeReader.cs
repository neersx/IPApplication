using System;
using System.Linq;
using System.Transactions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IGlobalNameChangeReader
    {
        string Read(int caseId);
    }

    class GlobalNameChangeReader : IGlobalNameChangeReader
    {
        public const string Running = "Running";

        public const string Complete = "Complete";

        readonly IDbContext _dbContext;

        public GlobalNameChangeReader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public string Read(int caseId)
        {
            using (_dbContext.BeginTransaction(IsolationLevel.ReadUncommitted))
            {
                var gnc = _dbContext.Set<GlobalNameChangeRequest>().Any(_ => _.CaseId == caseId);

                return gnc ? Running : null;
            }
        }
    }
}
