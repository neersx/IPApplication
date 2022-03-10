using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security.Access
{
    public class AllowableProgramsResolver : IAllowableProgramsResolver
    {
        readonly ISecurityContext _securityContext;
        readonly IDbContext _dbContext;
        readonly IListPrograms _listCasePrograms;

        public AllowableProgramsResolver(ISecurityContext securityContext, IDbContext dbContext, IListPrograms listCasePrograms)
        {
            _securityContext = securityContext;
            _dbContext = dbContext;
            _listCasePrograms = listCasePrograms;
        }

        public async Task<IEnumerable<string>> Resolve()
        {
            var profileId = _securityContext.User?.Profile?.Id;
            var defaultProgram = _listCasePrograms.GetDefaultCaseProgram();
            if (profileId != null)
            {
                return await (from program in _dbContext.Set<ProfileProgram>()
                               where program.ProfileId == profileId || program.ProgramId == defaultProgram
                               select program.ProgramId).Distinct().ToArrayAsync();
            }

            return new [] { defaultProgram };
        }
    }
}
