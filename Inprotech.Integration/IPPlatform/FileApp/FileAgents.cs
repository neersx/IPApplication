using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileAgents
    {
        bool TryGetAgentId(int caseId, out string agentId);

        IQueryable<RegisteredFileAgent> Available();

        IQueryable<string> FilesInJuridictions();
    }

    public class FileAgents : IFileAgents
    {
        readonly IDbContext _dbContext;

        public FileAgents(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<RegisteredFileAgent> Available()
        {
            return from n in _dbContext.Set<NameAlias>()
                   where n.AliasType.Code == KnownAliasTypes.FileAgentId && n.Alias != null
                   select new RegisteredFileAgent
                   {
                       AgentId = n.Alias,
                       Name = n.Name
                   };
        }

        public IQueryable<string> FilesInJuridictions()
        {
            return (from f in _dbContext.Set<FilesIn>()
                    join na in _dbContext.Set<NameAlias>() on f.NameId equals na.Name.Id into na1
                    from na in na1
                    where na.AliasType.Code == KnownAliasTypes.FileAgentId && na.Alias != null
                    select f.JurisdictionId)
                .DefaultIfEmpty()
                .Where(_ => _ != null)
                .Distinct();
        }

        public bool TryGetAgentId(int caseId, out string agentId)
        {
            agentId = null;
            var agents = (from cn in _dbContext.Set<CaseName>()
                          where cn.NameTypeId == KnownNameTypes.Agent && cn.CaseId == caseId
                          join na in _dbContext.Set<NameAlias>() on cn.NameId equals na.Name.Id into na1
                          from na in na1.DefaultIfEmpty()
                          select new FileAgent
                          {
                              CaseId = cn.CaseId,
                              NameId = cn.NameId,
                              Sequence = cn.Sequence,
                              FileAgentId = na != null && na.AliasType.Code == KnownAliasTypes.FileAgentId && na.Alias != null
                                  ? na.Alias
                                  : null
                          }).ToArray();
            
            if (agents.Any() && agents.All(_ => string.IsNullOrWhiteSpace(_.FileAgentId)))
            {
                // all agents are not known to FILE
                return false;
            }

            agentId = agents
                .OrderBy(_ => _.Sequence)
                .FirstOrDefault(_ => !string.IsNullOrWhiteSpace(_.FileAgentId))?
                .FileAgentId;

            return true;
        }
    }

    public class RegisteredFileAgent
    {
        public Name Name { get; set; }

        public string AgentId { get; set; }
    }

    public class FileAgent
    {
        public string FileAgentId { get; set; }

        public int CaseId { get; set; }

        public int NameId { get; set; }

        public short Sequence { get; set; }
    }
}