using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt.Maintenance
{
    public interface IPriorArtMaintenanceValidator
    {
        bool ExistingPriorArt(string countryCode, string officialNumber, string kindCode);
        bool ExistingLiterature(string description, string name, string title, string refDocumentParts, string publisher, string city, string countryCode);
    }
    public class PriorArtMaintenanceValidator : IPriorArtMaintenanceValidator
    {
        readonly IDbContext _dbContext;

        public PriorArtMaintenanceValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        public bool ExistingPriorArt(string countryCode, string officialNumber, string kindCode)
        {
            var number = officialNumber.StripNonAlphanumerics().TrimStart(countryCode.ToCharArray()).TrimEnd(kindCode?.ToUpper().ToCharArray());
            return _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Any(v => v.CountryId == countryCode && v.OfficialNumber == number);
        }

        public bool ExistingLiterature(string description, string name, string title, string refDocumentParts, string publisher, string city, string countryCode)
        {
            if (!string.IsNullOrWhiteSpace(description))
                return _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Any(v => v.Description == description);

            return _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>()
                             .Any(v => v.Name == name && v.Title == title && v.RefDocumentParts == refDocumentParts 
                                       && v.Publisher == publisher && v.City == city && v.CountryId == countryCode);
        }
    }
}
