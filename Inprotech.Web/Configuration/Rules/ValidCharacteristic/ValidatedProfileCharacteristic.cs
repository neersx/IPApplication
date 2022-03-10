using System.Linq;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{

    public interface IValidatedProfileCharacteristic
    {
        ValidatedCharacteristic GetProfile(string profileId);
    }

    public class ValidatedProfileCharacteristic : IValidatedProfileCharacteristic
    {
        readonly IDbContext _dbContext;
        public ValidatedProfileCharacteristic(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public ValidatedCharacteristic GetProfile(string profileId)
        {
            if (string.IsNullOrWhiteSpace(profileId))
                return null;

            var profile = _dbContext.Set<Profile>().FirstOrDefault(_ => _.Name == profileId);
            return profile == null ? null : new ValidatedCharacteristic(profile.Id.ToString(), profile.Name);
        }
    }
}
