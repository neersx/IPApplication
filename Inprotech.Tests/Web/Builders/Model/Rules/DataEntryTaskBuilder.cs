using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Configuration.Screens;
using Inprotech.Tests.Web.Builders.Model.Documents;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public enum VisualAttribute
    {
        Dim,
        Hide,
        Display
    }

    public class DataEntryTaskBuilder : IBuilder<DataEntryTask>
    {
        public DataEntryTaskBuilder()
        {
        }

        public DataEntryTaskBuilder(Criteria criteria, short? entryId = null)
        {
            Criteria = criteria;
            EntryNumber = entryId;
        }

        public Criteria Criteria { get; set; }
        public string Description { get; set; }
        public string UserInstruction { get; set; }
        public short? DisplaySequence { get; set; }
        public short? EntryNumber { get; set; }
        public int? DisplayEventNo { get; set; }
        public int? HideEventNo { get; set; }
        public int? DimEventNo { get; set; }
        public bool? ShouldPoliceImmediately { get; set; }
        public bool? AtleastOneEventFlag { get; set; }
        public short? ParentEntryId { get; set; }
        public int? ParentCriteriaId { get; set; }
        public decimal? Inherited { get; set; }

        public NumberType NumberType { get; set; }
        public Status CaseStatus { get; set; }
        public Status RenewalStatus { get; set; }
        public TableCode FileLocation { get; set; }
        public bool IsSeparator { get; set; }

        public DataEntryTask Build()
        {
            return new DataEntryTask(
                                     Criteria ?? new CriteriaBuilder().Build(),
                                     EntryNumber ?? Fixture.Short(),
                                     CaseStatus,
                                     RenewalStatus,
                                     NumberType,
                                     FileLocation)
            {
                Description = Description ?? Fixture.String("Description"),
                UserInstruction = UserInstruction,
                DisplaySequence = DisplaySequence ?? Fixture.Short(),
                DisplayEventNo = DisplayEventNo,
                HideEventNo = HideEventNo,
                DimEventNo = DimEventNo,
                ShouldPoliceImmediate = ShouldPoliceImmediately ?? false,
                AtLeastOneFlag = AtleastOneEventFlag.HasValue && AtleastOneEventFlag.Value ? 1 : 0,
                ParentCriteriaId = ParentCriteriaId ?? Criteria?.ParentCriteriaId,
                ParentEntryId = ParentEntryId,
                Inherited = Inherited,
                IsSeparator = IsSeparator,
                AvailableEvents = new List<AvailableEvent>(),
                DocumentRequirements = new List<DocumentRequirement>(),
                GroupsAllowed = new List<GroupControl>(),
                UsersAllowed = new List<UserControl>(),
                RolesAllowed = new List<RolesControl>()
            };
        }

        public static DataEntryTaskBuilder ForCriteria(Criteria criteria)
        {
            return new DataEntryTaskBuilder {Criteria = criteria};
        }
    }

    public static class DataEntryTaskBuilderExtensions
    {
        public static DataEntryTaskBuilder WithVisualAttribute(
            this DataEntryTaskBuilder source,
            VisualAttribute attribute,
            int eventNo)
        {
            switch (attribute)
            {
                case VisualAttribute.Dim:
                    source.DimEventNo = eventNo;
                    break;
                case VisualAttribute.Display:
                    source.DisplayEventNo = eventNo;
                    break;
                case VisualAttribute.Hide:
                    source.HideEventNo = eventNo;
                    break;
            }

            return source;
        }

        public static DataEntryTaskBuilder AsSeparator(this DataEntryTaskBuilder source)
        {
            source.IsSeparator = true;
            return source;
        }

        public static DataEntryTaskBuilder WithParentInheritance(this DataEntryTaskBuilder source, short? parentEntry = null)
        {
            source.ParentCriteriaId = source.Criteria.ParentCriteriaId ?? Fixture.Integer();
            source.ParentEntryId = parentEntry ?? Fixture.Short();
            source.Inherited = 1;
            return source;
        }

        public static DataEntryTask BuildWithAvailableEvents(this DataEntryTaskBuilder source, InMemoryDbContext db, int numToGenerate)
        {
            var n = Enumerable.Range(0, numToGenerate).Select(_ => $"event{_}").ToArray();

            return BuildWithAvailableEvents(source, db, n);
        }

        public static DataEntryTask BuildWithAvailableEvents(this DataEntryTaskBuilder source, InMemoryDbContext db, params string[] events)
        {
            var entry = source.Build().In(db);
            for (var i = 0; i < events.Length; i++)
            {
                var e = db.Set<Event>().SingleOrDefault(_ => _.Description == events[i]) ??
                        new EventBuilder
                        {
                            Description = events[i]
                        }.Build().In(db);

                entry.AvailableEvents.Add(new AvailableEvent
                {
                    EventId = e.Id,
                    Event = e,
                    CriteriaId = source.Criteria.Id,
                    DataEntryTaskId = entry.Id,
                    Inherited = source.Inherited,
                    DisplaySequence = (short) i
                }.In(db));
            }

            return entry;
        }

        public static DataEntryTask BuildWithSteps(this DataEntryTaskBuilder source, InMemoryDbContext db, params string[] name)
        {
            var entry = source.Build().In(db);
            var workflowWizard = WindowControlBuilder.For(entry).Build().In(db);

            foreach (var n in name) BuildStep(entry, db, n).In(db);

            if (!entry.TaskSteps.Contains(workflowWizard))
            {
                entry.TaskSteps.Add(workflowWizard);
            }

            foreach (var topicControl in entry.WorkflowWizard?.TopicControls ?? Enumerable.Empty<TopicControl>()) topicControl.IsInherited = source.Inherited.HasValue && source.Inherited == 1;

            return entry;
        }

        public static DataEntryTask BuildWithSteps(this DataEntryTaskBuilder source, InMemoryDbContext db, int numberToGenerate)
        {
            var n = Enumerable.Range(0, numberToGenerate).Select(_ => $"frmStep{_}").ToArray();

            return BuildWithSteps(source, db, n);
        }

        public static DataEntryTask WithStep(this DataEntryTask entry, InMemoryDbContext db, string name, params TopicControlFilter[] filters)
        {
            entry.BuildStep(db, name, filters);
            return entry;
        }

        public static TopicControl BuildStep(this DataEntryTask entry, InMemoryDbContext db, string name, params TopicControlFilter[] filters)
        {
            var workflowWizard = db.Set<WindowControl>()
                                   .SingleOrDefault(_ => _.EntryNumber == entry.Id && _.CriteriaId == entry.CriteriaId) ??
                                 WindowControlBuilder.For(entry).Build().In(db);

            if (!entry.TaskSteps.Contains(workflowWizard))
            {
                entry.TaskSteps.Add(workflowWizard);
            }

            return TopicControlBuilder.For(workflowWizard, name, filters).Build().In(db);
        }

        public static DataEntryTask BuildWithDocuments(this DataEntryTaskBuilder source, InMemoryDbContext db, int numberToGenerate)
        {
            var entry = source.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++)
            {
                entry.DocumentRequirements.Add(new DocumentRequirementBuilder
                {
                    Criteria = source.Criteria,
                    DataEntryTask = entry,
                    Inherited = source.Inherited,
                    IsMandatory = Fixture.Boolean()
                }.Build().In(db));
            }

            return entry;
        }

        public static DataEntryTask BuildWithUserControls(this DataEntryTaskBuilder source, InMemoryDbContext db, int numberToGenerate)
        {
            var entry = source.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++)
            {
                entry.UsersAllowed.Add(new UserControlBuilder
                {
                    CriteriaNo = source.Criteria.Id,
                    EntryNumber = entry.Id,
                    Inherited = source.Inherited
                }.Build().In(db));
            }

            return entry;
        }

        public static DataEntryTask BuildWithGroupControls(this DataEntryTaskBuilder source, InMemoryDbContext db, int numberToGenerate)
        {
            var entry = source.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++)
            {
                entry.GroupsAllowed.Add(new GroupControl
                {
                    CriteriaId = source.Criteria.Id,
                    EntryId = entry.Id,
                    Inherited = source.Inherited
                }.In(db));
            }

            return entry;
        }
    }
}