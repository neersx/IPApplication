using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using Xunit;
using model = InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Configuration.Rules.EventControlMaintenance
{
    public class DesignatedJurisdictionsFacts
    {
        public class ValidateMethod : FactBase
        {
            [Fact]
            public void DoesNotThrowIfNoErrors()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var country = new CountryBuilder {Id = "AAA"}.Build();
                country.Type = "1";
                var criteria = new CriteriaBuilder {Country = country}.Build().In(Db);
                var delta = new Delta<string> {Added = new[] {"A"}};
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, CriteriaId = criteria.Id, DesignatedJurisdictionsDelta = delta};
                new CountryGroupBuilder {Id = country.Id, CountryCode = "A"}.Build().In(Db);
                var result = f.Subject.Validate(saveModel);
                Assert.Empty(result);
            }

            [Fact]
            public void ThrowsErrorIfCriteriaIsNotFromAGroupCountry()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var country = new CountryBuilder {Id = "ZZZ"}.Build();
                country.Type = "0";
                var criteria = new CriteriaBuilder {Country = country}.Build().In(Db);
                var delta = new Delta<string> {Added = new[] {"A"}};
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, CriteriaId = criteria.Id, DesignatedJurisdictionsDelta = delta};

                var result = f.Subject.Validate(saveModel);
                Assert.NotEmpty(result);
            }

            [Fact]
            public void ThrowsErrorIfDesignatedJurisdictionIsNotAMemberOfGroupCountry()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var country = new CountryBuilder {Id = "AAA"}.Build();
                country.Type = "1";
                var criteria = new CriteriaBuilder {Country = country}.Build().In(Db);
                var delta = new Delta<string> {Added = new[] {"A"}};
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, CriteriaId = criteria.Id, DesignatedJurisdictionsDelta = delta};

                var result = f.Subject.Validate(saveModel);
                Assert.NotEmpty(result);
            }
        }

        public class ApplyChangesMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void AddsOrInheritsNewDesignatedJurisdictions(bool inherit)
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();
                var jurisdiction = Fixture.String();
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = sequence, JurisdictionId = jurisdiction}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = inherit ? Fixture.Integer() : criteria.Id, DesignatedJurisdictionsDelta = new Delta<string> {Added = new List<string>()}};
                var newDesignatedJurisdiction = Fixture.String();
                saveModel.DesignatedJurisdictionsDelta.Added.Add(newDesignatedJurisdiction);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Add(newDesignatedJurisdiction);

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                Assert.Equal(2, eventRule.DueDateCalcs.Count);
                var addedRule = eventRule.DueDateCalcs.SingleOrDefault(_ => _.JurisdictionId == newDesignatedJurisdiction);
                Assert.NotNull(addedRule);
                Assert.Equal(sequence + 1, addedRule.Sequence);
                Assert.Equal(inherit, addedRule.IsInherited);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ResetsInheritanceFlagOnMainEventControl(bool isMainEventControl)
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();

                var jurisdiction1 = Fixture.String();
                var jurisdiction2 = Fixture.String();

                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = sequence, JurisdictionId = jurisdiction1, Inherited = 0}.For(eventRule).Build());
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = sequence, JurisdictionId = jurisdiction2, Inherited = 0}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = isMainEventControl ? criteria.Id : Fixture.Integer()};
                saveModel.ResetInheritance = true;

                var fieldsToUpdate = new EventControlFieldsToUpdate();

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                if (isMainEventControl)
                {
                    Assert.True(eventRule.DueDateCalcs.All(_ => _.IsInherited));
                }
                else
                {
                    Assert.True(eventRule.DueDateCalcs.All(_ => !_.IsInherited));
                }
            }

            [Fact]
            public void ClearsCountryStopRemindersFlagWhenDeletingAllDesignations()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var validEvent = new ValidEventBuilder().Build();
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = Fixture.Integer(), ApplyToDescendants = true};
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                validEvent.CheckCountryFlag = Fixture.Integer();

                validEvent.DueDateCalcs.Add(new model.DueDateCalc(validEvent, 0) {JurisdictionId = "A"});
                fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.Add("A");

                f.Subject.ApplyChanges(validEvent, saveModel, fieldsToUpdate);

                Assert.Null(validEvent.CheckCountryFlag);
            }

            [Fact]
            public void DeletesDesignatedJurisdictions()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var jurisdictionDelete = Fixture.String();
                var jurisdictionDelete1 = Fixture.String();
                var jurisdictionDontDelete = Fixture.String();
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = jurisdictionDelete, Inherited = 1}.For(eventRule).Build());
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = jurisdictionDelete1, Inherited = 0}.For(eventRule).Build());
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = jurisdictionDontDelete, Inherited = 0}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteria.Id, DesignatedJurisdictionsDelta = new Delta<string>()};
                saveModel.DesignatedJurisdictionsDelta.Deleted.AddRange(new[] {jurisdictionDelete, jurisdictionDelete1});

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.AddRange(new[] {jurisdictionDelete, jurisdictionDelete1});

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                Assert.Equal(1, eventRule.DueDateCalcs.Count);
                Assert.Equal(jurisdictionDontDelete, eventRule.DueDateCalcs.Single().JurisdictionId);
            }

            [Fact]
            public void ForcesACountryStopRemindersFlagWhenChildDoesntHaveOneSet()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var validEvent = new ValidEventBuilder().Build();
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = Fixture.Integer(), ApplyToDescendants = true};
                saveModel.CountryFlagForStopReminders = Fixture.Integer();

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                validEvent.CheckCountryFlag = null;
                fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Add("A");
                fieldsToUpdate.CheckCountryFlag = false;

                f.Subject.ApplyChanges(validEvent, saveModel, fieldsToUpdate);

                Assert.Equal(saveModel.CheckCountryFlag, validEvent.CheckCountryFlag);
            }

            [Fact]
            public void OnlyDeletesInheritedChildDesignatedJurisdictions()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var sequence = Fixture.Short();
                var jurisdictionDelete = Fixture.String();
                var jurisdictionDontDelete = Fixture.String();
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = sequence, JurisdictionId = jurisdictionDelete, Inherited = 1}.For(eventRule).Build());
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = sequence, JurisdictionId = jurisdictionDontDelete, Inherited = 0}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = Fixture.Integer(), DesignatedJurisdictionsDelta = new Delta<string> {Deleted = new List<string>()}};
                saveModel.DesignatedJurisdictionsDelta.Deleted.Add(jurisdictionDelete);

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.Add(jurisdictionDelete);

                f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate);

                Assert.Equal(1, eventRule.DueDateCalcs.Count);
                Assert.Equal(jurisdictionDontDelete, eventRule.DueDateCalcs.Single().JurisdictionId);
            }

            [Fact]
            public void PreventsClearingOfCountryStopRemindersFlagIfDesignationsRemain()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var validEvent = new ValidEventBuilder().Build();
                var saveModel = new WorkflowEventControlSaveModel {OriginatingCriteriaId = Fixture.Integer(), ApplyToDescendants = true, CheckCountryFlag = null};
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                validEvent.CheckCountryFlag = Fixture.Integer();
                validEvent.DueDateCalcs.Add(new model.DueDateCalc(validEvent, 0) {JurisdictionId = "A"});

                Assert.True(fieldsToUpdate.CheckCountryFlag);

                f.Subject.ApplyChanges(validEvent, saveModel, fieldsToUpdate);

                Assert.False(fieldsToUpdate.CheckCountryFlag);
            }

            [Fact]
            public void ThrowsErrorWhenAddingDuplicateJurisdiction()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build().In(Db);
                var jurisdiction = Fixture.String();
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = jurisdiction}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel();

                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Add(jurisdiction);

                Assert.Throws<InvalidOperationException>(() => f.Subject.ApplyChanges(eventRule, saveModel, fieldsToUpdate));
            }
        }

        public class SetChildInheritanceDeltaMethod : FactBase
        {
            [Fact]
            public void DeletesExistingInheritedJurisdictions()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                criteria.Country = new CountryBuilder {Type = "1"}.Build();
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();

                var deleted = Fixture.String();
                var existing = Fixture.String();

                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = existing, Inherited = 0}.For(eventRule).Build());
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = deleted, Inherited = 1}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DesignatedJurisdictionsDelta = new Delta<string>
                {
                    Deleted = new[] {deleted, existing}
                };

                f.Subject.SetChildInheritanceDelta(eventRule, saveModel, fieldsToUpdate);
                Assert.Equal(deleted, fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.Single());
            }

            [Fact]
            public void DoesNotPassJurisdictionsToNonGroupChildren()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                var country = new CountryBuilder {Type = "0"}.Build();
                criteria.Country = country;
                criteria.CountryId = country.Id;
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();
                var saveModel = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                saveModel.DesignatedJurisdictionsDelta.Added.Add(Fixture.String());
                fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Add(Fixture.String());

                f.Subject.SetChildInheritanceDelta(eventRule, saveModel, fieldsToUpdate);
                Assert.Empty(fieldsToUpdate.DesignatedJurisdictionsDelta.Added);

                criteria.CountryId = null;
                f.Subject.SetChildInheritanceDelta(eventRule, saveModel, fieldsToUpdate);
                Assert.Empty(fieldsToUpdate.DesignatedJurisdictionsDelta.Added);
            }

            [Fact]
            public void IncludesNonExistingJurisdictions()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build().In(Db);
                criteria.Country = new CountryBuilder {Type = "1"}.Build();
                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();

                var added = Fixture.String();
                var existing = Fixture.String();

                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = existing, Inherited = 0}.For(eventRule).Build());

                var saveModel = new WorkflowEventControlSaveModel();
                var fieldsToUpdate = new EventControlFieldsToUpdate();
                fieldsToUpdate.DesignatedJurisdictionsDelta = new Delta<string>
                {
                    Added = new[] {added, existing}
                };

                f.Subject.SetChildInheritanceDelta(eventRule, saveModel, fieldsToUpdate);
                Assert.Equal(added, fieldsToUpdate.DesignatedJurisdictionsDelta.Added.Single());
            }
        }

        public class RemoveInheritanceMethod : FactBase
        {
            [Fact]
            public void RemovesInheritanceForDeletedJurisdictions()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var baseEvent = new Event(Fixture.Integer());
                var criteria = new CriteriaBuilder().Build();

                var eventRule = new ValidEventBuilder().For(criteria, baseEvent).Build();
                var fieldsToUpdate = new EventControlFieldsToUpdate();

                var deleted = Fixture.String();
                var notDeleted = Fixture.String();
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = deleted, Inherited = 1}.For(eventRule).Build());
                eventRule.DueDateCalcs.Add(new DueDateCalcBuilder {Sequence = Fixture.Short(), JurisdictionId = notDeleted, Inherited = 1}.For(eventRule).Build());

                fieldsToUpdate.DesignatedJurisdictionsDelta.Deleted.Add(deleted);

                f.Subject.RemoveInheritance(eventRule, fieldsToUpdate);
                Assert.False(eventRule.DueDateCalcs.Single(d => d.JurisdictionId == deleted).IsInherited);
                Assert.True(eventRule.DueDateCalcs.Single(d => d.JurisdictionId == notDeleted).IsInherited);
            }
        }

        public class ResetMethod : FactBase
        {
            [Fact]
            public void AddsIfNotExisting()
            {
                var f = new DesignatedJurisdictionsFixture(Db);
                var @event = new EventBuilder().Build();
                var criteria = new CriteriaBuilder().WithCountry().Build().In(Db);
                criteria.Country.Type = "1";

                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var resetEvent = new ValidEventBuilder().For(criteria, @event).Build();

                var designatedJurisdiction = new DueDateCalcSaveModel();
                designatedJurisdiction.JurisdictionId = Fixture.String();
                parent.DueDateCalcs.Add(designatedJurisdiction);

                f.Subject.Reset(newValues, parent, resetEvent);

                var added = newValues.DesignatedJurisdictionsDelta.Added.First();
                Assert.Equal(designatedJurisdiction.JurisdictionId, added);
                Assert.Empty(newValues.DesignatedJurisdictionsDelta.Updated);
                Assert.Empty(newValues.DesignatedJurisdictionsDelta.Deleted);
            }

            [Fact]
            public void DeletesIfNotInParent()
            {
                var f = new DesignatedJurisdictionsFixture(Db);

                var @event = new EventBuilder().Build();
                var criteria = new CriteriaBuilder().WithCountry().Build().In(Db);

                criteria.Country.Type = "1";
                var newValues = new WorkflowEventControlSaveModel();
                var parent = new ValidEventBuilder().Build();
                var resetEvent = new ValidEventBuilder().For(criteria, @event).Build();

                var designatedJurisdiction = new DueDateCalcSaveModel();
                designatedJurisdiction.JurisdictionId = Fixture.String();
                resetEvent.DueDateCalcs.Add(designatedJurisdiction);

                f.Subject.Reset(newValues, parent, resetEvent);

                var deleted = newValues.DesignatedJurisdictionsDelta.Deleted.First();
                Assert.Equal(designatedJurisdiction.JurisdictionId, deleted);
                Assert.Empty(newValues.DesignatedJurisdictionsDelta.Added);
                Assert.Empty(newValues.DesignatedJurisdictionsDelta.Updated);
            }
        }
    }

    public class DesignatedJurisdictionsFixture : IFixture<DesignatedJurisdictions>
    {
        public DesignatedJurisdictionsFixture(InMemoryDbContext db)
        {
            Subject = new DesignatedJurisdictions(db);
        }

        public DesignatedJurisdictions Subject { get; }
    }
}