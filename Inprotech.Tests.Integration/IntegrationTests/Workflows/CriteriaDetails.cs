using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CriteriaDetails : IntegrationTest
    {
        [Test]
        public void ReorderEntries()
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var parent = setup.InsertWithNewId(new Criteria
                                                                         {
                                                                             Description = Fixture.Prefix("parent"),
                                                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                         });

                                      setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) {Description = "Entry 1", DisplaySequence = 1, IsSeparator = true});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 2) {Description = "Entry 2", DisplaySequence = 2});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 3) {Description = "Entry 3", DisplaySequence = 3});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 4) {Description = "Entry 4", DisplaySequence = 4});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 5) {Description = "Entry 5", DisplaySequence = 5});

                                      var child1 = setup.InsertWithNewId(new Criteria
                                                                         {
                                                                             Description = Fixture.Prefix("child1"),
                                                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                         });

                                      setup.Insert<DataEntryTask>(new DataEntryTask(child1.Id, 5) { Description = "Entry. 5", DisplaySequence = 1, Inherited = 1 });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(child1.Id, 4) { Description = "Entry =4", DisplaySequence = 2, Inherited = 1 });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(child1.Id, 1) {Description = "Entry- 1", DisplaySequence = 3, Inherited = 1, IsSeparator = true });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(child1.Id, 2) {Description = "Entry -2", DisplaySequence = 4, Inherited = 1});

                                      var child2 = setup.InsertWithNewId(new Criteria
                                                                         {
                                                                             Description = Fixture.Prefix("child2"),
                                                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                         });

                                      setup.Insert<DataEntryTask>(new DataEntryTask(child2.Id, 1) {Description = "entry 1", DisplaySequence = 1, Inherited = 0, IsSeparator = true });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(child2.Id, 3) {Description = "entry3", DisplaySequence = 3, Inherited = 0});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(child2.Id, 4) {Description = "entry:4", DisplaySequence = 4, Inherited = 0});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(child2.Id, 5) {Description = "entry5", DisplaySequence = 5, Inherited = 0});

                                      var grandChild21 = setup.InsertWithNewId(new Criteria
                                                                               {
                                                                                   Description = Fixture.Prefix("grandChild21"),
                                                                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                               });

                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild21.Id, 1) {Description = "ENTRY1", DisplaySequence = 1, IsSeparator = true });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild21.Id, 2) {Description = "ENTRY3", DisplaySequence = 2});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild21.Id, 3) {Description = "ENTRY4", DisplaySequence = 3});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild21.Id, 4) { Description = "ENTRY:4", DisplaySequence = 4 });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild21.Id, 5) {Description = "ENTRY:5", DisplaySequence = 5});

                                      var grandChild22 = setup.InsertWithNewId(new Criteria
                                                                               {
                                                                                   Description = Fixture.Prefix("grandChild22"),
                                                                                   PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                               });

                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild22.Id, 1) { Description = "ENTRY*1", DisplaySequence = 1, IsSeparator = true });
                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild22.Id, 5) {Description = "ENTRY+5", DisplaySequence = 3});
                                      setup.Insert<DataEntryTask>(new DataEntryTask(grandChild22.Id, 3) { Description = "ENTRY4", DisplaySequence = 5 });

                                      setup.Insert(new Inherits {Criteria = child1, FromCriteria = parent});
                                      setup.Insert(new Inherits {Criteria = child2, FromCriteria = parent});
                                      setup.Insert(new Inherits {Criteria = grandChild21, FromCriteria = child2});
                                      setup.Insert(new Inherits {Criteria = grandChild22, FromCriteria = child2});

                                      return new
                                      {
                                          Parent = parent,
                                          Child1 = child1,
                                          Child2 = child2,
                                          GrandChild21 = grandChild21,
                                          GrandChild22 = grandChild22
                                      };
                                  });

            var entryReorderRequest = new WorkflowsController.EntryReorderRequest
            {
                InsertBefore = true,
                SourceId = 4,
                TargetId = 2
            };

            var result = ApiClient.Post<dynamic>($"configuration/rules/workflows/{data.Parent.Id}/entries/reorder", JsonConvert.SerializeObject(entryReorderRequest));

            Assert.AreEqual(1, (short?) result.prevTargetId);
            Assert.AreEqual(3, (short?) result.nextTargetId);

            entryReorderRequest.NextTargetId = (short?) result.nextTargetId;
            entryReorderRequest.PrevTargetId = (short?) result.prevTargetId;

            ApiClient.Post<dynamic>($"configuration/rules/workflows/{data.Parent.Id}/entries/descendants/reorder", JsonConvert.SerializeObject(entryReorderRequest));

            short[] child1Seq, child2Seq, grandChild21Seq, grandChild22Seq;
            using (var db = new SqlDbContext())
            {
                child1Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == data.Child1.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Id).ToArray();

                child2Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == data.Child2.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Id).ToArray();

                grandChild21Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == data.GrandChild21.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Id).ToArray();

                grandChild22Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == data.GrandChild22.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Id).ToArray();
            }

            Assert.AreEqual(new[] {5, 1, 4, 2}, child1Seq, "Entry is moved based on target");
            Assert.AreEqual(new[] {1, 4, 3, 5}, child2Seq, "Entry is moved based on fallback");
            Assert.AreEqual(new[] {1, 2, 3, 4, 5}, grandChild21Seq, "Entry did not move since two entries are found when source is match with fussy match logic");
            Assert.AreEqual(new[] {1, 5, 3}, grandChild22Seq, "Entry did not move, since fallback entry is not exact match. Fallback entry is a separator, hence requires exact match");
        }

        static WorkflowsController.AddEntryParams CreateRequest(string description,bool isSeparator = false, int? insertAfter = null)
        {
            return new WorkflowsController.AddEntryParams
            {
                IsSeparator = isSeparator,
                ApplyToChildren = true,
                EntryDescription = description,
                InsertAfterEntryId = insertAfter
            };
        }

        [Test]
        public void AddEntryAndPropagateToDescendents()
        {
            const string newEntryA = "New Normal Entry A";
            const string newEntryX = "Normal Entry X";
            const string newEntryY = "Normal Entry Y";

            const string newSeparatorEntry1 = "~~~~~~ Filing ~~~~~";
            const string newSeparatorEntry2 = "####";
            const string newSeparatorEntry3 = "                                    ";

            var criteriaData = CriteriaTreeBuilder.Build();

            var parentEntries = criteriaData.Parent.DataEntryTasks.OrderBy(_=>_.DisplaySequence).Select(_=>_.Description).ToList();
            var child1Entries = criteriaData.Child1.DataEntryTasks.OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToList();
            var child2Entries = criteriaData.Child2.DataEntryTasks.OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToList();
            var grandChild21Entries = criteriaData.GrandChild21.DataEntryTasks.OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToList();
            var grandChild22Entries = criteriaData.GrandChild22.DataEntryTasks.OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToList();
            var greatGrandChild211Entries = criteriaData.GreatGrandChild211.DataEntryTasks.OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToList();

            DbSetup.Do(setup =>
                       {
                           setup.Insert<DataEntryTask>(new DataEntryTask(criteriaData.Child1.Id, 2) { Description = newSeparatorEntry3, DisplaySequence = 2, IsSeparator = true });
                           setup.Insert<DataEntryTask>(new DataEntryTask(criteriaData.Child1.Id, 3) { Description = newEntryY, DisplaySequence = 3 });

                           setup.Insert<DataEntryTask>(new DataEntryTask(criteriaData.Child2.Id, 2) {Description = newSeparatorEntry2, DisplaySequence = 2, IsSeparator = true});
                           setup.Insert<DataEntryTask>(new DataEntryTask(criteriaData.Child2.Id, 3) {Description = newEntryX, DisplaySequence = 3});

                           setup.Insert<DataEntryTask>(new DataEntryTask(criteriaData.GrandChild21.Id, 2) { Description = newEntryY, DisplaySequence = 2 });
                           setup.Insert<DataEntryTask>(new DataEntryTask(criteriaData.GreatGrandChild211.Id, 2) { Description = newSeparatorEntry1, DisplaySequence = 2 , IsSeparator = true});
                       });

            var resultNewEntryA = ApiClient.Post<dynamic>($"configuration/rules/workflows/{criteriaData.Parent.Id}/entries", 
                                                JsonConvert.SerializeObject(CreateRequest(newEntryA)));
            Assert.NotNull(resultNewEntryA);
            var newEntryNo = (int)resultNewEntryA.entryNo;

            ApiClient.Post<dynamic>($"configuration/rules/workflows/{criteriaData.Parent.Id}/entries",
                                      JsonConvert.SerializeObject(CreateRequest(newEntryX)));

            ApiClient.Post<dynamic>($"configuration/rules/workflows/{criteriaData.Parent.Id}/entries",
                                                JsonConvert.SerializeObject(CreateRequest(newSeparatorEntry2, true)));

            ApiClient.Post<dynamic>($"configuration/rules/workflows/{criteriaData.Parent.Id}/entries",
                                      JsonConvert.SerializeObject(CreateRequest(newEntryY)));

            ApiClient.Post<dynamic>($"configuration/rules/workflows/{criteriaData.Parent.Id}/entries",
                                               JsonConvert.SerializeObject(CreateRequest(newSeparatorEntry3, true)));

            var resultNewSeparatorEntry1 = ApiClient.Post<dynamic>($"configuration/rules/workflows/{criteriaData.Parent.Id}/entries",
                                              JsonConvert.SerializeObject(CreateRequest(newSeparatorEntry1, true, newEntryNo)));
            Assert.NotNull(resultNewSeparatorEntry1);

            string[] parentSeq, child1Seq, child2Seq, grandChild21Seq, grandChild22Seq, greatGrandChild211Seq;
            using (var db = new SqlDbContext())
            {
                parentSeq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaData.Parent.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();

                child1Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaData.Child1.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();

                child2Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaData.Child2.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();

                grandChild21Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaData.GrandChild21.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();

                grandChild22Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaData.GrandChild22.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();

                greatGrandChild211Seq = db.Set<DataEntryTask>().Where(_ => _.CriteriaId == criteriaData.GreatGrandChild211.Id).OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();
            }

            parentEntries.AddRange(new [] { newEntryA, newSeparatorEntry1, newEntryX, newSeparatorEntry2, newEntryY, newSeparatorEntry3});
            child1Entries.AddRange(new[] { newSeparatorEntry3, newEntryY, newEntryA, newSeparatorEntry1, newEntryX, newSeparatorEntry2 });
            child2Entries.AddRange(new[] { newSeparatorEntry2, newEntryX, newEntryA, newSeparatorEntry1, newEntryY, newSeparatorEntry3 });
            grandChild21Entries.AddRange(new[] { newEntryY, newEntryA, newSeparatorEntry1, newSeparatorEntry3 });
            grandChild22Entries.AddRange(new[] { newEntryA, newSeparatorEntry1, newEntryY, newSeparatorEntry3 });
            greatGrandChild211Entries.AddRange(new[] { newSeparatorEntry1, newEntryA, newSeparatorEntry3 });

            Assert.AreEqual(parentEntries, parentSeq, "All entries are added in the parent entry");
            Assert.AreEqual(child1Entries, child1Seq, "Entries are added in Child1, skipping the entries which are already existing");
            Assert.AreEqual(child2Entries, child2Seq, "Entries are added in Child2, skipping the entries which are already existing");
            Assert.AreEqual(grandChild21Entries, grandChild21Seq, "Entries are added in GrandChild21, skipping the entries which are already existing in Child2 and itself");
            Assert.AreEqual(grandChild22Entries, grandChild22Seq, "Entries are added in GrandChild22, skipping the entries which are already existing in Child2 and itself");
            Assert.AreEqual(greatGrandChild211Entries, greatGrandChild211Seq, "Entries are added in GreatGrandChild211, skipping the entries which are already existing in Child21 and itself");
        }
    }
}