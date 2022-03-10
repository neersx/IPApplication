using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public interface ICountryGroup
    {
        IEnumerable<string> GetMemberCountries(string countryKey);
    }

    public class CountryGroup : ICountryGroup
    {
        readonly IDbContext _dbContext;

        public CountryGroup(IDbContext dbContext)
        {
            if(dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public IEnumerable<string> GetMemberCountries(string countryKey)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.CountryGroup>()
                             .Where(
                                    c => c.Id == countryKey
                                         && (DateTime.Today < c.DateCeased || c.DateCeased == null)
                                         && (c.DateCommenced <= DateTime.Today || c.DateCommenced == null))
                             .Select(c => c.MemberCountry);
        }
    }
}