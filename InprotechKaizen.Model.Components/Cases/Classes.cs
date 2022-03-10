using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Caching;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IClasses
    {
       TmClass GetLocalClass(string propertyId, string countryId, string localClass);
    }

    public class Classes : IClasses
    {
        readonly IDbContext _dbContext;
        private ILifetimeScopeCache _perLifetime;

        public Classes(IDbContext dbContext, ILifetimeScopeCache perLifetime)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (perLifetime == null) throw new ArgumentNullException("perLifetime");

            _dbContext = dbContext;
            _perLifetime = perLifetime;
        }

        private IEnumerable<TmClass> Initialize(string propertyId, string countryId)
        {
            return _perLifetime.GetOrAdd(this,
                                         new {propertyId, countryId},
                                         x =>
                                             {
                                                 var countryCode = KnownValues.DefaultCountryCode;

                                                 if (_dbContext.Set<TmClass>().Any(_ => _.PropertyType == propertyId && _.CountryCode == countryId))
                                                     countryCode = countryId;

                                                 return _dbContext.Set<TmClass>()
                                                                  .Where(_ => _.PropertyType == propertyId && _.CountryCode == countryCode);
                                             });
        }

        public TmClass GetLocalClass(string propertyId, string countryId, string localClass)
        {
            var tmClass = Initialize(propertyId, countryId)
                .FirstOrDefault(_ => StripLeadingZeros(_.Class) == StripLeadingZeros(localClass));

            if (tmClass == null)
                throw new Exception("TM Class is not available for the provided class -" + localClass);

            return tmClass;
        }

        static string StripLeadingZeros(string classId)
        {
            return classId.TrimStart('0');
        }
    }
}
