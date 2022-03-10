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
    public class SubTypePicklistMaintenanceFacts
    {
        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anySubType = new SubTypeBuilder {Id = "A", Name = "abc"}.Build();

                _existing = new SubTypeBuilder {Id = "B", Name = "xyz"}.Build().In(Db);
            }

            readonly EntityModel.SubType _anySubType;
            readonly EntityModel.SubType _existing;

            [Theory]
            [InlineData(null)]
            [InlineData("C")]
            public void PreventUnknownFromBeingSaved(string id)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new SubTypePicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                            new SubType
                                                                                                            {
                                                                                                                Code = id,
                                                                                                                Value = "abc"
                                                                                                            }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsSubtype()
            {
                var fixture = new SubTypePicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new SubType
                {
                    Value = _anySubType.Name,
                    Code = _anySubType.Code
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.SubType>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.Code);
                Assert.Equal(model.Value, justAdded.Name);
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new SubTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new SubType
                {
                    Code = string.Empty,
                    Value = _existing.Name
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan2Characters()
            {
                var subject = new SubTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new SubType
                {
                    Code = "123",
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 2), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueValue()
            {
                var subject = new SubTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new SubType
                {
                    Value = _existing.Name,
                    Code = _anySubType.Code
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValue()
            {
                var subject = new SubTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new SubType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValueToBeNoGreaterThan50Characters()
            {
                var subject = new SubTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new SubType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "123456789012345678901234567890123456789012345678901234567890123"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesSubtype()
            {
                var subject = new SubTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new SubType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "blah"
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Code);
                Assert.Equal(model.Value, _existing.Name);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesSubType()
            {
                var model = new SubTypeBuilder().Build().In(Db);

                var f = new SubTypePicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.SubType>().Any());
            }
        }

        public class SubTypePicklistMaintenanceFixture : IFixture<SubTypesPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public SubTypePicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new SubTypesPicklistMaintenance(_db);
            }

            public SubTypesPicklistMaintenance Subject { get; set; }

            public SubTypePicklistMaintenanceFixture WithSubType()
            {
                new SubTypeBuilder().Build().In(_db);

                return this;
            }
        }
    }
}