using System.Linq;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;
using NUnit.Framework;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EntryEvents : IntegrationTest
    {
        static string[] Names(params Event[] @event)
        {
            return @event.Select(_ => _.Description).ToArray();
        }

        [Test]
        public void ReorderEntryEvents()
        {
            var data = CriteriaTreeBuilder.Build();

            var apple = data.Events["apple"];
            var banana = data.Events["banana"];
            var orange = data.Events["orange"];
            var papaya = data.Events["papaya"];
            var watermelon = data.Events["watermelon"];
            var peach = data.Events["peach"];

            data.Parent.FirstEntry().QuickAdd(apple, banana, orange, peach);

            data.Child1.FirstEntry().QuickAdd(apple, banana, orange, papaya, watermelon);

            data.Child2.FirstEntry().QuickAdd(apple, banana, papaya);

            data.Child3.FirstEntry().QuickAdd(apple, banana, papaya, peach);

            data.GrandChild21.FirstEntry().QuickAdd(apple, papaya, watermelon);

            data.GrandChild22.FirstEntry().QuickAdd(apple, banana, papaya, orange);

            data.GreatGrandChild211.FirstEntry().QuickAdd(apple, banana, orange);

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{data.Parent.FirstEntry().Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                          {
                              CriteriaId = data.Parent.Id,
                              Id = data.Parent.FirstEntry().Id,
                              Description = data.Parent.FirstEntry().Description,
                              ApplyToDescendants = true,
                              EntryEventsMoved = new[]
                                                                             {
                                                                                 new EntryEventMovementsBase {EventId = banana.Id}, /* move banana to first */
                                                                                 new EntryEventMovementsBase {EventId = apple.Id, PrevEventId = orange.Id} /* move apple to follow orange */
                                                                             }
                          }));

            using (var ctx = new SqlDbContext())
            {
                var result = (from ae in ctx.Set<AvailableEvent>()
                              where new[] { apple.Id, banana.Id, orange.Id, papaya.Id, watermelon.Id, peach.Id }.Contains(ae.EventId)
                              group ae by ae.CriteriaId
                              into grp
                              select new
                              {
                                  grp.Key,
                                  Events = grp.OrderBy(_ => _.DisplaySequence).Select(_ => _.Event.Description)
                              }).ToDictionary(k => k.Key, v => v.Events.ToArray());

                CollectionAssert.AreEqual(Names(banana, orange, apple, peach), result[data.Parent.Id], "Movements in parent is correct");

                CollectionAssert.AreEqual(Names(banana, orange, apple, papaya, watermelon), result[data.Child1.Id], "Movement in parent replicated in child #1, which has additional fruits");

                CollectionAssert.AreEqual(Names(banana, apple, papaya), result[data.Child2.Id], "Movement in parent replicated in child #2, which has less fruit, ignores movement that cannot be actioned.");

                CollectionAssert.AreEqual(Names(banana, papaya, apple, peach), result[data.Child3.Id], "Movement in parent replicated in child #3, which has a missing fruit, fallbacks from previous to next to find out correct order.");

                CollectionAssert.AreEqual(Names(apple, papaya, watermelon), result[data.GrandChild21.Id], "Movement in parent cannot be replicated in grand child #21");

                CollectionAssert.AreEqual(Names(banana, papaya, orange, apple), result[data.GrandChild22.Id], "Movements in parent replicated in grand child #22, which has different additional fruit in order");

                CollectionAssert.AreEqual(Names(apple, banana, orange), result[data.GreatGrandChild211.Id], "Movements in parent cannot be replicated because grand child #21 did not move in the hierarchy chain");
            }
        }
    }
}