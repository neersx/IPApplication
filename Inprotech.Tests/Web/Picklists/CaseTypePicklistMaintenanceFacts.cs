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
    public class CaseTypePicklistMaintenanceFacts
    {
        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anyCaseType = new CaseTypeBuilder {Id = "Q", Name = "abc"}.Build();

                _existing = new CaseTypeBuilder {Id = "B", Name = "xyz"}.Build().In(Db);
            }

            readonly EntityModel.CaseType _anyCaseType;
            readonly EntityModel.CaseType _existing;

            [Theory]
            [InlineData(null)]
            [InlineData("C")]
            public void PreventUnknownFromBeingSaved(string id)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new CaseTypePicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                             new CaseType
                                                                                                             {
                                                                                                                 Code = id,
                                                                                                                 Value = "abc"
                                                                                                             }, Operation.Update);
                                                 });
            }

            [Fact]
            public void ActualCasetypeCannotBeChangedIfCaseIsInUse()
            {
                var casetype1 = new CaseTypeBuilder {Id = "A", Name = "Properties"}.Build().In(Db);
                var casetype2 = new CaseTypeBuilder {ActualCaseTypeId = casetype1.Code, Id = "B", Name = "BBB"}.Build().In(Db);
                var casetype3 = new CaseTypeBuilder {Id = "C", Name = "CCC"}.Build().In(Db);

                new CaseBuilder {CaseType = new EntityModel.CaseType(casetype2.Code, casetype2.Name)}.Build().In(Db);
                var fixture = new CaseTypePicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new CaseType
                {
                    Value = casetype2.Name,
                    Code = casetype2.Code,
                    ActualCaseType = new CaseType(casetype3.Code, casetype3.Name)
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("pkActualCaseType", r.Errors[0].Field);
                Assert.Equal("entity.cannotchangeactualcasetype", r.Errors[0].Message);
            }

            [Fact]
            public void ActualCaseTypeShouldBeUnique()
            {
                var casetype1 = new CaseTypeBuilder {Id = "A", Name = "Properties"}.Build().In(Db);
                new CaseTypeBuilder {ActualCaseTypeId = "A"}.Build().In(Db);

                var fixture = new CaseTypePicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new CaseType
                {
                    Value = _anyCaseType.Name,
                    Code = _anyCaseType.Code,
                    ActualCaseType = new CaseType(casetype1.Code, casetype1.Name)
                };

                var r = subject.Save(model, Operation.Add);

                Assert.Equal("pkActualCaseType", r.Errors[0].Field);
                Assert.Equal("entity.actualcasetypenotUnique", r.Errors[0].Message);
            }

            [Fact]
            public void AddsCaseType()
            {
                var fixture = new CaseTypePicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new CaseType
                {
                    Value = _anyCaseType.Name,
                    Code = _anyCaseType.Code
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.CaseType>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.Code);
                Assert.Equal(model.Value, justAdded.Name);
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new CaseTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseType
                {
                    Code = string.Empty,
                    Value = _anyCaseType.Name
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresKeyToBeNoGreaterThan1Characters()
            {
                var subject = new CaseTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseType
                {
                    Code = "123",
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 1), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueValue()
            {
                var subject = new CaseTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseType
                {
                    Value = _existing.Name,
                    Code = _anyCaseType.Code
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValue()
            {
                var subject = new CaseTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseType
                {
                    Code = _existing.Code,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresValueToBeNoGreaterThan50Characters()
            {
                var subject = new CaseTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseType
                {
                    Code = _existing.Code,
                    Value = "123456789012345678901234567890123456789012345678901234567890123"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesCaseType()
            {
                var subject = new CaseTypePicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new CaseType
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

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CaseTypeAIsProtectedCannotBeDeleted()
            {
                var model = new CaseTypeBuilder {Id = "A"}.Build().In(Db);

                var f = new CaseTypePicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.NotNull(r);
                Assert.NotNull(r.Errors);
                Assert.Equal("entity.protectedcasetype", r.Errors[0].Message);
            }

            [Fact]
            public void DeletesCaseType()
            {
                var model = new CaseTypeBuilder().Build().In(Db);

                var f = new CaseTypePicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.CaseType>().Any());
            }

            [Fact]
            public void InUseCaseTypeCannotbeDeleted()
            {
                var model = new CaseTypeBuilder().Build().In(Db);
                new ValidActionBuilder {CaseType = model}.Build().In(Db);

                var f = new CaseTypePicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.NotNull(r);
                Assert.NotNull(r.Errors);
                Assert.Equal("entity.cannotdelete", r.Errors[0].Message);
            }
        }

        public class CaseTypePicklistMaintenanceFixture : IFixture<CaseTypesPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public CaseTypePicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;

                Subject = new CaseTypesPicklistMaintenance(db);
            }

            public CaseTypesPicklistMaintenance Subject { get; set; }

            public CaseTypePicklistMaintenanceFixture WithCaseType()
            {
                new CaseTypeBuilder().Build().In(_db);

                return this;
            }
        }
    }
}