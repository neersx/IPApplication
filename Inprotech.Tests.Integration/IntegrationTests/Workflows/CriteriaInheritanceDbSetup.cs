using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows
{
#pragma warning disable 618
    public class CriteriaInheritanceDbSetup : DbSetup
    {
        static readonly string ParentCriteria = Fixture.Prefix("parent");
        static readonly string OrphanCriteria = Fixture.Prefix("orphan");
        static readonly string ChildCriteria = Fixture.Prefix("child1");
        static readonly string ChildCriteria2 = Fixture.Prefix("child2");
        static readonly string GrandchildCriteria = Fixture.Prefix("grandchild");
        static readonly string EventDescription = Fixture.Prefix("event");
        static readonly string EntryDescription = Fixture.Prefix("entry");
        static readonly string NewEventDescription = Fixture.Prefix("event2");
        static readonly string ReplacedEventDescription = Fixture.Prefix("replacedevent");
        static readonly string ActionDescripion = Fixture.Prefix("action");

        public TreeFixture SetupTree()
        {
            var orphan = InsertWithNewId(new Criteria
                                         {
                                             Description = OrphanCriteria,
                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                         });

            var parent = InsertWithNewId(new Criteria
                                         {
                                             Description = ParentCriteria,
                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                             ParentCriteriaId = null,
                                             UserDefinedRule = null
                                         });

            var child = InsertWithNewId(new Criteria
                                        {
                                            Description = ChildCriteria,
                                            PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                            ParentCriteriaId = parent.Id,
                                            UserDefinedRule = 0
                                        });

            var child2 = InsertWithNewId(new Criteria
                                         {
                                             Description = ChildCriteria2,
                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                             ParentCriteriaId = parent.Id,
                                             UserDefinedRule = 1
                                         });

            var grandchild = InsertWithNewId(new Criteria
                                             {
                                                 Description = GrandchildCriteria,
                                                 PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                 ParentCriteriaId = child.Id,
                                                 UserDefinedRule = 1
                                             });

            Insert(new Inherits
                   {
                       Criteria = grandchild,
                       FromCriteria = child
                   });

            Insert(new Inherits
                   {
                       Criteria = child,
                       FromCriteria = parent
                   });

            Insert(new Inherits
                   {
                       Criteria = child2,
                       FromCriteria = parent
                   });

            return new TreeFixture
            {
                GrandchildId = grandchild.Id,
                ChildId = child.Id,
                Child2Id = child2.Id,
                ParentId = parent.Id,
                OrphanId = orphan.Id
            };
        }

        public InheritanceDataFixture SetupForBreakInheritance()
        {
            var fixture = new InheritanceDataFixture();
            var tree = fixture.Tree = SetupTree();

            var @event = InsertWithNewId(new Event
                                         {
                                             Description = EventDescription
                                         });

            Insert(new ValidEvent
                   {
                       Description = EventDescription,
                       CriteriaId = tree.ChildId,
                       EventId = @event.Id,
                       ParentCriteriaNo = tree.ParentId,
                       ParentEventNo = 123,
                       Inherited = 1
                   });

            var entry = Insert(new DataEntryTask
                               {
                                   Description = EntryDescription,
                                   CriteriaId = tree.ChildId,
                                   ParentCriteriaId = tree.ParentId,
                                   ParentEntryId = 123,
                                   Inherited = 1
                               });

            fixture.EntryId = entry.Id;
            fixture.EventId = @event.Id;

            return fixture;
        }

        public ChangeParentageDataFixture SetupForChangeParentage(bool usedByLiveCase = false)
        {
            var fixture = new ChangeParentageDataFixture();
            var tree = fixture.Tree = SetupTree();

            if (usedByLiveCase) SetupUsedByLiveCaseForCriteria(tree.ParentId);

            var sameEvent = InsertWithNewId(new Event
                                            {
                                                Description = ReplacedEventDescription
                                            });
            fixture.SameEventId = sameEvent.Id;

            Insert(new ValidEvent
                   {
                       EventId = sameEvent.Id,
                       CriteriaId = tree.OrphanId,
                       Description = ReplacedEventDescription
                   });

            Insert(new ValidEvent
                   {
                       EventId = sameEvent.Id,
                       CriteriaId = tree.ParentId,
                       Description = EventDescription
                   });

            Insert(new ValidEvent
                   {
                       EventId = sameEvent.Id,
                       CriteriaId = tree.ChildId,
                       Description = EventDescription
                   });

            var newEvent = InsertWithNewId(new Event
                                           {
                                               Description = NewEventDescription
                                           });
            fixture.NewEventId = newEvent.Id;

            Insert(new ValidEvent
                   {
                       EventId = newEvent.Id,
                       CriteriaId = tree.OrphanId,
                       Description = NewEventDescription
                   });

            fixture.SameEntryDescInParent = "E2E SameEntryDesc";
            fixture.SameEntryDescInChild = "E2E SameEntryDesc$";
            fixture.NewEntryDesc = "E2E NewEntryDesc";
            fixture.EntryStepName1 = "E2EScreen-1";
            fixture.EntryStepName2 = "E2EScreen-2";

            Insert(new DataEntryTask
                   {
                       CriteriaId = tree.OrphanId,
                       Description = fixture.SameEntryDescInParent
                   });

            var newDataEntryTask = Insert(new DataEntryTask
                                          {
                                              CriteriaId = tree.OrphanId,
                                              Description = fixture.NewEntryDesc
                                          });

            Insert(new DataEntryTask
                   {
                       CriteriaId = tree.ParentId,
                       Description = fixture.SameEntryDescInChild
                   });

            Insert(new DataEntryTask
                   {
                       CriteriaId = tree.ChildId,
                       Description = fixture.SameEntryDescInChild
                   });

            Insert(new Screen {ScreenName = fixture.EntryStepName1, ScreenTitle = "e2e-1", ScreenType = "G"});
            Insert(new Screen {ScreenName = fixture.EntryStepName2, ScreenTitle = "e2e-2", ScreenType = "G"});

            var windowControl = Insert(new WindowControl(tree.OrphanId, newDataEntryTask.Id));
            var topic1 = new TopicControl(fixture.EntryStepName1)
            {
                TopicSuffix = Fixture.String(20),
                Title = "e2e-1"
            };
            var topic2 = new TopicControl(fixture.EntryStepName2)
            {
                TopicSuffix = Fixture.String(20),
                Title = "e2e-2"
            };
            windowControl.TopicControls.AddRange(new[] {topic1, topic2});
            DbContext.SaveChanges();

            return fixture;
        }

        public ChangeParentageEventOrderingDataFixture SetupForChangeParentageEventOrdering()
        {
            var fixture = new ChangeParentageEventOrderingDataFixture();
            var tree = fixture.Tree = SetupTree();

            var eventA = InsertWithNewId(new Event {Description = Fixture.Prefix("A")});
            var eventB = InsertWithNewId(new Event {Description = Fixture.Prefix("B")});
            var eventC = InsertWithNewId(new Event {Description = Fixture.Prefix("C")});
            var eventD = InsertWithNewId(new Event {Description = Fixture.Prefix("D")});
            var eventE = InsertWithNewId(new Event {Description = Fixture.Prefix("E")});
            var eventF = InsertWithNewId(new Event {Description = Fixture.Prefix("F")});

            Insert(new ValidEvent(tree.OrphanId, eventA.Id) {DisplaySequence = 0});
            Insert(new ValidEvent(tree.OrphanId, eventB.Id) {DisplaySequence = 1});
            Insert(new ValidEvent(tree.OrphanId, eventC.Id) {DisplaySequence = 2});
            Insert(new ValidEvent(tree.OrphanId, eventD.Id) {DisplaySequence = 3});

            Insert(new ValidEvent(tree.ChildId, eventC.Id) {DisplaySequence = 0});
            Insert(new ValidEvent(tree.ChildId, eventB.Id) {DisplaySequence = 1});
            Insert(new ValidEvent(tree.ChildId, eventE.Id) {DisplaySequence = 2});
            Insert(new ValidEvent(tree.ChildId, eventF.Id) {DisplaySequence = 3});

            Insert(new ValidEvent(tree.GrandchildId, eventC.Id) {DisplaySequence = 0});
            Insert(new ValidEvent(tree.GrandchildId, eventB.Id) {DisplaySequence = 1});
            Insert(new ValidEvent(tree.GrandchildId, eventE.Id) {DisplaySequence = 2});
            Insert(new ValidEvent(tree.GrandchildId, eventF.Id) {DisplaySequence = 3});

            fixture.EventA = eventA.Id;
            fixture.EventB = eventB.Id;
            fixture.EventC = eventC.Id;
            fixture.EventD = eventD.Id;
            fixture.EventE = eventE.Id;
            fixture.EventF = eventF.Id;

            return fixture;
        }

        public void SetupUsedByLiveCaseForCriteria(int criteriaId)
        {
            var @case = new CaseBuilder(DbContext).Create(Fixture.Prefix());

            var act = InsertWithNewId(new Action {Name = ActionDescripion});
            Insert(new OpenAction
                   {
                       ActionId = act.Code,
                       CaseId = @case.Id,
                       CriteriaId = criteriaId
                   });
        }

        public ChangeParentageEntriesOrderingDataFixture SetupForChangeParentageEntriesOrdering()
        {
            var fixture = new ChangeParentageEntriesOrderingDataFixture();
            var tree = fixture.Tree = SetupTree();

            var entryA = Fixture.Prefix("A");
            var entryB = Fixture.Prefix("B");
            var entryC = Fixture.Prefix("C");
            var entryD = Fixture.Prefix("D");
            var entryE = Fixture.Prefix("E");
            var entryF = Fixture.Prefix("F");

            Insert(new DataEntryTask(tree.OrphanId, 1) {DisplaySequence = 0, Description = entryA});
            Insert(new DataEntryTask(tree.OrphanId, 2) {DisplaySequence = 1, Description = entryB});
            Insert(new DataEntryTask(tree.OrphanId, 3) {DisplaySequence = 2, Description = entryC});
            Insert(new DataEntryTask(tree.OrphanId, 4) {DisplaySequence = 3, Description = entryD});

            Insert(new DataEntryTask(tree.ChildId, 5) {DisplaySequence = 0, Description = entryC});
            Insert(new DataEntryTask(tree.ChildId, 6) {DisplaySequence = 1, Description = entryB});
            Insert(new DataEntryTask(tree.ChildId, 7) {DisplaySequence = 2, Description = entryE});
            Insert(new DataEntryTask(tree.ChildId, 8) {DisplaySequence = 3, Description = entryF});

            Insert(new DataEntryTask(tree.GrandchildId, 11) {DisplaySequence = 0, Description = entryC});
            Insert(new DataEntryTask(tree.GrandchildId, 12) {DisplaySequence = 1, Description = entryB});
            Insert(new DataEntryTask(tree.GrandchildId, 13) {DisplaySequence = 2, Description = entryE});
            Insert(new DataEntryTask(tree.GrandchildId, 14) {DisplaySequence = 3, Description = entryF});

            fixture.EntryA = entryA;
            fixture.EntryB = entryB;
            fixture.EntryC = entryC;
            fixture.EntryD = entryD;
            fixture.EntryE = entryE;
            fixture.EntryF = entryF;

            return fixture;
        }

        public class TreeFixture
        {
            public int ChildId { get; set; }
            public int Child2Id { get; set; }
            public int GrandchildId { get; set; }
            public int ParentId { get; set; }
            public int OrphanId { get; set; }
        }

        public class InheritanceDataFixture
        {
            public TreeFixture Tree { get; set; }
            public string ChildName => ChildCriteria;
            public string Child2Name => ChildCriteria2;
            public string GrandChildName => GrandchildCriteria;
            public string ParentName => ParentCriteria;
            public string OrphanName => OrphanCriteria;
            public string ValidEvent => EventDescription;
            public int EntryId { get; set; }
            public int EventId { get; set; }
        }

        public class ChangeParentageDataFixture : InheritanceDataFixture
        {
            public string ReplacedEvent => ReplacedEventDescription;
            public int SameEventId { get; set; }
            public string NewEvent => NewEventDescription;
            public int NewEventId { get; set; }
            public string SameEntryDescInParent { get; set; }
            public string SameEntryDescInChild { get; set; }
            public string NewEntryDesc { get; set; }
            public string EntryStepName1 { get; set; }
            public string EntryStepName2 { get; set; }
        }

        public class ChangeParentageEventOrderingDataFixture
        {
            public TreeFixture Tree { get; set; }
            public int EventA { get; set; }
            public int EventB { get; set; }
            public int EventC { get; set; }
            public int EventD { get; set; }
            public int EventE { get; set; }
            public int EventF { get; set; }
        }

        public class ChangeParentageEntriesOrderingDataFixture
        {
            public TreeFixture Tree { get; set; }
            public string EntryA { get; set; }
            public string EntryB { get; set; }
            public string EntryC { get; set; }
            public string EntryD { get; set; }
            public string EntryE { get; set; }
            public string EntryF { get; set; }
        }
    }
}