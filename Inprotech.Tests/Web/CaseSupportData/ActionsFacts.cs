using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;

// ReSharper disable ParameterOnlyUsedForPreconditionCheck.Local

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class ActionsFacts
    {
        public class ActionsMethod : FactBase
        {
            [Fact]
            public void ReturnsBaseActionList()
            {
                var f = new ActionsFixture(Db);

                var a1 = new ActionBuilder { Id = "AB", Name = "DEFGHI", NumberOfCyclesAllowed = 1, ActionType = 2 }.Build().In(Db);
                var a2 = new ActionBuilder { Id = "CD", Name = "ABCDEFG", NumberOfCyclesAllowed = 2, ActionType = 1 }.Build().In(Db);

                var r = f.Subject.Get(string.Empty, string.Empty, string.Empty);

                var a = r.ToArray();

                Assert.Equal(a1.Code, a[0].Code);
                Assert.Equal(a1.Name, a[0].Name);
                Assert.Equal(a1.NumberOfCyclesAllowed, a[0].Cycles);
                Assert.Equal(a1.ActionType, a[0].ActionType);

                Assert.Equal(a2.Code, a[1].Code);
                Assert.Equal(a2.Name, a[1].Name);
                Assert.Equal(a2.NumberOfCyclesAllowed, a[1].Cycles);
                Assert.Equal(a2.ActionType, a[1].ActionType);
            }

            [Fact]
            public void ReturnsBaseIfKeyNotFoundInValidList()
            {
                var f = new ActionsFixture(Db);

                var a1 = new ActionBuilder { Id = "AB", Name = "DEFGHI", NumberOfCyclesAllowed = 1 }.Build().In(Db);
                new ActionBuilder { Id = "CD", Name = "ABCDEFG", NumberOfCyclesAllowed = 2 }.Build().In(Db);

                new ValidActionBuilder
                {
                    ActionName = "ValidDefault",
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db),
                    Action = new ActionBuilder { Id = "CD", Name = "DEFGHI", NumberOfCyclesAllowed = 2 }.Build().In(Db)
                }.Build().In(Db);

                var r = f.Subject.Get("AN", "P", "A", a1.Code);
                var a = r.ToArray();

                Assert.Equal(a1.Code, a[0].Code);
                Assert.Equal(a1.Name, a[0].Name);
            }

            [Fact]
            public void ReturnsValidActions()
            {
                var f = new ActionsFixture(Db);

                var a1 =
                    new ValidActionBuilder
                    {
                        ActionName = "Valid",
                        Country = new CountryBuilder { Id = "AU" }.Build().In(Db),
                        CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                        PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db),
                        Action =
                            new ActionBuilder { Id = "AB", Name = "ABCDEFG", NumberOfCyclesAllowed = 1, ActionType = 2 }.Build().In(Db)
                    }.Build().In(Db);

                var a2 = new ValidActionBuilder
                {
                    ActionName = "Invalid",
                    Country = new CountryBuilder { Id = "US" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "E" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "T" }.Build().In(Db)
                }.Build().In(Db);

                var r = f.Subject.Get("AU", "P", "A");
                var result = r.ToArray();

                Assert.Single(result);
                Assert.Equal(a1.Action.Code, result[0].Code);
                Assert.Equal(a1.ActionName, result[0].Name);
                Assert.Equal(a1.Action.NumberOfCyclesAllowed, result[0].Cycles);
                Assert.Null(result.FirstOrDefault(_ => _.Name == a2.ActionName));
                Assert.Equal(a1.Action.ActionType, result[0].ActionType);
            }

            [Fact]
            public void ReturnsValidActionsForDefaultCountry()
            {
                var f = new ActionsFixture(Db);

                var defaultAction = new ValidActionBuilder
                {
                    ActionName = "ValidDefault",
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db),
                    Action = new ActionBuilder { Id = "CD", Name = "DEFGHI", NumberOfCyclesAllowed = 2 }.Build().In(Db)
                }.Build().In(Db);

                var a2 = new ValidActionBuilder
                {
                    ActionName = "InvalidDefault",
                    CaseType = new CaseTypeBuilder { Id = "E" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "T" }.Build().In(Db)
                }.Build().In(Db);

                var r = f.Subject.Get("AN", "P", "A");
                var a = r.ToArray();

                Assert.Equal(defaultAction.Action.Code, a[0].Code);
                Assert.Equal(defaultAction.ActionName, a[0].Name);
                Assert.Equal(defaultAction.Action.NumberOfCyclesAllowed, a[0].Cycles);
                Assert.Null(a.FirstOrDefault(_ => _.Name == a2.ActionName));
            }
        }

        public class ActionDataModel : FactBase
        {
            [Fact]
            public void ReturnsCyclesAsOneByDefault()
            {
                var action = new ActionData();
                Assert.Equal((short?)1, action.Cycles);

                var cycles = Fixture.Short();
                action.Cycles = cycles;
                Assert.Equal(cycles, action.Cycles);
            }
        }

        public class CaeViewActionsMethod : FactBase
        {
            [Fact]
            public void ReturnsBaseNameIfNotFoundInAction()
            {
                var f = new ActionsFixture(Db);

                var @case = new CaseBuilder
                {
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db)
                }.Build().In(Db);

                var a1 = new ActionBuilder { Id = "AB", Name = "DEFGHI", NumberOfCyclesAllowed = 1 }.Build().In(Db);
                var a2 = new ActionBuilder { Id = "CD", Name = "NameFromBase", NumberOfCyclesAllowed = 2 }.Build().In(Db);

                var valid = new ValidActionBuilder
                {
                    ActionName = "ValidDefault",
                    Country = @case.Country,
                    CaseType = @case.Type,
                    PropertyType = @case.PropertyType,
                    Action = a1
                }.Build().In(Db);

                var validBaseName = new ValidActionBuilder
                {
                    Country = @case.Country,
                    CaseType = @case.Type,
                    PropertyType = @case.PropertyType,
                    Action = a2
                }.Build().In(Db);

                new OpenActionBuilder(Db)
                {
                    Action = valid.Action,
                    Case = @case,
                    Cycle = 1
                }.Build().In(Db);

                new OpenActionBuilder(Db)
                {
                    Action = validBaseName.Action,
                    Case = @case,
                    Cycle = 2
                }.Build().In(Db);

                var r = f.Subject.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);
                var a = r.ToArray();

                Assert.Equal(2, a.Length);
                Assert.Equal(valid.ActionName, a[0].Name);
                Assert.Equal(false, a[0].HasEditableCriteria);
                Assert.Equal(validBaseName.Action.Name, a[1].Name);
            }

            dynamic SetupData(decimal userDefinedRule)
            {
                var c1 = new Criteria {Id = Fixture.Integer(), UserDefinedRule = userDefinedRule, PurposeCode = CriteriaPurposeCodes.EventsAndEntries}.In(Db);

                var a1 = new ActionBuilder { Id = "AB", Name = "DEFGHI", NumberOfCyclesAllowed = 1, ActionType = 2 }.Build().In(Db);
                var a2 = new ActionBuilder { Id = "CD", Name = "ABCDEFG", NumberOfCyclesAllowed = 2, ActionType = 1 }.Build().In(Db);
                var @case = new CaseBuilder
                {
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db)
                }.Build().In(Db);
                var oa1 = OpenActionBuilder.ForCaseAsValid(Db, @case, a1, c1).Build().In(Db);
                var oa2 = OpenActionBuilder.ForCaseAsValid(Db, @case, a2, c1).Build().In(Db);

                return new
                {
                    a1,
                    a2,
                    @case,
                    oa1,
                    oa2
                };
            }

            [Fact]
            public void ReturnsOrderedCaseViewActionList()
            {
                var f = new ActionsFixture(Db);
                var data = SetupData(1);
                var @case = data.@case as Case;

                var r = f.Subject.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);

                var a = r.ToArray();

                void AssertFor(OpenAction oa, Action ac, ActionData resp)
                {
                    Assert.Equal(oa.ActionId, resp.Code);
                    Assert.Equal(ac.Name, resp.Name);
                    Assert.Equal(oa.Cycle, resp.Cycle);
                    Assert.Equal(oa.PoliceEvents == 1, resp.IsOpen);
                }

                var isFirstCycleSmaller = data.oa1.Cycle < data.oa2.Cycle;
                AssertFor(isFirstCycleSmaller ? data.oa1 : data.oa2, isFirstCycleSmaller ? data.a1 : data.a2, a[0]);
                AssertFor(isFirstCycleSmaller ? data.oa2 : data.oa1, isFirstCycleSmaller ? data.a2 : data.a1, a[1]);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public void CheckEditableCriteriaForProtectedActionCriteria(bool hasProtectedRuleRights, bool expected)
            {
                var data = SetupData(0);
                var @case = data.@case as Case;
                var f = new ActionsFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected).Returns(hasProtectedRuleRights);

                var r = f.Subject.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);
                var a = r.ToArray();

                Assert.Equal(expected, a[0].HasEditableCriteria);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, false)]
            public void CheckEditableCriteriaForUnprotectedActionCriteria(bool hasUnProtectedRuleRights, bool expected)
            {
                var data = SetupData(1);
                var @case = data.@case as Case;
                var f = new ActionsFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules).Returns(hasUnProtectedRuleRights);

                var r = f.Subject.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);
                var a = r.ToArray();

                Assert.Equal(expected, a[0].HasEditableCriteria);
            }

            [Fact]
            public void ReturnsValidActionsForDefaultCountry()
            {
                var f = new ActionsFixture(Db);

                var @case = new CaseBuilder
                {
                    Country = new CountryBuilder { Id = "ZZZ" }.Build().In(Db),
                    CaseType = new CaseTypeBuilder { Id = "A" }.Build().In(Db),
                    PropertyType = new PropertyTypeBuilder { Id = "P" }.Build().In(Db)
                }.Build().In(Db);

                var defaultAction = new ValidActionBuilder
                {
                    ActionName = "ValidDefault",
                    Country = @case.Country,
                    CaseType = @case.Type,
                    PropertyType = @case.PropertyType,
                    Action = new ActionBuilder { Id = "CD", Name = "DEFGHI", NumberOfCyclesAllowed = 2 }.Build().In(Db)
                }.Build().In(Db);

                var a2 = new ValidActionBuilder
                {
                    ActionName = "InvalidDefault",
                    CaseType = @case.Type,
                    PropertyType = @case.PropertyType
                }.Build().In(Db);

                var oa1 = new OpenActionBuilder(Db)
                {
                    Action = defaultAction.Action,
                    Case = @case
                }.Build().In(Db);
                new OpenActionBuilder(Db)
                {
                    Action = a2.Action,
                    Case = @case
                }.Build().In(Db);

                var r = f.Subject.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);
                var a = r.ToArray();

                Assert.Equal(oa1.ActionId, a[0].Code);
                Assert.Equal(defaultAction.ActionName, a[0].Name);
                Assert.Equal(oa1.Cycle, a[0].Cycle);
                Assert.Equal(oa1.PoliceEvents == 1, a[0].IsOpen);
                Assert.Null(a.FirstOrDefault(_ => _.Name == a2.ActionName));
            }

            [Fact]
            public void ShouldNotThrowWhenProfileNotSetAgainstUser()
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var securityContext = Substitute.For<ISecurityContext>();
                var taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                securityContext.User.Returns(new User("actionUser", false, null));
                var actionEventNotes = Substitute.For<IActionEventNotes>();
                var subject = new Actions(Db, cultureResolver, securityContext, Fixture.Today, actionEventNotes, taskSecurityProvider);

                var a1 = new ActionBuilder { Id = "AB", Name = "DEFGHI", NumberOfCyclesAllowed = 1, ActionType = 2 }.Build().In(Db);
                var a2 = new ActionBuilder { Id = "CD", Name = "ABCDEFG", NumberOfCyclesAllowed = 2, ActionType = 1 }.Build().In(Db);
                var @case = new CaseBuilder().Build().In(Db);

                OpenActionBuilder.ForCaseAsValid(Db, @case, a1).Build().In(Db);
                OpenActionBuilder.ForCaseAsValid(Db, @case, a2).Build().In(Db);

                var exception = Record.Exception(() => subject.CaseViewActions(@case.Id, @case.Country.Id, @case.PropertyType.Code, @case.TypeId));
                Assert.Null(exception);
            }
        }

        public class ActionsFixture : IFixture<Actions>
        {
            public ActionsFixture(InMemoryDbContext db)
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();
                var securityContext = Substitute.For<ISecurityContext>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                securityContext.User.Returns(new User("actionUser", false, new Profile(3, "user")));
                var systemClock = Substitute.For<Func<DateTime>>();
                var actionEventNotes = Substitute.For<IActionEventNotes>();
                Subject = new Actions(db, cultureResolver, securityContext, systemClock, actionEventNotes, TaskSecurityProvider);
            }

            public Actions Subject { get; }
            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        }
    }
}