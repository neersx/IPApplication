using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security.ExternalApplications;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExternalApplications.Security.Authentication.User
{
    public class UserValidator : IUserValidator
    {
        readonly IDbContext _dbContext;

        public UserValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<bool> ValidateUser(string loginId)
        {
            return await _dbContext.Set<InprotechKaizen.Model.Security.User>()
                                   .AnyAsync(user => user.UserName == loginId);
        }
    }
}