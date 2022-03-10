using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class BasisPicklistMaintenanceFacts
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesTheInstructionType()
            {
                var model = new ApplicationBasis("A", Fixture.String()).In(Db);

                var f = new BasisPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<ApplicationBasis>().Any());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _existing = new ApplicationBasis("A", "abc")
                {
                    Convention = 0m
                }.In(Db);
            }

            readonly ApplicationBasis _existing;

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            [InlineData("B")]
            public void PreventUnknownFromBeingSaved(string typeCode)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new BasisPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                          new Basis
                                                                                                          {
                                                                                                              Code = typeCode
                                                                                                          }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsBasis()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Basis
                {
                    Code = "T",
                    Value = "blah",
                    Convention = true
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<ApplicationBasis>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.Code);
                Assert.Equal(model.Value, justAdded.Name);
                Assert.True(justAdded.Convention == 1m);
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Basis
                {
                    Code = string.Empty,
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan2Characters()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Basis
                {
                    Code = "abc",
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 2), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescription()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Basis
                {
                    Code = _existing.Code,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescriptionToBeNoGreaterThan50Characters()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Basis
                {
                    Code = _existing.Code,
                    Value = "123456789012345678901234567890123456789012345678901234567890"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueCode()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Basis
                {
                    Code = _existing.Code,
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueDescription()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Basis
                {
                    Code = "B",
                    Value = _existing.Name
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesBasis()
            {
                var subject = new BasisPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Basis
                {
                    Code = _existing.Code,
                    Value = "blah"
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Code);
                Assert.Equal(model.Value, _existing.Name);
            }
        }

        public class BasisPicklistMaintenanceFixture : IFixture<BasisPicklistMaintenance>
        {
            public BasisPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                Subject = new BasisPicklistMaintenance(db);
            }

            public BasisPicklistMaintenance Subject { get; set; }
        }
    }
}