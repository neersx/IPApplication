using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using Xunit;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Picklists
{
    public class ChecklistPickListMaintenanceFacts
    {
        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anyChecklist = new ChecklistBuilder {Id = 1, Description = "Test1", ChecklistTypeFlag = 1}.Build();

                _existing = new ChecklistBuilder {Id = 2, Description = "Test2", ChecklistTypeFlag = 2}.Build().In(Db);
            }

            readonly EntityModel.CheckList _anyChecklist;
            readonly EntityModel.CheckList _existing;

            [Fact]
            public void AddsChecklist()
            {
                const short lastInternalCode = 3;
                var fixture = new ChecklistPicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new ChecklistMatcher
                {
                    Value = _anyChecklist.Description,
                    ChecklistTypeFlag = _anyChecklist.ChecklistTypeFlag
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.CheckList>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(lastInternalCode, justAdded.Id);
                Assert.Equal(model.Value, justAdded.Description);
                Assert.NotEqual(model.ChecklistTypeFlag, justAdded.ChecklistTypeFlag);
            }

            [Fact]
            public void RequiresUniqueValue()
            {
                var subject = new ChecklistPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new ChecklistMatcher
                {
                    Value = _existing.Description,
                    Code = _anyChecklist.Id
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValue()
            {
                var subject = new ChecklistPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new ChecklistMatcher
                {
                    Code = _existing.Id,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValueToBeNoGreaterThan50Characters()
            {
                var subject = new ChecklistPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new ChecklistMatcher
                {
                    Code = _existing.Id,
                    Value = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesChecklist()
            {
                var subject = new ChecklistPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new ChecklistMatcher
                {
                    Code = _existing.Id,
                    Value = "blah",
                    ChecklistType = ChecklistType.Examination,
                    ChecklistTypeFlag = Convert.ToDecimal(ChecklistType.Examination)
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Id);
                Assert.Equal(model.ChecklistTypeFlag, _existing.ChecklistTypeFlag);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesChecklist()
            {
                var model = new ChecklistBuilder().Build().In(Db);

                var f = new ChecklistPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.CheckList>().Any());
            }
        }

        public class ChecklistPicklistMaintenanceFixture : IFixture<ChecklistPickListMaintenance>
        {
            readonly InMemoryDbContext _db;

            public ChecklistPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new ChecklistPickListMaintenance(_db);
            }

            public ChecklistPickListMaintenance Subject { get; set; }

            public ChecklistPicklistMaintenanceFixture WithAction()
            {
                new ChecklistBuilder().Build().In(_db);

                return this;
            }
        }
    }
}