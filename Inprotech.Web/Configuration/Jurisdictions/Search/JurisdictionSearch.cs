using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Jurisdictions
{
    public interface IJurisdictionSearch
    {
        IEnumerable<Country> Search(SearchOptions searchOptions);
    }

    public class JurisdictionSearch : IJurisdictionSearch
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _cultureResolver;

        public JurisdictionSearch(IDbContext dbContext, IPreferredCultureResolver cultureResolver)
        {
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
        }

        public IEnumerable<Country> Search(SearchOptions searchOptions)
        {
            var preferredCulture = _cultureResolver.Resolve();
            return _dbContext.Set<Country>()
                .Where(_ => _.Id.Contains(searchOptions.Text) || _.Name.Contains(searchOptions.Text))
                .Select(_ => new {_.Id, Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, preferredCulture), _.Type})
                .OrderBy(_ => _.Name)
                .ToList()
                .Select(_ => new Country(_.Id, _.Name, _.Type))
                .AsQueryable();
        }
    }
}