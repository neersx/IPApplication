using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using Xunit;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseCategoriesPicklistMaintenanceFacts
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesTheCaseCategories()
            {
                var model = new EntityModel.CaseCategory("A", Fixture.String(), Fixture.String()).In(Db);

                var f = new CaseCategoriesPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.CaseCategory>().Any());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _existing = new EntityModel.CaseCategory("A", "1", "abc").In(Db);
            }

            readonly EntityModel.CaseCategory _existing;

            [Fact]
            public void AddsCaseCategories()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new CaseCategory
                {
                    Code = "T",
                    Value = "blah",
                    CaseTypeId = "A"
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.CaseCategory>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.CaseCategoryId);
                Assert.Equal(model.Value, justAdded.Name);
            }

            [Fact]
            public void PreventUnknownFromBeingSaved()
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new CaseCategoriesPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                                   new CaseCategory(2, "abc", "c"), Operation.Update);
                                                 });
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseCategory
                {
                    Code = string.Empty,
                    Value = "abc",
                    CaseTypeId = "A"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan2Characters()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseCategory
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
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseCategory
                {
                    Key = _existing.Id,
                    Code = _existing.CaseCategoryId,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescriptionToBeNoGreaterThan50Characters()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseCategory
                {
                    Key = _existing.Id,
                    Code = _existing.CaseCategoryId,
                    Value = "123456789012345678901234567890123456789012345678901234567890"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueCode()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseCategory
                {
                    Code = _existing.CaseCategoryId,
                    Value = "abc",
                    CaseTypeId = "A"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueDescription()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new CaseCategory
                {
                    Code = "B",
                    Value = _existing.Name,
                    CaseTypeId = "A"
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesCaseCategories()
            {
                var subject = new CaseCategoriesPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new CaseCategory
                {
                    Key = _existing.Id,
                    Code = _existing.CaseCategoryId,
                    Value = "blah",
                    CaseTypeId = "A"
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.CaseCategoryId);
                Assert.Equal(model.Value, _existing.Name);
            }
        }

        public class CaseCategoriesPicklistMaintenanceFixture : IFixture<CaseCategoriesPicklistMaintenance>
        {
            public CaseCategoriesPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                Subject = new CaseCategoriesPicklistMaintenance(db);
            }

            public CaseCategoriesPicklistMaintenance Subject { get; set; }
        }
    }
}