using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseClasses
    {
        IEnumerable<TmClass> Get(Case @case);
    }

    public class CaseClasses : ICaseClasses
    {
        readonly IDbContext _dbContext;

        public CaseClasses(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<TmClass> Get(Case @case)
        {
            var all = _dbContext.Set<TmClass>().AsQueryable();
            var allowSubClass = @case.PropertyType != null && @case.PropertyType.AllowSubClass == 1m;

            var localClasses = @case.LocalClasses.Split(',');

            var classCountry = all.Any(_ => _.CountryCode == @case.CountryId
                                            && _.PropertyType == @case.PropertyTypeId)
                ? @case.CountryId
                : KnownValues.DefaultCountryCode;

            var relevantClasses = all.Where(_ => _.CountryCode == classCountry
                                                 && _.PropertyType == @case.PropertyTypeId &&
                                                 (localClasses.Contains(_.Class + "." + _.SubClass) && _.SubClass != null
                                                  || localClasses.Contains(_.Class) && _.SubClass == null));

            var filtered = !allowSubClass
                ? relevantClasses.Where(_ => _.SequenceNo == all.Where(c => c.CountryCode == _.CountryCode
                                                                            && c.PropertyType == _.PropertyType
                                                                            && c.Class.Equals(_.Class)).Min(c => c.SequenceNo))
                : relevantClasses;

            return filtered.ToArray();
        }
    }
}
