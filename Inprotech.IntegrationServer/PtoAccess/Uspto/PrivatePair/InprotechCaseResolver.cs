using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Notifications;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    
    public interface IInprotechCaseResolver
    {
        IEnumerable<EligibleCase> ResolveUsing(string applicationNumber);
    }

    public class InprotechCaseResolver : IInprotechCaseResolver
    {
        readonly IDbContext _dbContext;

        public InprotechCaseResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<EligibleCase> ResolveUsing(string applicationNumber)
        {
            if (string.IsNullOrWhiteSpace(applicationNumber)) throw new ArgumentNullException(nameof(applicationNumber));

            var systemCode = ExternalSystems.SystemCode(DataSourceType.UsptoPrivatePair);

            var numbers = from o in _dbContext.Set<OfficialNumber>()
                          where o.IsCurrent == 1 && o.NumberTypeId == KnownNumberTypes.Application
                                && (applicationNumber == o.Number ||
                                    applicationNumber == DbFuncs.ConvertToPctShortFormat(o.Number) ||
                                    applicationNumber == DbFuncs.StripNonAlphanumerics(o.Number))
                          select o;

            return from e in _dbContext.FilterEligibleCasesForComparison(systemCode)
                   join c in _dbContext.Set<CaseIndexes>() on e.CaseKey equals c.CaseId into c1
                   from c in c1
                   where e.IsLiveCase
                         && c.GenericIndex == applicationNumber
                         && c.Source == CaseIndexSource.OfficialNumbers
                         && numbers.Any(_ => _.CaseId == c.CaseId)
                   select new EligibleCase
                          {
                              SystemCode = systemCode,
                              CaseKey = e.CaseKey,
                              ApplicationNumber = e.ApplicationNumber,
                              PublicationNumber = e.PublicationNumber,
                              RegistrationNumber = e.RegistrationNumber,
                              CountryCode = e.CountryCode
                          };
        }
    }
}