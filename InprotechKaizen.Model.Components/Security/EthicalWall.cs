using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IEthicalWall
    {
        IEnumerable<int> AllowedCases(params int[] caseIds);
    }

    public class EthicalWall : IEthicalWall
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public EthicalWall(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
        }

        public IEnumerable<int> AllowedCases(params int[] caseIds)
        {
            var userId = _securityContext.User.Id;

            const int chunkSize = 10000;

            if (caseIds.Length <= chunkSize)
            {
                return Filtered(userId, caseIds);
            }

            var result = new List<int>();

            var allCaseIds = caseIds.ToList();

            var currentChunk = allCaseIds.Take(chunkSize).ToArray();

            while (currentChunk.Any())
            {
                allCaseIds = allCaseIds.Except(currentChunk).ToList();

                var chunk = currentChunk;

                result.AddRange(Filtered(userId, chunk));

                currentChunk = allCaseIds.Take(chunkSize).ToArray();
            }
            return result;
        }

        IQueryable<int> Filtered(int userId, int[] caseIds)
        {
            return from c in _dbContext.CasesEthicalWall(userId)
                   where caseIds.Contains(c.CaseId)
                   select c.CaseId;
        }
    }
}