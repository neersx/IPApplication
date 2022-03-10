using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Ede
{
    [TestFixture]
    [Category(Categories.Integration)]
    public class ResolveEventMapping : IntegrationTest
    {
        const int EventMapStructure = 5;
        const int IpOneDataSource = -5;
        const int CommonEncodingSchemeId = -1;

        [Test]
        public void DefaultMappingReturnsStandardEvents()
        {
            var result = DbSetup.Do(db =>
                                    {
                                        var required = new[] {"A", "P", "R"};

                                        var nt = db.DbContext.Set<NumberType>()
                                                   .Where(_ => required.Contains(_.NumberTypeCode))
                                                   .ToDictionary(k => k.NumberTypeCode, v => v.RelatedEventId);

                                        var mapping = db.DbContext
                                                        .ResolveEventMappings("Application,Publication,Registration/Grant", "IpOneData")
                                                        .ToDictionary(k => k.Code, v => v.MappedEventId);

                                        return (RelatedEvent: nt, Mapping: mapping);
                                    });

            Assert.AreEqual(result.RelatedEvent["A"], result.Mapping["Application"], $"Related Event for NumberType 'A' ({result.RelatedEvent["A"]}) should have the same default Mapping for 'Application' ({result.Mapping["Application"]})");
            Assert.AreEqual(result.RelatedEvent["P"], result.Mapping["Publication"], $"Related Event for NumberType 'P' ({result.RelatedEvent["P"]}) should have the same default Mapping for 'Publication' ({result.Mapping["Publication"]})");
            Assert.AreEqual(result.RelatedEvent["R"], result.Mapping["Registration/Grant"], $"Related Event for NumberType 'R' ({result.RelatedEvent["R"]}) should have the same default Mapping for 'Registration/Grant' ({result.Mapping["Registration/Grant"]})");
        }

        [Test]
        public void ReturnDirectRawMapping()
        {
            var result = DbSetup.Do(db =>
                                    {
                                        var a = db.InsertWithNewId(new Event {Description = RandomString.Next(30)});
                                        var p = db.InsertWithNewId(new Event {Description = RandomString.Next(30)});
                                        var r = db.InsertWithNewId(new Event {Description = RandomString.Next(30)});

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Application",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               OutputValue = a.Id.ToString()
                                                           });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Publication",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               OutputValue = p.Id.ToString()
                                                           });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Registration/Grant",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               OutputValue = r.Id.ToString()
                                                           });

                                        var raw = new Dictionary<string, int>
                                                  {
                                                      {"A", a.Id},
                                                      {"P", p.Id},
                                                      {"R", r.Id}
                                                  };

                                        var mapping = db.DbContext
                                                        .ResolveEventMappings("Application,Publication,Registration/Grant", "IpOneData")
                                                        .ToDictionary(k => k.Code, v => v.MappedEventId);

                                        return (Raw: raw, Mapping: mapping);
                                    });

            Assert.AreEqual(result.Raw["A"], result.Mapping["Application"], $"Should return configured raw mapping for 'A' ({result.Raw["A"]}), result: 'Application' ({result.Mapping["Application"]})");
            Assert.AreEqual(result.Raw["P"], result.Mapping["Publication"], $"Should return configured raw mapping for 'P' ({result.Raw["P"]}), result: 'Publication' ({result.Mapping["Publication"]})");
            Assert.AreEqual(result.Raw["R"], result.Mapping["Registration/Grant"], $"Should return configured raw mapping for 'R' ({result.Raw["R"]}), result: 'Registration/Grant' ({result.Mapping["Registration/Grant"]})");
        }

        [Test]
        public void ReturnEncodedRawMapping()
        {
            var result = DbSetup.Do(db =>
                                    {
                                        var a = db.InsertWithNewId(new Event {Description = RandomString.Next(30)});
                                        var p = db.InsertWithNewId(new Event {Description = RandomString.Next(30)});
                                        var r = db.InsertWithNewId(new Event {Description = RandomString.Next(30)});

                                        var applicationEventInproEncoded = db.InsertWithNewId(new EncodedValue
                                                                                              {
                                                                                                  Code = a.Id.ToString(),
                                                                                                  Description = RandomString.Next(30),
                                                                                                  SchemeId = CommonEncodingSchemeId,
                                                                                                  StructureId = EventMapStructure
                                                                                              });

                                        var publicationEventInproEncoded = db.InsertWithNewId(new EncodedValue
                                                                                              {
                                                                                                  Code = p.Id.ToString(),
                                                                                                  Description = RandomString.Next(30),
                                                                                                  SchemeId = CommonEncodingSchemeId,
                                                                                                  StructureId = EventMapStructure
                                                                                              });

                                        var registrationEventInproEncoded = db.InsertWithNewId(new EncodedValue
                                                                                               {
                                                                                                   Code = r.Id.ToString(),
                                                                                                   Description = RandomString.Next(30),
                                                                                                   SchemeId = CommonEncodingSchemeId,
                                                                                                   StructureId = EventMapStructure
                                                                                               });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Application",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               OutputCodeId = applicationEventInproEncoded.Id
                                                           });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Publication",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               OutputCodeId = publicationEventInproEncoded.Id
                                                           });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Registration/Grant",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               OutputCodeId = registrationEventInproEncoded.Id
                                                           });

                                        var raw = new Dictionary<string, int>
                                                  {
                                                      {"A", a.Id},
                                                      {"P", p.Id},
                                                      {"R", r.Id}
                                                  };

                                        var mapping = db.DbContext
                                                        .ResolveEventMappings("Application,Publication,Registration/Grant", "IpOneData")
                                                        .ToDictionary(k => k.Code, v => v.MappedEventId);

                                        return (Raw: raw, Mapping: mapping);
                                    });

            Assert.AreEqual(result.Raw["A"], result.Mapping["Application"], $"Should return configured raw mapping for 'A' ({result.Raw["A"]}), result: 'Application' ({result.Mapping["Application"]})");
            Assert.AreEqual(result.Raw["P"], result.Mapping["Publication"], $"Should return configured raw mapping for 'P' ({result.Raw["P"]}), result: 'Publication' ({result.Mapping["Publication"]})");
            Assert.AreEqual(result.Raw["R"], result.Mapping["Registration/Grant"], $"Should return configured raw mapping for 'R' ({result.Raw["R"]}), result: 'Registration/Grant' ({result.Mapping["Registration/Grant"]})");
        }

        [Test]
        public void ReturnNullWhenMarkedNotApplicable()
        {
            var result = DbSetup.Do(db =>
                                    {
                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Application",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               IsNotApplicable = true
                                                           });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Publication",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               IsNotApplicable = true
                                                           });

                                        db.InsertWithNewId(new Mapping
                                                           {
                                                               InputDescription = "Registration/Grant",
                                                               DataSourceId = IpOneDataSource,
                                                               StructureId = EventMapStructure,
                                                               IsNotApplicable = true
                                                           });

                                        return db.DbContext
                                                 .ResolveEventMappings("Application,Publication,Registration/Grant", "IpOneData")
                                                 .ToDictionary(k => k.Code, v => v.MappedEventId);
                                    });

            Assert.Null(result["Application"], $"Should return null as raw mapping for 'Application' indicates it to be ignored. ({result["Application"]})");
            Assert.Null(result["Publication"], $"Should return null as raw mapping for 'Publication' indicates it to be ignored.  ({result["Publication"]})");
            Assert.Null(result["Registration/Grant"], $"Should return null as raw mapping for 'Registration/Grant' indicates it to be ignored.  ({result["Registration/Grant"]})");
        }       
    }
}