using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Characteristics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedJurisdictionCharacteristic
    {
        ValidatedCharacteristic GetJurisdiction(string jurisdictionId);
    }

    public class ValidatedJurisdictionCharacteristic : IValidatedJurisdictionCharacteristic
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDbContext _dbContext;

        public ValidatedJurisdictionCharacteristic(IPreferredCultureResolver preferredCultureResolver, IDbContext dbContext)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext = dbContext;
        }

        public ValidatedCharacteristic GetJurisdiction(string jurisdictionId)
        {
            if (string.IsNullOrWhiteSpace(jurisdictionId))
                return new ValidatedCharacteristic();

            var culture = _preferredCultureResolver.Resolve();

            var jurisdiction = _dbContext.Set<Country>().FirstOrDefault(_ => _.Id == jurisdictionId);

            return jurisdiction == null ? null : new ValidatedCharacteristic(jurisdiction.Id, DbFuncs.GetTranslation(jurisdiction.Name, null, jurisdiction.NameTId, culture));
        }
    }
}
