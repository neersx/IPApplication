using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.ValidCombinations;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;
using KnownValues = InprotechKaizen.Model.KnownValues;
using RelatedCaseModel = InprotechKaizen.Model.Cases.RelatedCase;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class RelatedCasesFacts
    {
        public class CaseSetup
        {
            public CaseSetup(InMemoryDbContext db)
            {
                Case = new Case("IRN", new Country().In(db), new CaseType(), new PropertyType()).In(db);

                CaseRelationFromEvent = new EventBuilder().Build().In(db);
                CaseRelationDisplayEvent = new EventBuilder().Build().In(db);
                CaseRelation = new CaseRelationBuilder {FromEventId = CaseRelationFromEvent.Id}.Build().In(db);
                CaseRelation.ShowFlag = 1;

                ApplicationNumberType = new NumberType(KnownNumberTypes.Application, Fixture.String(), null, true).In(db);
            }

            public Case Case { get; set; }

            public CaseRelation CaseRelation { get; set; }

            public Event CaseRelationFromEvent { get; set; }

            public Event CaseRelationDisplayEvent { get; set; }

            public NumberType ApplicationNumberType { get; set; }
        }

        public class ForInternalUsers : FactBase
        {
            public ForInternalUsers()
            {
                _fixture = new CaseSetup(Db);
            }

            readonly ICaseAuthorization _caseAuthorization = Substitute.For<ICaseAuthorization>();
            readonly CaseSetup _fixture;

            IRelatedCases CreateSubject()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var securityContext = Substitute.For<ISecurityContext>();

                securityContext.User.Returns(new User(Fixture.String(), false));

                return new RelatedCases(securityContext, cultureResolver, Db, _caseAuthorization);
            }

            [Fact]
            public async Task ShouldIdentifyRelationshipAsPointingToChildWhenMatchingExternalCaseCharacteristics()
            {
                var externalRelatedCaseCountry = new CountryBuilder
                {
                    Name = Fixture.String()
                }.Build().In(Db);

                new RelatedCaseModel(_fixture.Case.Id, externalRelatedCaseCountry.Id, Fixture.String(), _fixture.CaseRelation).In(Db);

                var reciprocalRelationship = new CaseRelation
                {
                    Relationship = Fixture.String(),
                    PointsToParent = 1
                }.In(Db);

                // Use Current Cases' Property Type because assumption is reciprocal relationships do not deviate property types
                new ValidRelationship(externalRelatedCaseCountry, _fixture.Case.PropertyType, _fixture.CaseRelation, reciprocalRelationship).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.True(r.IsPointingToChild);
                Assert.Equal("down", r.Direction);
            }

            [Fact]
            public async Task ShouldIdentifyRelationshipAsPointingToChildWhenMatchingExternalCaseCharateristicsWithDefaultCountry()
            {
                var failbackCountryCode = new CountryBuilder
                {
                    Id = KnownValues.DefaultCountryCode
                }.Build().In(Db);

                var externalRelatedCaseCountry = new CountryBuilder
                {
                    Name = Fixture.String()
                }.Build().In(Db);

                new RelatedCaseModel(_fixture.Case.Id, externalRelatedCaseCountry.Id, Fixture.String(), _fixture.CaseRelation).In(Db);

                var reciprocalRelationship = new CaseRelation
                {
                    Relationship = Fixture.String(),
                    PointsToParent = 1
                }.In(Db);

                // Use Current Cases' Property Type because assumption is reciprocal relationships do not deviate property types
                new ValidRelationship(failbackCountryCode, _fixture.Case.PropertyType, _fixture.CaseRelation, reciprocalRelationship).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.True(r.IsPointingToChild);
                Assert.Equal("down", r.Direction);
            }

            [Fact]
            public async Task ShouldIdentifyRelationshipAsPointingToChildWhenMatchingOtherSideCaseCharateristics()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db),
                    PropertyType = new PropertyTypeBuilder().Build().In(Db)
                }.Build().In(Db);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var reciprocalRelationship = new CaseRelation
                {
                    Relationship = Fixture.String(),
                    PointsToParent = 1
                }.In(Db);

                new ValidRelationship(caseOtherSide.Country, caseOtherSide.PropertyType, _fixture.CaseRelation, reciprocalRelationship).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.True(r.IsPointingToChild);
                Assert.Equal("down", r.Direction);
            }

            [Fact]
            public async Task ShouldIdentifyRelationshipAsPointingToChildWhenMatchingOtherSideCaseCharateristicsWithDefaultCountry()
            {
                var failbackCountryCode = new CountryBuilder
                {
                    Id = KnownValues.DefaultCountryCode
                }.Build().In(Db);

                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db),
                    PropertyType = new PropertyTypeBuilder().Build().In(Db)
                }.Build().In(Db);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var reciprocalRelationship = new CaseRelation
                {
                    Relationship = Fixture.String(),
                    PointsToParent = 1
                }.In(Db);

                new ValidRelationship(failbackCountryCode, caseOtherSide.PropertyType, _fixture.CaseRelation, reciprocalRelationship).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.True(r.IsPointingToChild);
                Assert.Equal("down", r.Direction);
            }

            [Fact]
            public async Task ShouldIdentifyRelationshipAsPointingToParent()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                _fixture.CaseRelation.PointsToParent = 1;

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.True(r.IsPointingToParent);
                Assert.Equal("up", r.Direction);
            }

            [Fact]
            public async Task ShouldIdentifyRelationshipIsNeitherPointingToParentNorToChild()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.False(r.IsPointingToParent);
                Assert.Null(r.Direction);
            }

            [Fact]
            public async Task ShouldNotReturnInaccessibleCases()
            {
                RelatedCaseModel CreateRelatedCase()
                {
                    var rc = new CaseBuilder
                    {
                        Country = new CountryBuilder().Build().In(Db)
                    }.Build().In(Db);

                    rc.CaseEvents.Add(new CaseEvent(rc.Id, _fixture.CaseRelationFromEvent.Id, 1)
                    {
                        EventDate = Fixture.Today(),
                        IsOccurredFlag = 1
                    }.In(Db));

                    return new RelatedCaseModel(_fixture.Case.Id, rc.Country.Id, null, _fixture.CaseRelation, rc.Id) {RelationshipNo = Fixture.Integer()}.In(Db);
                }

                var a = CreateRelatedCase();

                var c = CreateRelatedCase();

                var b = CreateRelatedCase();

                _caseAuthorization.AccessibleCases(Arg.Any<int[]>()).Returns(new[] {a.RelatedCaseId.Value, c.RelatedCaseId.Value});

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Select(_ => _.CaseId).ToArray();

                Assert.Contains(a.RelatedCaseId, r);
                Assert.Contains(c.RelatedCaseId, r);

                Assert.DoesNotContain(b.RelatedCaseId, r);
            }

            [Fact]
            public async Task ShouldReturnClassesFromExternalRelatedCase()
            {
                var classesRecordedAgainstTheRelatedCase = Fixture.String();

                var externalRelatedCaseCountry = new CountryBuilder
                {
                    Name = Fixture.String()
                }.Build().In(Db);

                new RelatedCaseModel(_fixture.Case.Id, _fixture.CaseRelation.Relationship, externalRelatedCaseCountry.Id)
                {
                    Class = classesRecordedAgainstTheRelatedCase
                }.In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(classesRecordedAgainstTheRelatedCase, r.Classes);
            }

            [Fact]
            public async Task ShouldReturnCountryDetailsFromExternalRelatedCase()
            {
                var externalRelatedCaseCountry = new CountryBuilder
                {
                    Name = Fixture.String()
                }.Build().In(Db);

                new RelatedCaseModel(_fixture.Case.Id, _fixture.CaseRelation.Relationship, externalRelatedCaseCountry.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(externalRelatedCaseCountry.Id, r.CountryCode);
                Assert.Equal(externalRelatedCaseCountry.Name, r.Jurisdiction);
            }

            [Fact]
            public async Task ShouldReturnCountryDetailsFromInternalRelatedCase()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(caseOtherSide.Country.Id, r.CountryCode);
                Assert.Equal(caseOtherSide.Country.Name, r.Jurisdiction);
            }

            [Fact]
            public async Task ShouldReturnEventDateFromRelationshipDisplayEvent()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                caseOtherSide.CaseEvents.Add(new CaseEvent(caseOtherSide.Id, _fixture.CaseRelationDisplayEvent.Id, 1)
                {
                    EventDate = Fixture.PastDate(),
                    IsOccurredFlag = 1
                }.In(Db));

                _fixture.CaseRelation.DisplayEvent = _fixture.CaseRelationDisplayEvent;
                _fixture.CaseRelation.DisplayEventId = _fixture.CaseRelationDisplayEvent.Id;
                _fixture.CaseRelation.FromEvent = null;
                _fixture.CaseRelation.FromEventId = null;

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(Fixture.PastDate(), r.EventDate);
            }

            [Fact]
            public async Task ShouldReturnEventDateFromRelationshipFromEventIfDisplayEventNotExists()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                caseOtherSide.CaseEvents.Add(new CaseEvent(caseOtherSide.Id, _fixture.CaseRelationFromEvent.Id, 1)
                {
                    EventDate = Fixture.PastDate(),
                    IsOccurredFlag = 1
                }.In(Db));

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(Fixture.PastDate(), r.EventDate);
            }

            [Fact]
            public async Task ShouldReturnEventDescriptionFromOpenActionCycleCriterion()
            {
                void ConfigureCaseEventHavingControllingActionCriteriaDescription(Case @case, Event @event, string specificDescription)
                {
                    @case.CaseEvents.Add(new CaseEvent(@case.Id, @event.Id, 1)
                    {
                        EventDate = Fixture.PastDate(),
                        IsOccurredFlag = 1
                    }.In(Db));

                    var action = new Action().In(Db);
                    @event.ControllingAction = action.Code;

                    var c = new Criteria().In(Db);
                    @case.OpenActions.Add(new OpenAction(action, @case, 1, "status", c, true).In(Db));

                    new ValidEvent(c, @event, specificDescription).In(Db);
                }

                var specificEventDescription = Fixture.String();

                var caseOtherSide = new CaseBuilder {Country = _fixture.Case.Country}.Build().In(Db);

                ConfigureCaseEventHavingControllingActionCriteriaDescription(caseOtherSide, _fixture.CaseRelationFromEvent, specificEventDescription);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(specificEventDescription, r.EventDescription);
            }

            [Fact]
            public async Task ShouldReturnInternalStatusDescription()
            {
                var caseOtherSideStatus = new Status(Fixture.Short(), Fixture.String())
                {
                    ExternalName = Fixture.String()
                }.In(Db);

                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db),
                    Status = caseOtherSideStatus
                }.Build().In(Db);

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(caseOtherSideStatus.Name, r.Status);
            }

            [Fact]
            public async Task ShouldReturnLocalClassesFromInternalRelatedCase()
            {
                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                caseOtherSide.LocalClasses = Fixture.String();

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(caseOtherSide.LocalClasses, r.Classes);
            }

            [Fact]
            public async Task ShouldReturnOfficialNumberFromEarliestPriorityRelationship()
            {
                var priorityNumber = Fixture.String();

                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                caseOtherSide.OfficialNumbers.Add(new OfficialNumber(_fixture.ApplicationNumberType, caseOtherSide, priorityNumber)
                {
                    IsCurrent = 1
                }.In(Db));

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                new SiteControl
                {
                    ControlId = SiteControls.EarliestPriority,
                    StringValue = _fixture.CaseRelation.Relationship
                }.In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(priorityNumber, r.OfficialNumber);
            }

            [Fact]
            public async Task ShouldReturnOfficialNumberFromOthersideCurrentNumber()
            {
                var currentOfficialNumberInOthersideCase = Fixture.String();

                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db)
                }.Build().In(Db);

                caseOtherSide.OfficialNumbers.Add(new OfficialNumber(_fixture.ApplicationNumberType, caseOtherSide, currentOfficialNumberInOthersideCase)
                {
                    IsCurrent = 1
                }.In(Db));

                caseOtherSide.CurrentOfficialNumber = currentOfficialNumberInOthersideCase;

                _caseAuthorization.AccessibleCases(caseOtherSide.Id).Returns(new[] {caseOtherSide.Id});

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(currentOfficialNumberInOthersideCase, r.OfficialNumber);
            }

            [Fact]
            public async Task ShouldReturnOfficialNumberHeldExternally()
            {
                var numberHeldExternally = Fixture.String();

                new RelatedCaseModel(_fixture.Case.Id, _fixture.Case.Country.Id, numberHeldExternally, _fixture.CaseRelation, null).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(numberHeldExternally, r.OfficialNumber);
            }

            [Fact]
            public async Task ShouldSortByDateIfConfigured()
            {
                RelatedCaseModel CreateCaseWithEventDate(DateTime eventDate, int relationshipNo)
                {
                    var rc = new CaseBuilder
                    {
                        Country = new CountryBuilder().Build().In(Db)
                    }.Build().In(Db);

                    rc.CaseEvents.Add(new CaseEvent(rc.Id, _fixture.CaseRelationFromEvent.Id, 1)
                    {
                        EventDate = eventDate,
                        IsOccurredFlag = 1
                    }.In(Db));

                    return new RelatedCaseModel(_fixture.Case.Id, rc.Country.Id, null, _fixture.CaseRelation, rc.Id) {RelationshipNo = relationshipNo}.In(Db);
                }

                var second = CreateCaseWithEventDate(Fixture.Today(), 3);

                var third = CreateCaseWithEventDate(Fixture.FutureDate(), 1);

                var first = CreateCaseWithEventDate(Fixture.PastDate(), 2);

                _caseAuthorization.AccessibleCases(Arg.Any<int[]>()).Returns(x => ((int[]) x[0]).AsEnumerable());

                var subject = CreateSubject();

                new SiteControl(SiteControls.RelatedCasesSortOrder) {StringValue = "DATE"}.In(Db);

                var r = (await subject.Retrieve(_fixture.Case.Id)).ToArray();

                Assert.Equal(first.RelationshipNo, r[0].RelationshipNo);
                Assert.Equal(second.RelationshipNo, r[1].RelationshipNo);
                Assert.Equal(third.RelationshipNo, r[2].RelationshipNo);
            }

            [Fact]
            public async Task ShouldSortByOrderIfNotConfigured()
            {
                RelatedCaseModel CreateCaseWithEventDate(DateTime eventDate, int relationshipNo)
                {
                    var rc = new CaseBuilder
                    {
                        Country = new CountryBuilder().Build().In(Db)
                    }.Build().In(Db);

                    rc.CaseEvents.Add(new CaseEvent(rc.Id, _fixture.CaseRelationFromEvent.Id, 1)
                    {
                        EventDate = eventDate,
                        IsOccurredFlag = 1
                    }.In(Db));

                    return new RelatedCaseModel(_fixture.Case.Id, rc.Country.Id, null, _fixture.CaseRelation, rc.Id) {RelationshipNo = relationshipNo}.In(Db);
                }

                var third = CreateCaseWithEventDate(Fixture.Today(), 3);

                var first = CreateCaseWithEventDate(Fixture.FutureDate(), 1);

                var second = CreateCaseWithEventDate(Fixture.PastDate(), 2);

                _caseAuthorization.AccessibleCases(Arg.Any<int[]>()).Returns(x => ((int[]) x[0]).AsEnumerable());

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).ToArray();

                Assert.Equal(first.RelationshipNo, r[0].RelationshipNo);
                Assert.Equal(second.RelationshipNo, r[1].RelationshipNo);
                Assert.Equal(third.RelationshipNo, r[2].RelationshipNo);
            }
        }

        public class ForExternalUsers : FactBase
        {
            public ForExternalUsers()
            {
                _fixture = new CaseSetup(Db);
            }

            readonly ICaseAuthorization _caseAuthorization = Substitute.For<ICaseAuthorization>();
            readonly CaseSetup _fixture;

            IRelatedCases CreateSubject()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var securityContext = Substitute.For<ISecurityContext>();

                securityContext.User.Returns(new User(Fixture.String(), true));

                return new RelatedCases(securityContext, cultureResolver, Db, _caseAuthorization);
            }

            [Fact]
            public async Task ShouldReturnClientReference()
            {
                var clientRef = Fixture.String();

                var caseOtherSideStatus = new Status(Fixture.Short(), Fixture.String())
                {
                    ExternalName = Fixture.String()
                }.In(Db);

                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db),
                    Status = caseOtherSideStatus
                }.Build().In(Db);

                new FilteredUserCase
                {
                    ClientReferenceNo = clientRef
                }.In(Db).WithKnownId(x => x.CaseId, caseOtherSide.Id);

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(clientRef, r.ClientReference);
            }

            [Fact]
            public async Task ShouldReturnExternalStatusDescription()
            {
                var caseOtherSideStatus = new Status(Fixture.Short(), Fixture.String())
                {
                    ExternalName = Fixture.String()
                }.In(Db);

                var caseOtherSide = new CaseBuilder
                {
                    Country = new CountryBuilder().Build().In(Db),
                    Status = caseOtherSideStatus
                }.Build().In(Db);

                new FilteredUserCase().In(Db).WithKnownId(x => x.CaseId, caseOtherSide.Id);

                new RelatedCaseModel(_fixture.Case.Id, caseOtherSide.Country.Id, null, _fixture.CaseRelation, caseOtherSide.Id).In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Single();

                Assert.Equal(caseOtherSideStatus.ExternalName, r.Status);
            }

            [Fact]
            public async Task ShouldReturnViewableRelatedCases()
            {
                RelatedCaseModel CreateRelatedCase(bool visibleToExternalUser)
                {
                    var rc = new CaseBuilder
                    {
                        Country = new CountryBuilder().Build().In(Db)
                    }.Build().In(Db);

                    rc.CaseEvents.Add(new CaseEvent(rc.Id, _fixture.CaseRelationFromEvent.Id, 1)
                    {
                        EventDate = Fixture.Today(),
                        IsOccurredFlag = 1
                    }.In(Db));

                    if (visibleToExternalUser)
                    {
                        new FilteredUserCase().In(Db).WithKnownId(x => x.CaseId, rc.Id);
                    }

                    return new RelatedCaseModel(_fixture.Case.Id, rc.Country.Id, null, _fixture.CaseRelation, rc.Id) {RelationshipNo = Fixture.Integer()}.In(Db);
                }

                var a = CreateRelatedCase(true);

                var c = CreateRelatedCase(false);

                var b = CreateRelatedCase(true);

                var subject = CreateSubject();

                var r = (await subject.Retrieve(_fixture.Case.Id)).Select(_ => _.CaseId).ToArray();

                Assert.Contains(a.RelatedCaseId, r);
                Assert.Contains(b.RelatedCaseId, r);

                Assert.DoesNotContain(c.RelatedCaseId, r);
            }
        }
    }
}