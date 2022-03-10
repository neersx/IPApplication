using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class DesignatedJurisdictionTest : IntegrationTest
    {
        [Test]
        public void AddDesignatedJurisdiction()
        {
            var data = DbSetup.Do(setup =>
            {
                var groupJurisdiction = new CountryBuilder(setup.DbContext) {Type = "1"}.Create(Fixture.String(5));
                var jurisdiction = new CountryBuilder(setup.DbContext).Create(Fixture.String(5));
                var jurisdiction1 = new CountryBuilder(setup.DbContext).Create(Fixture.String(5));

                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction));
                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction1));

                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance(null, groupJurisdiction);
                var existingEvent = setup.InsertWithNewId(new Event());
                
                setup.Insert(new DueDateCalc(inheritanceFixture.ChildCriteriaId, inheritanceFixture.EventId, 0) { JurisdictionId = jurisdiction.Id });
                
                var nonGroupChild = new CriteriaBuilder(setup.DbContext) {JurisdictionId = jurisdiction.Id }.Create("child1", inheritanceFixture.CriteriaId);
                setup.Insert(new ValidEvent(nonGroupChild.Id, inheritanceFixture.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    NonGroupChild = nonGroupChild.Id,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingEventToUpdate = existingEvent.Id,
                    JurisdictionId = jurisdiction.Id,
                    JurisdictionId1 = jurisdiction1.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                DesignatedJurisdictionsDelta = new Delta<string> { Added = new [] {data.JurisdictionId, data.JurisdictionId1} }
            }.WithMandatoryFields();
            
            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaDesignatedJurisdictions = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DueDateCalcs;
                var childDesignatedJurisdictions = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DueDateCalcs.ToArray();
                var grandchildDesignatedJurisdictions = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DueDateCalcs.Where(_ => _.Inherited == 1).ToArray();

                Assert.AreEqual(2, criteriaDesignatedJurisdictions.Count, "Adds new Designated Jurisdiction.");
                Assert.AreEqual(2, childDesignatedJurisdictions.Length, "Adds Inherited Designated Jurisdiction to child");
                Assert.NotNull(childDesignatedJurisdictions.SingleOrDefault(_ => _.JurisdictionId == data.JurisdictionId1 && _.Inherited == 1), "Adds Inherited Designated Jurisdiction to child");
                Assert.AreEqual(1, grandchildDesignatedJurisdictions.Length, "Adds Inherited Designated Jurisdiction to grandchild");
                Assert.NotNull(grandchildDesignatedJurisdictions.SingleOrDefault(_ => _.JurisdictionId == data.JurisdictionId1 && _.Inherited == 1), "Adds Inherited Designated Jurisdiction from child to grandchild");

                var nonGroupChild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.NonGroupChild).DueDateCalcs;
                Assert.AreEqual(0, nonGroupChild.Count, "Does not push designated jurisdictions to non-group country children");
            }
        }

        [Test]
        public void DeleteDesignatedJurisdiction()
        {
            var data = DbSetup.Do(setup =>
            {
                var groupJurisdiction = new CountryBuilder(setup.DbContext) { Type = "1" }.Create(Fixture.String(5));
                var jurisdiction = new CountryBuilder(setup.DbContext).Create(Fixture.String(5));
                var jurisdiction1 = new CountryBuilder(setup.DbContext).Create(Fixture.String(5));

                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction));
                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction1));

                var f = new EventControlDbSetup().SetupCriteriaInheritance(null, groupJurisdiction);

                setup.Insert(new DueDateCalc(f.CriteriaId, f.EventId, 0) { JurisdictionId = jurisdiction.Id });
                setup.Insert(new DueDateCalc(f.ChildCriteriaId, f.EventId, 0) { JurisdictionId = jurisdiction.Id, Inherited = 1});
                setup.Insert(new DueDateCalc(f.GrandchildCriteriaId, f.GrandchildValidEvent.EventId, 0) { JurisdictionId = jurisdiction.Id, Inherited = 0 });

                var child1 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                var childValidEvent1 = setup.Insert(new ValidEvent(child1.Id, f.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });
                setup.Insert(new DueDateCalc(child1.Id, childValidEvent1.EventId, 0) { JurisdictionId = jurisdiction.Id, Inherited = 0});

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    Child1Id = child1.Id,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    JurisdictionId = jurisdiction.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ChangeRespOnDueDates = false,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                DesignatedJurisdictionsDelta = new Delta<string> { Deleted = new [] {data.JurisdictionId} }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).DueDateCalcs.Count;
                var childCount = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).DueDateCalcs.Count;
                var child1Count = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.Child1Id && _.EventId == data.EventId).DueDateCalcs.Count;
                var grandchildCount = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).DueDateCalcs.Count;

                Assert.AreEqual(0, parentCount, "Deletes Designated Jurisdiction.");
                Assert.AreEqual(0, childCount, "Deletes Inherited child Designated Jurisdiction.");
                Assert.AreEqual(1, child1Count, "Does not delete non inherited child Designated Jurisdiction.");
                Assert.AreEqual(1, grandchildCount, "Does not delete not-inherited grandchild.");
            }
        }
    }
}