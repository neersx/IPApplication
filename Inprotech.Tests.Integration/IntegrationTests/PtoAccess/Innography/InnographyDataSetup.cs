using System;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Queries;
using InprotechCase = InprotechKaizen.Model.Cases.Case;
using IntegrationCase = Inprotech.Integration.Case;

namespace Inprotech.Tests.Integration.IntegrationTests.PtoAccess.Innography
{
    public class InnographyDataSetup : DbSetup
    {
        public Family CreateFamily()
        {
            return InsertWithNewId(new Family
            {
                Name = RandomString.Next(20) + "InnographyFamily"
            });
        }

        public InprotechCase BuildInprotechCase(string countryCode, string propertyType, Family family)
        {
            var caseType = DbContext.Set<CaseType>().Single(_ => _.Code == "A");
            var country = DbContext.Set<Country>().Single(_ => _.Id == countryCode);
            var property = DbContext.Set<PropertyType>().Single(_ => _.Code == propertyType);

            return InsertWithNewId(new InprotechCase(RandomString.Next(20), country, caseType, property)
            {
                Title = RandomString.Next(20),
                Family = family
            });
        }

        public InnographyDataSetup AddOfficialNumber(InprotechCase @case, string numberTypeCode, string number)
        {
            var numberType = DbContext.Set<NumberType>().Single(_ => _.NumberTypeCode == numberTypeCode);

            @case.OfficialNumbers.Add(new OfficialNumber(numberType, @case, number)
            {
                IsCurrent = 1
            });

            DbContext.SaveChanges();

            return this;
        }

        public InnographyDataSetup AddOfficialNumberAndDate(InprotechCase @case, string numberTypeCode, string number, DateTime? date)
        {
            var numberType = DbContext.Set<NumberType>().Single(_ => _.NumberTypeCode == numberTypeCode);

            @case.OfficialNumbers.Add(new OfficialNumber(numberType, @case, number)
            {
                IsCurrent = 1
            });

            // For the purpose of this integration test, it is okay as long as we are dealing with Defaults 
            // 'A' ==> 'Application' ==> -4
            // 'P' ==> 'Publication' ==> -36
            // 'R' ==> 'Registration/Grant' ==> -8
            @case.CaseEvents.Add(new CaseEvent(@case.Id, numberType.RelatedEventId.Value, 1)
            {
                EventDate = date,
                IsOccurredFlag = 1
            });

            DbContext.SaveChanges();

            return this;
        }

        public InnographyDataSetup ChangeOfficialNumber(InprotechCase @case, string numberTypeCode, string oldNumber, string newNumber)
        {
            var officialNumber = @case.OfficialNumbers.Single(_ => _.NumberTypeId == numberTypeCode && _.Number == oldNumber);
            officialNumber.Number = newNumber;

            DbContext.SaveChanges();

            return this;
        }

        public InnographyDataSetup DeleteOfficialNumber(InprotechCase @case, string numberTypeCode, string number)
        {
            var officialNumber = @case.OfficialNumbers.Single(_ => _.NumberTypeId == numberTypeCode && _.Number == number);
            @case.OfficialNumbers.Remove(officialNumber);

            DbContext.Set<OfficialNumber>().Remove(officialNumber);

            DbContext.SaveChanges();

            return this;
        }

        public Query CreateQuery(Family family)
        {
            var filterCriteria = new XElement("csw_ListCase",
                                              new XElement("FilterCriteriaGroup",
                                                           new XElement("FilterCriteria",
                                                                        new XElement("FamilyKey",
                                                                                     new XAttribute("Operator", 0),
                                                                                     family.Id
                                                                                    )))
                                             ).ToString();

            return Insert(new Query
            {
                ContextId = (int) QueryContext.CaseSearch,
                Name = RandomString.Next(20),
                Filter = new QueryFilter
                {
                    ProcedureName = KnownProcedureNames.ListCase,
                    XmlFilterCriteria = filterCriteria
                }
            });
        }

        public void ChangePropertyType(InprotechCase @case, string propertyType)
        {
            var property = DbContext.Set<PropertyType>().Single(_ => _.Code == propertyType);
            @case.PropertyType = property;

            DbContext.SaveChanges();
        }

        public void ChangeCountry(InprotechCase @case, string countryCode)
        {
            var country = DbContext.Set<Country>().Single(_ => _.Id == countryCode);
            @case.Country = country;

            DbContext.SaveChanges();
        }

        public void AddCpaGlobalIdentifier(int caseId, string identifier, bool isActive = true)
        {
            var globalIdentifier = DbContext.Set<CpaGlobalIdentifier>().FirstOrDefault(x => x.CaseId == caseId);

            globalIdentifier = globalIdentifier ?? DbContext.Set<CpaGlobalIdentifier>().Add(new CpaGlobalIdentifier { CaseId = caseId, InnographyId = identifier, IsActive = isActive });
            globalIdentifier.InnographyId = identifier;
            globalIdentifier.IsActive = isActive;
            DbContext.SaveChanges();
        }

        public int CountCpaGlobalIdentifierFor(int caseId)
        {
            return DbContext.Set<CpaGlobalIdentifier>().Count(_ => _.CaseId == caseId);
        }

        public int CreateDataMappingFor(string name)
        {
            var e = InsertWithNewId(new Event { Description = RandomString.Next(30) });

            InsertWithNewId(new Mapping
            {
                InputDescription = name,
                DataSourceId = -5,
                StructureId = KnownMapStructures.Events,
                OutputValue = e.Id.ToString()
            });
            return e.Id;
        }

        public void AddEvent(InprotechCase @case, int eventId, DateTime date)
        {
            @case.CaseEvents.Add(new CaseEvent(@case.Id, eventId, 1)
            {
                EventDate = date,
                IsOccurredFlag = 1
            });

            DbContext.SaveChanges();
        }

        public void ChangeEventDate(InprotechCase @case, int eventId, DateTime date)
        {
            @case.CaseEvents.Single(_ => _.EventNo == eventId).EventDate = date;
            DbContext.SaveChanges();
        }

        public void DeleteEventDate(InprotechCase @case, int eventId)
        {
            var theEvent = @case.CaseEvents.Single(_ => _.EventNo == eventId);
            @case.CaseEvents.Remove(theEvent);
            DbContext.SaveChanges();
        }
    }
}