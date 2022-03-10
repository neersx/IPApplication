using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using Xunit;
using Action = Inprotech.Web.Picklists.Action;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Picklists
{
    public class ActionPicklistMaintenanceFacts
    {
        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anyAction = new ActionBuilder {Id = "W", Name = "adwi", NumberOfCyclesAllowed = 11}.Build();

                _existing = new ActionBuilder {Id = "B", Name = "xyz", NumberOfCyclesAllowed = 1}.Build().In(Db);
            }

            readonly EntityModel.Action _anyAction;
            readonly EntityModel.Action _existing;

            [Theory]
            [InlineData(null)]
            [InlineData("C")]
            public void PreventUnknownFromBeingSaved(string id)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new ActionsPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                            new Action
                                                                                                            {
                                                                                                                Code = id,
                                                                                                                Value = "abc",
                                                                                                                Cycles = 1
                                                                                                            }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsAction()
            {
                var fixture = new ActionsPicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new Action
                {
                    Value = _anyAction.Name,
                    Code = _anyAction.Code,
                    Cycles = _anyAction.NumberOfCyclesAllowed,
                    ActionTypeFlag = _anyAction.ActionType
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.Action>().Last();

                Assert.Equal("success", r.Result);
                //Assert.NotEqual(justAdded, _existing);
                //Assert.Equal(model.Value, justAdded.Name);
                //Assert.Equal(model.Cycles,justAdded.NumberOfCyclesAllowed);
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new ActionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Action
                {
                    Code = string.Empty,
                    Value = _existing.Name,
                    Cycles = _existing.NumberOfCyclesAllowed,
                    ActionTypeFlag = _existing.ActionType
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan2Characters()
            {
                var subject = new ActionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Action
                {
                    Code = "123",
                    Value = "abc",
                    Cycles = 1,
                    ActionTypeFlag = 0
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 2), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueValue()
            {
                var subject = new ActionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Action
                {
                    Value = _existing.Name,
                    Code = _anyAction.Code
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValue()
            {
                var subject = new ActionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Action
                {
                    Code = _existing.Code,
                    Value = string.Empty,
                    Key = _existing.Id
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValueToBeNoGreaterThan50Characters()
            {
                var subject = new ActionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Action
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesAction()
            {
                var subject = new ActionsPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Action
                {
                    Code = _existing.Code,
                    Value = "blah",
                    Cycles = 10,
                    Key = _existing.Id
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Code);
                Assert.Equal(model.Value, _existing.Name);
                Assert.Equal(model.Cycles, _existing.NumberOfCyclesAllowed);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesAction()
            {
                var model = new ActionBuilder().Build().In(Db);

                var f = new ActionsPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.Action>().Any());
            }
        }

        public class ActionsPicklistMaintenanceFixture : IFixture<ActionsPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public ActionsPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;

                Subject = new ActionsPicklistMaintenance(_db);
            }

            public ActionsPicklistMaintenance Subject { get; set; }

            public ActionsPicklistMaintenanceFixture WithAction()
            {
                new ActionBuilder().Build().In(_db);

                return this;
            }
        }
    }
}