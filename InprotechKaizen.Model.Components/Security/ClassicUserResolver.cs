using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IClassicUserResolver
    {
        Task<string> Resolve(int userIdentityId, bool? resolveSystemUser = true);
    }

    public class ClassicUserResolver : IClassicUserResolver
    {
        readonly IDbContext _dbContext;

        public ClassicUserResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<string> Resolve(int userIdentityId, bool? resolveSystemUser = true)
        {
            var user = await (from cu in _dbContext.Set<ClassicUser>()
                              where cu.UserIdentity.Id == userIdentityId
                              select cu.Name).FirstOrDefaultAsync();

            if (string.IsNullOrWhiteSpace(user) && resolveSystemUser == true)
            {
                using var cmd = _dbContext.CreateSqlCommand("select system_user");

                user = await cmd.ExecuteScalarAsync() as string;
            }

            return user;
        }
    }
}