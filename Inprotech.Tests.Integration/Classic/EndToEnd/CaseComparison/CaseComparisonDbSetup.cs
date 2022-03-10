using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechCase = InprotechKaizen.Model.Cases.Case;
using IntegrationCase = Inprotech.Integration.Case;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison
{
    public class CaseComparisonDbSetup
    {
        public InprotechCase BuildInprotechCase(string countryCode, string propertyType, string caseType = "A")
        {
            using (var db = new DbSetup())
            {
                var ctx = db.DbContext;
                return db.InsertWithNewId(new InprotechCase
                {
                    Irn = RandomString.Next(20),
                    Title = RandomString.Next(20),
                    Type = ctx.Set<CaseType>().Single(_ => _.Code == caseType),
                    Country = ctx.Set<Country>().Single(_ => _.Id == countryCode),
                    PropertyType = ctx.Set<PropertyType>().Single(_ => _.Code == propertyType)
                });
            }
        }

        public InprotechCase BuildInprotechCase(DataSourceType source)
        {
            var map = new Dictionary<DataSourceType, CriteriaDetail>
            {
                {DataSourceType.Epo, new CriteriaDetail("EP", "P")},
                {DataSourceType.UsptoPrivatePair, new CriteriaDetail("US", "P")},
                {DataSourceType.UsptoTsdr, new CriteriaDetail("US", "T")}
            };

            CriteriaDetail criteriaDetail;
            if (map.TryGetValue(source, out criteriaDetail))
            {
                return BuildInprotechCase(criteriaDetail.CountryCode, criteriaDetail.PropertyType);
            }

            throw new NotSupportedException("This data source type is not yet supported in this extension method.");
        }

        public CaseComparisonDbSetup BuildIntegrationEnvironment(DataSourceType source, Guid sessionGuid)
        {
            using (var db = new IntegrationDbSetup())
            {
                var schedule = db.Insert(new Schedule
                {
                    Name = RandomString.Next(20),
                    DataSourceType = source,
                    DownloadType = DownloadType.All,
                    CreatedBy = -1,
                    CreatedOn = DateTime.Now,
                    NextRun = DateTime.Parse("2030-01-01")
                });

                db.Insert(new ScheduleExecution(sessionGuid, schedule, DateTime.Now));

                return this;
            }
        }

        public IntegrationCase BuildIntegrationCase(DataSourceType source, int? inprotechCaseId, string applicationNumber = null, string publicationNumber = null, string registrationNumber = null)
        {
            using (var db = new IntegrationDbSetup())
            {
                return db.Insert(new IntegrationCase
                {
                    ApplicationNumber = applicationNumber,
                    PublicationNumber = publicationNumber,
                    RegistrationNumber = registrationNumber,
                    CorrelationId = inprotechCaseId,
                    Source = source,
                    CreatedOn = DateTime.Now,
                    UpdatedOn = DateTime.Now
                });
            }
        }

        public class CriteriaDetail
        {
            public CriteriaDetail(string countryCode, string propertyType)
            {
                CountryCode = countryCode;
                PropertyType = propertyType;
            }

            public string CountryCode { get; set; }

            public string PropertyType { get; set; }
        }
    }
}