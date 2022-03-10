using System;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Configuration.ValidCombinations;
using Inprotech.Web.Picklists;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using ServiceStack;
using Xunit;
using Action = Inprotech.Web.Picklists.Action;

namespace Inprotech.Tests.Web.Picklists
{
    public class ActionsPicklistControllerFacts : FactBase
    {
        public class ControllerMethods : FactBase
        {
            [Fact]
            public void ReturnsActionsContainingSearchString()
            {
                var f = new ActionsPicklistControllerFixture();

                var a1 = new ActionData {Code = "AB", Name = "ABCDEFG"};
                var a2 = new ActionData {Code = "CD", Name = "DEFGHI"};
                var a3 = new ActionData {Code = "EF", Name = "GHIJKL"};

                f.Actions.Get(null, null, null).ReturnsForAnyArgs(new[] {a1, a2, a3});

                var r = f.Subject.Actions(null, "C");

                var a = r.Data.OfType<Action>().ToArray();

                Assert.Equal(a2.Code, a[0].Code);
                Assert.Equal(a1.Code, a[1].Code);
                Assert.Null(a.FirstOrDefault(_ => _.Code == a3.Code));
            }

            [Fact]
            public void ReturnsActionsSortedByDescription()
            {
                var f = new ActionsPicklistControllerFixture();

                var a1 = new ActionData {Code = "CD", Name = "ABCDEFG", Cycles = 1};
                var a2 = new ActionData {Code = "AB", Name = "DEFGHI", Cycles = 2};
                var a3 = new ActionData {Code = "EF", Name = "GHIJKL", Cycles = 3};

                f.Actions.Get(null, null, null).ReturnsForAnyArgs(new[] {a1, a2, a3});
                var r = f.Subject.Actions();

                var a = r.Data.OfType<Action>().ToArray();

                Assert.Equal(a1.Code, a[0].Code);
                Assert.Equal(a1.Name, a[0].Value);
                Assert.Equal(a1.Cycles, a[0].Cycles);
                Assert.Equal(a2.Code, a[1].Code);
                Assert.Equal(a2.Name, a[1].Value);
                Assert.Equal(a2.Cycles, a[1].Cycles);
                Assert.Equal(a3.Code, a[2].Code);
                Assert.Equal(a3.Name, a[2].Value);
                Assert.Equal(a3.Cycles, a[2].Cycles);
            }

            [Fact]
            public void ReturnsActionsWithExactMatchFlagOnCodeOrderedByExactMatch()
            {
                var f = new ActionsPicklistControllerFixture();

                var a1 = new ActionData {Code = "A", Name = "BDecoy1"};
                var a2 = new ActionData {Code = "!", Name = "Decoy2"};
                var a3 = new ActionData {Code = "B", Name = "Target"};

                f.Actions.Get(null, null, null).ReturnsForAnyArgs(new[] {a1, a2, a3});

                var r = f.Subject.Actions(null, "b");
                var a = r.Data.OfType<Action>().ToArray();

                Assert.Equal(2, a.Length);
                Assert.Equal(a3.Code, a[0].Code);
                Assert.Equal(a1.Code, a[1].Code);
            }

            [Fact]
            public void ReturnsActionsWithExactMatchFlagOnDescription()
            {
                var f = new ActionsPicklistControllerFixture();

                var a1 = new ActionData {Code = "1", Name = "A"};
                var a2 = new ActionData {Code = "2", Name = "AB"};

                f.Actions.Get(null, null, null).ReturnsForAnyArgs(new[] {a1, a2});

                var r = f.Subject.Actions(null, "A");
                var a = r.Data.OfType<Action>().ToArray();

                Assert.Equal(2, a.Length);

                Assert.Equal(a1.Code, a[0].Code);
                Assert.Equal(a2.Code, a[1].Code);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new ActionsPicklistControllerFixture();

                var a1 = new ActionData {Code = "AB", Name = "ABCDEFG"};
                var a2 = new ActionData {Code = "EF", Name = "GHIJKL"};
                var a3 = new ActionData {Code = "CD", Name = "DEFGHI"};

                f.Actions.Get(null, null, null).ReturnsForAnyArgs(new[] {a1, a2, a3});

                var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.Actions(qParams);
                var actions = r.Data.OfType<Action>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(actions);
                Assert.Equal(a3.Code, actions.Single().Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new ActionsPicklistControllerFixture().Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Actions").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("Action", picklistAttribute.Name);
            }
        }

        public class ActionModel : FactBase
        {
            [Fact]
            public void ReturnsCyclesAsOneByDefault()
            {
                var action = new Action();
                Assert.Equal((short?) 1, action.Cycles);

                var cycles = Fixture.Short();
                action.Cycles = cycles;
                Assert.Equal(cycles, action.Cycles);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsPicklistMaintenanceSave()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.ActionsPicklistMaintenance.Save(Arg.Any<Action>(), Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new Action();

                Assert.Equal(r, s.Update(Fixture.Integer(), JObject.FromObject(model)));
                f.ActionsPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Update);
            }

            [Fact]
            public void CallsValidActionsUpdate()
            {
                var f = new ActionsPicklistControllerFixture();

                var model = new ActionSaveDetails();
                var saveData = JObject.FromObject(model);
                saveData["validDescription"] = Fixture.String("11");
                var saveDetails = saveData.ToObject<ActionSaveDetails>();
                f.ValidActions.Update(saveDetails).Returns(new object());
                f.Subject.Update(Fixture.Integer(), saveData);

                f.ValidActions.ReceivedWithAnyArgs(1).Update(saveDetails);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new ActionsPicklistControllerFixture();

                var exception =
                    Record.Exception(() => f.Subject.Update(Fixture.Integer(), null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.ActionsPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new Action();

                Assert.Equal(r, s.AddOrDuplicate(JObject.FromObject(model)));
                f.ActionsPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Add);
            }

            [Fact]
            public void CallsValidActionsSave()
            {
                var f = new ActionsPicklistControllerFixture();

                var model = new ActionSaveDetails();
                var saveData = JObject.FromObject(model);
                saveData["validDescription"] = Fixture.String("11");
                var response = new {Result = "Success"};
                f.ValidActions.Save(Arg.Any<ActionSaveDetails>()).Returns(response);
                var result = f.Subject.AddOrDuplicate(saveData);

                f.ValidActions.ReceivedWithAnyArgs(1).Save(Arg.Any<ActionSaveDetails>());
                Assert.Equal(response.Result, result.Result);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new ActionsPicklistControllerFixture();

                var exception =
                    Record.Exception(() => f.Subject.AddOrDuplicate(null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.ActionsPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.ActionsPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsDeleteForActionIfValidcCombinationKeysNotProvided()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.ActionsPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1, string.Empty));
                f.ActionsPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsValidActionsDelete()
            {
                var f = new ActionsPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                var actionData = new ActionData {Id = 1, Code = "1"};
                f.ActionsPicklistMaintenance.Get(1).Returns(actionData);

                f.ValidActions.Delete(Arg.Any<ValidActionIdentifier[]>()).Returns(new DeleteResponseModel<ValidActionIdentifier>());

                var response = f.Subject.Delete(1, deleteData.ToString());

                f.ValidActions.ReceivedWithAnyArgs(1).Delete(Arg.Any<ValidActionIdentifier[]>());

                Assert.NotNull(response);
            }

            [Fact]
            public void ThrowsExceptionWhenCallsDeleteWithIncorrectParams()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;
                var actionData = new ActionData {Id = 1, Code = "1"};
                f.ActionsPicklistMaintenance.Get(1).Returns(actionData);

                dynamic data = new {validCombinationKeys = string.Empty, isDefaultJurisdiction = "false"};

                var exception =
                    Record.Exception(() => s.Delete(1, JsonConvert.SerializeObject(data)));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNull()
            {
                var f = new ActionsPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                var actionData = new ActionData {Id = 1, Code = "1"};
                f.ActionsPicklistMaintenance.Get(1).Returns(actionData);

                f.ValidActions.Delete(Arg.Any<ValidActionIdentifier[]>()).Returns(null as DeleteResponseModel<ValidActionIdentifier>);

                var exception = Record.Exception(() => f.Subject.Delete(1, deleteData.ToString()));
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void CallsActionsGet()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;

                var action = new ActionBuilder {Id = "AS", Name = "Overview"}.Build().In(Db);

                var actionData = new ActionData {Id = action.Id, Code = action.Name};
                f.ActionsPicklistMaintenance.Get(1).Returns(actionData);

                s.Action(action.Id);
                f.ActionsPicklistMaintenance.Received(1).Get(1);
            }

            [Fact]
            public void CallsGetForValidAction()
            {
                var f = new ActionsPicklistControllerFixture();
                var s = f.Subject;
                var keys = new ValidCombinationKeys {Jurisdiction = "AU", PropertyType = "P", CaseType = "P"};
                var actionData = new ActionData {Id = 1, Code = "AS"};
                f.ActionsPicklistMaintenance.Get(1).Returns(actionData);

                f.ValidActions.GetValidAction(Arg.Any<ValidActionIdentifier>()).Returns(null as ActionSaveDetails);

                var exception =
                    Record.Exception(() => s.Action(1, JsonConvert.SerializeObject(keys), false));

                Assert.IsType<HttpResponseException>(exception);
            }
        }
    }

    public class ActionsPicklistControllerFixture : IFixture<ActionsPicklistController>
    {
        public ActionsPicklistControllerFixture()
        {
            Actions = Substitute.For<IActions>();
            ActionsPicklistMaintenance = Substitute.For<IActionsPicklistMaintenance>();
            ValidActions = Substitute.For<IValidActions>();

            Subject = new ActionsPicklistController(Actions, ActionsPicklistMaintenance, ValidActions);
        }

        public IActionsPicklistMaintenance ActionsPicklistMaintenance { get; set; }

        public IActions Actions { get; set; }

        public IValidActions ValidActions { get; set; }

        public ActionsPicklistController Subject { get; }
    }
}