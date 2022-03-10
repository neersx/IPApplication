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
    public class PropertyTypePicklistMaintenanceFacts
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesPropertyType()
            {
                var model = new EntityModel.PropertyType("M", Fixture.String()).In(Db);

                var r = new PropertyTypesPicklistMaintenance(Db).Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.PropertyType>().Any());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _existing = new EntityModel.PropertyType("M", "marketing event")
                {
                    AllowSubClass = 1
                }.In(Db);
            }

            readonly EntityModel.PropertyType _existing;

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            [InlineData("B")]
            public void PreventUnknownFromBeingSaved(string propertyTypeCode)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new PropertyTypesPicklistMaintenance(Db).Save(
                                                                                                   new PropertyType
                                                                                                   {
                                                                                                       Code = propertyTypeCode
                                                                                                   }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsBasis()
            {
                var model = new PropertyType
                {
                    Code = "T",
                    Value = "blah",
                    AllowSubClass = 1
                };

                var r = new PropertyTypesPicklistMaintenance(Db).Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.PropertyType>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.Code);
                Assert.Equal(model.Value, justAdded.Name);
                Assert.Equal(1, justAdded.AllowSubClass);
            }

            [Fact]
            public void RequiresCode()
            {
                var r = new PropertyTypesPicklistMaintenance(Db).Save(new PropertyType
                {
                    Code = string.Empty,
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan1Character()
            {
                var r = new PropertyTypesPicklistMaintenance(Db).Save(new PropertyType
                {
                    Code = "ab",
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 1), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescription()
            {
                var r = new PropertyTypesPicklistMaintenance(Db).Save(new PropertyType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescriptionToBeNoGreaterThan50Characters()
            {
                var r = new PropertyTypesPicklistMaintenance(Db).Save(new PropertyType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "123456789012345678901234567890123456789012345678901234567890"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueCode()
            {
                var r = new PropertyTypesPicklistMaintenance(Db).Save(new PropertyType
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
                var r = new PropertyTypesPicklistMaintenance(Db).Save(new PropertyType
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
                var model = new PropertyType
                {
                    Key = _existing.Id,
                    Code = _existing.Code,
                    Value = "blah",
                    AllowSubClass = 0
                };

                var r = new PropertyTypesPicklistMaintenance(Db).Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Code);
                Assert.Equal(model.Value, _existing.Name);
                Assert.Equal(0m, _existing.AllowSubClass);
            }
        }
    }
}