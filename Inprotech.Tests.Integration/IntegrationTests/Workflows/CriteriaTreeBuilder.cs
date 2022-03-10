using System.Collections.Generic;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows
{
    public class CriteriaTreeBuilder
    {
        public static CriteriaTreeFixture Build()
        {
            return DbSetup.Do(setup =>
                              {
                                  var apple = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("apple")});
                                  var banana = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("banana")});
                                  var orange = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("orange")});
                                  var papaya = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("papaya")});
                                  var watermelon = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("watermelon")});
                                  var peach = setup.InsertWithNewId(new Event {Description = Fixture.Prefix("peach")});

                                  var parent = setup.InsertWithNewId(new Criteria
                                                                     {
                                                                         Description = Fixture.Prefix("parent"),
                                                                         PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                     });

                                  var parentEntry = setup.Insert(new DataEntryTask
                                                                 {
                                                                     CriteriaId = parent.Id,
                                                                     Description = "Entry 1",
                                                                     DisplaySequence = 1
                                                                 });

                                  var child1 = setup.InsertWithNewId(new Criteria
                                                                     {
                                                                         Description = Fixture.Prefix("child1"),
                                                                         PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                         ParentCriteriaId = parent.Id
                                                                     });

                                  setup.Insert(new DataEntryTask
                                               {
                                                   CriteriaId = child1.Id,
                                                   Description = "Entry- 1",
                                                   DisplaySequence = 1,
                                                   Inherited = 1,
                                                   ParentCriteriaId = parent.Id,
                                                   ParentEntryId = parentEntry.Id
                                               });

                                  var child2 = setup.InsertWithNewId(new Criteria
                                                                     {
                                                                         Description = Fixture.Prefix("child2"),
                                                                         PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                         ParentCriteriaId = parent.Id
                                                                     });

                                  var child2Entry = setup.Insert(new DataEntryTask
                                                                 {
                                                                     CriteriaId = child2.Id,
                                                                     Description = "entry1",
                                                                     DisplaySequence = 1,
                                                                     Inherited = 1,
                                                                     ParentCriteriaId = parent.Id,
                                                                     ParentEntryId = parentEntry.Id
                                                                 });
                                  var child3 = setup.InsertWithNewId(new Criteria
                                                                     {
                                                                         Description = Fixture.Prefix("child3"),
                                                                         PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                         ParentCriteriaId = parent.Id
                                                                     });
                                  var child3Entry = setup.Insert(new DataEntryTask
                                                                 {
                                                                     CriteriaId = child3.Id,
                                                                     Description = "entry1",
                                                                     DisplaySequence = 1,
                                                                     Inherited = 1,
                                                                     ParentCriteriaId = parent.Id,
                                                                     ParentEntryId = parentEntry.Id
                                                                 });

                                  var grandChild21 = setup.InsertWithNewId(new Criteria
                                                                           {
                                                                               Description = Fixture.Prefix("grandChild21"),
                                                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                               ParentCriteriaId = child2.Id
                                                                           });

                                  var grandChild21Entry = setup.Insert(new DataEntryTask
                                                                       {
                                                                           CriteriaId = grandChild21.Id,
                                                                           Description = "ENTRY1",
                                                                           DisplaySequence = 1,
                                                                           Inherited = 1,
                                                                           ParentEntryId = child2Entry.Id,
                                                                           ParentCriteriaId = child2Entry.CriteriaId
                                                                       });

                                  var grandChild22 = setup.InsertWithNewId(new Criteria
                                                                           {
                                                                               Description = Fixture.Prefix("grandChild22"),
                                                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                               ParentCriteriaId = child2.Id
                                                                           });

                                  setup.Insert(new DataEntryTask
                                               {
                                                   CriteriaId = grandChild22.Id,
                                                   Description = "ENTRY1",
                                                   DisplaySequence = 1,
                                                   Inherited = 1,
                                                   ParentEntryId = child2Entry.Id,
                                                   ParentCriteriaId = child2Entry.CriteriaId
                                               });

                                  var greatGrandChild211 = setup.InsertWithNewId(new Criteria
                                                                                 {
                                                                                     Description = Fixture.Prefix("greatGrandChild211"),
                                                                                     PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                                     ParentCriteriaId = grandChild21.Id
                                                                                 });

                                  setup.Insert(new DataEntryTask
                                               {
                                                   CriteriaId = greatGrandChild211.Id,
                                                   Description = "ENTRY1",
                                                   DisplaySequence = 1,
                                                   Inherited = 1,
                                                   ParentEntryId = grandChild21Entry.Id,
                                                   ParentCriteriaId = grandChild21Entry.CriteriaId
                                               });

                                  setup.Insert(new Inherits {Criteria = child1, FromCriteria = parent});
                                  setup.Insert(new Inherits {Criteria = child2, FromCriteria = parent});
                                  setup.Insert(new Inherits {Criteria = child3, FromCriteria = parent});
                                  setup.Insert(new Inherits {Criteria = grandChild21, FromCriteria = child2});
                                  setup.Insert(new Inherits {Criteria = grandChild22, FromCriteria = child2});
                                  setup.Insert(new Inherits {Criteria = greatGrandChild211, FromCriteria = grandChild21});

                                  return new CriteriaTreeFixture
                                  {
                                      Events = new Dictionary<string, Event>
                                      {
                                          {"apple", apple},
                                          {"banana", banana},
                                          {"orange", orange},
                                          {"papaya", papaya},
                                          {"watermelon", watermelon},
                                          {"peach", peach}
                                      },
                                      Parent = parent,
                                      Child1 = child1,
                                      Child2 = child2,
                                      Child3 = child3,
                                      GrandChild21 = grandChild21,
                                      GrandChild22 = grandChild22,
                                      GreatGrandChild211 = greatGrandChild211
                                  };
                              });
        }

        public class CriteriaTreeFixture
        {
            public CriteriaTreeFixture()
            {
                Events = new Dictionary<string, Event>();
            }

            public Criteria Parent { get; set; }

            public Criteria Child1 { get; set; }

            public Criteria Child2 { get; set; }
            public Criteria Child3 { get; set; }

            public Criteria GrandChild21 { get; set; }

            public Criteria GrandChild22 { get; set; }

            public Criteria GreatGrandChild211 { get; set; }

            public Dictionary<string, Event> Events { get; set; }

            public int[] CriteriaIds => new[] {Parent.Id, Child1.Id, Child2.Id, GrandChild21.Id, GrandChild22.Id, GreatGrandChild211.Id};
        }
    }
}