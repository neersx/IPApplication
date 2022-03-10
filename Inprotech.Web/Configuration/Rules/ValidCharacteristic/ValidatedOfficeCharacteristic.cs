using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Characteristics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedOfficeCharacteristic
    {
        ValidatedCharacteristic GetOffice(int? officeId);
    }

    public class ValidatedOfficeCharacteristic : IValidatedOfficeCharacteristic
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDbContext _dbContext;

        public ValidatedOfficeCharacteristic(IPreferredCultureResolver preferredCultureResolver, IDbContext dbContext)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _dbContext = dbContext;
        }

        public ValidatedCharacteristic GetOffice(int? officeId)
        {
            if (officeId == null)
                return new ValidatedCharacteristic();
            var culture = _preferredCultureResolver.Resolve();

            var office = _dbContext.Set<Office>().FirstOrDefault(_ => _.Id == officeId);

            return office == null ? null : new ValidatedCharacteristic(office.Id.ToString(), DbFuncs.GetTranslation(office.Name, null, office.NameTId, culture));
        }
    }
}
