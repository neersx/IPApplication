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
using InprotechKaizen.Model.Components.Cases;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using ServiceStack;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class PropertyTypesPicklistControllerFacts : FactBase
    {
        public class PropertyTypesMethod : FactBase
        {
            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var p1 = new PropertyTypeListItem {PropertyTypeKey = "A", PropertyTypeDescription = "Decoy1", AllowSubClass = 1};
                var p2 = new PropertyTypeListItem {PropertyTypeKey = "C", PropertyTypeDescription = "Decoy2", AllowSubClass = 1};
                var p3 = new PropertyTypeListItem {PropertyTypeKey = "B", PropertyTypeDescription = "Target", AllowSubClass = 1};
                f.PropertyTypes.GetPropertyTypes(null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 1, Take = 1};
                f.PropertyTypes.Get(new[] {string.Empty}).ReturnsForAnyArgs(new[] {p1, p2, p3});
                var r = f.Subject.PropertyTypes(qParams);
                var propertyTypes = r.Data.OfType<PropertyType>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(propertyTypes);
                Assert.Equal(p3.PropertyTypeKey, propertyTypes.Single().Code);
            }

            [Fact]
            public void ReturnsPagedResultswithConvention()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var p1 = new PropertyTypeListItem {PropertyTypeKey = "P1", PropertyTypeDescription = "P1 Desc", AllowSubClass = 1};
                var p2 = new PropertyTypeListItem {PropertyTypeKey = "P1", PropertyTypeDescription = "P1 Desc", AllowSubClass = 1};
                var p3 = new PropertyTypeListItem {PropertyTypeKey = "P1", PropertyTypeDescription = "P1 Desc", AllowSubClass = 1};
                f.PropertyTypes.Get(new[] {string.Empty}).ReturnsForAnyArgs(new[] {p1, p2, p3});

                var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.PropertyTypes(qParams);
                var property = r.Data.OfType<PropertyType>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(property);
                Assert.Equal(p2.PropertyTypeKey, property.Single().Code);
                Assert.Equal(p2.AllowSubClass, property.Single().AllowSubClass);
            }

            [Fact]
            public void ReturnsPropertyTypesContainingSearchStringOrderedByExactMatch()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var p1 = new PropertyTypeListItem {PropertyTypeKey = "A", PropertyTypeDescription = "ABCDEFG", AllowSubClass = 1};
                var p2 = new PropertyTypeListItem {PropertyTypeKey = "B", PropertyTypeDescription = "DEFGHI", AllowSubClass = 1};
                var p3 = new PropertyTypeListItem {PropertyTypeKey = "C", PropertyTypeDescription = "GHIJKL", AllowSubClass = 1};
                f.PropertyTypes.GetPropertyTypes(null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.PropertyTypes.Get(new[] {string.Empty}).ReturnsForAnyArgs(new[] {p1, p2, p3});
                var r = f.Subject.PropertyTypes(null, "B");
                var p = r.Data.OfType<PropertyType>().ToArray();

                Assert.Equal(p2.PropertyTypeKey, p[0].Code);
                Assert.Equal(p1.PropertyTypeKey, p[1].Code);
                Assert.Null(p.FirstOrDefault(_ => _.Code == p3.PropertyTypeKey));
            }

            [Fact]
            public void ReturnsPropertyTypesSortedByDescription()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var p1 = new PropertyTypeListItem {PropertyTypeKey = "A", PropertyTypeDescription = "DEFGHI", AllowSubClass = 1};
                var p2 = new PropertyTypeListItem {PropertyTypeKey = "B", PropertyTypeDescription = "ABCDEFG", AllowSubClass = 1};
                var p3 = new PropertyTypeListItem {PropertyTypeKey = "C", PropertyTypeDescription = "GHIJKL", AllowSubClass = 1};
                f.PropertyTypes.GetPropertyTypes(null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.PropertyTypes.Get((string[]) null).ReturnsForAnyArgs(new[] {p1, p2, p3});
                var r = f.Subject.PropertyTypes();
                var p = r.Data.OfType<PropertyType>().ToArray();

                Assert.Equal(p2.PropertyTypeKey, p[0].Code);
                Assert.Equal(p2.PropertyTypeDescription, p[0].Value);
                Assert.Equal(p1.PropertyTypeKey, p[1].Code);
                Assert.Equal(p1.PropertyTypeDescription, p[1].Value);
                Assert.Equal(p3.PropertyTypeKey, p[2].Code);
                Assert.Equal(p3.PropertyTypeDescription, p[2].Value);
            }

            [Fact]
            public void ReturnsPropertyTypesWithExactMatchFlagOnCodeOrderedByExactMatch()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var p1 = new PropertyTypeListItem {PropertyTypeKey = "A", PropertyTypeDescription = "~Decoy1", AllowSubClass = 1};
                var p2 = new PropertyTypeListItem {PropertyTypeKey = "!", PropertyTypeDescription = "Decoy2", AllowSubClass = 1};
                var p3 = new PropertyTypeListItem {PropertyTypeKey = "~", PropertyTypeDescription = "Target", AllowSubClass = 1};
                f.PropertyTypes.GetPropertyTypes(null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.PropertyTypes.Get(new[] {string.Empty}).ReturnsForAnyArgs(new[] {p1, p2, p3});
                var r = f.Subject.PropertyTypes(null, "~");
                var p = r.Data.OfType<PropertyType>().ToArray();

                Assert.Equal(2, p.Length);
                Assert.Equal(p3.PropertyTypeKey, p[0].Code);
                Assert.Equal(p1.PropertyTypeKey, p[1].Code);
            }

            [Fact]
            public void ReturnsPropertyTypesWithExactMatchFlagOnDescription()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var p2 = new PropertyTypeListItem {PropertyTypeKey = "1", PropertyTypeDescription = "A", AllowSubClass = 1};
                var p1 = new PropertyTypeListItem {PropertyTypeKey = "2", PropertyTypeDescription = "AB", AllowSubClass = 1};

                f.PropertyTypes.GetPropertyTypes(null).ReturnsForAnyArgs(new[] {p2, p1});

                f.PropertyTypes.Get(new[] {string.Empty}).ReturnsForAnyArgs(new[] {p1, p2});
                var r = f.Subject.PropertyTypes(null, "A");
                var p = r.Data.OfType<PropertyType>().ToArray();

                Assert.Equal(2, p.Length);
                Assert.Equal(p2.PropertyTypeKey, p[0].Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new PropertyTypesPicklistControllerFixture().Subject.GetType();
                var picklistAttribute =
                    // ReSharper disable once AssignNullToNotNullAttribute
                    subjectType.GetMethod("PropertyTypes").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("PropertyType", picklistAttribute.Name);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsPicklistMaintenanceSave()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.PropertyTypesPicklistMaintenance.Save(Arg.Any<PropertyType>(), Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new PropertyType();

                Assert.Equal(r, s.Update(Fixture.Integer(), JObject.FromObject(model)));
                f.PropertyTypesPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Update);
            }

            [Fact]
            public void CallsValidPropertyTypesUpdate()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var model = new PropertyTypeSaveDetails();
                var saveData = JObject.FromObject(model);
                saveData["validDescription"] = Fixture.String("11");
                var saveDetails = saveData.ToObject<PropertyTypeSaveDetails>();
                f.ValidPropertyTypes.Update(saveDetails).Returns(new object());
                f.Subject.Update(Fixture.Integer(), saveData);

                f.ValidPropertyTypes.ReceivedWithAnyArgs(1).Update(saveDetails);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new PropertyTypesPicklistControllerFixture();

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
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.PropertyTypesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new PropertyType();

                Assert.Equal(r, s.AddOrDuplicate(JObject.FromObject(model)));
                f.PropertyTypesPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Add);
            }

            [Fact]
            public void CallsValidPropertyTypesSave()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var model = new PropertyTypeSaveDetails();
                var saveData = JObject.FromObject(model);
                saveData["validDescription"] = Fixture.String("11");
                var response = new {Result = "Success"};
                f.ValidPropertyTypes.Save(Arg.Any<PropertyTypeSaveDetails>()).Returns(response);
                var result = f.Subject.AddOrDuplicate(saveData);

                f.ValidPropertyTypes.ReceivedWithAnyArgs(1).Save(Arg.Any<PropertyTypeSaveDetails>());
                Assert.Equal(response.Result, result.Result);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new PropertyTypesPicklistControllerFixture();

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
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.PropertyTypesPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.PropertyTypesPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsDeleteForActionIfValidcCombinationKeysNotProvided()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.PropertyTypesPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1, string.Empty));
                f.PropertyTypesPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsValidPropertyTypesDelete()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                f.PropertyTypes.Get(1)
                 .ReturnsForAnyArgs(new PropertyTypeListItem {PropertyTypeKey = "P"});

                f.ValidPropertyTypes.Delete(Arg.Any<ValidPropertyIdentifier[]>()).Returns(new DeleteResponseModel<ValidPropertyIdentifier>());

                var response = f.Subject.Delete(1, deleteData.ToString());

                f.ValidPropertyTypes.ReceivedWithAnyArgs(1).Delete(Arg.Any<ValidPropertyIdentifier[]>());

                Assert.NotNull(response);
            }

            [Fact]
            public void ThrowsExceptionWhenCallsDeleteWithIncorrectParams()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;
                f.PropertyTypes.Get(1)
                 .ReturnsForAnyArgs(new PropertyTypeListItem {PropertyTypeKey = "1"});

                dynamic data = new {validCombinationKeys = string.Empty, isDefaultJurisdiction = "false"};

                var exception =
                    Record.Exception(() => s.Delete(1, JsonConvert.SerializeObject(data)));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNull()
            {
                var f = new PropertyTypesPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                f.PropertyTypes.Get(1)
                 .ReturnsForAnyArgs(new PropertyTypeListItem {PropertyTypeKey = "P"});

                f.ValidPropertyTypes.Delete(Arg.Any<ValidPropertyIdentifier[]>()).Returns(null as DeleteResponseModel<ValidPropertyIdentifier>);

                var exception = Record.Exception(() => f.Subject.Delete(1, deleteData.ToString()));
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void CallsGetForPropertyTypeIfValidcCombinationKeysNotProvided()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;

                f.PropertyTypes.Get(1)
                 .ReturnsForAnyArgs(new PropertyTypeListItem());

                s.PropertyType(1, string.Empty, false);
                f.PropertyTypes.Received(2).Get(1);
            }

            [Fact]
            public void CallsGetForValidPropertyType()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                f.PropertyTypes.Get(1)
                 .ReturnsForAnyArgs(new PropertyTypeListItem {PropertyTypeKey = "P"});

                var exception =
                    Record.Exception(() => s.PropertyType(1, JsonConvert.SerializeObject(keys), false));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void CallsPropertyTypesGet()
            {
                var f = new PropertyTypesPicklistControllerFixture();
                var s = f.Subject;

                var propertyType = new PropertyTypeBuilder {Id = "P", Name = "Patents"}.Build().In(Db);

                f.PropertyTypes.Get(propertyType.Id)
                 .ReturnsForAnyArgs(new PropertyTypeListItem {PropertyTypeKey = propertyType.Code, PropertyTypeDescription = propertyType.Name});

                var response = s.PropertyType(propertyType.Id);
                f.PropertyTypes.Received(1).Get(propertyType.Id);
                Assert.Equal(propertyType.Code, response.Code);
                Assert.Equal(propertyType.Name, response.Value);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new PropertyTypesPicklistControllerFixture().Subject.GetType();
                var picklistAttribute =
                    // ReSharper disable once AssignNullToNotNullAttribute
                    subjectType.GetMethod("PropertyTypes").GetCustomAttribute<PicklistPayloadAttribute>();
                Assert.NotNull(picklistAttribute);
                Assert.Equal("PropertyType", picklistAttribute.Name);
            }
        }
    }

    public class PropertyTypesPicklistControllerFixture : IFixture<PropertyTypesPicklistController>
    {
        public PropertyTypesPicklistControllerFixture()
        {
            PropertyTypes = Substitute.For<IPropertyTypes>();
            PropertyTypesPicklistMaintenance = Substitute.For<IPropertyTypesPicklistMaintenance>();
            ValidPropertyTypes = Substitute.For<IValidPropertyTypes>();

            Subject = new PropertyTypesPicklistController(PropertyTypes, PropertyTypesPicklistMaintenance, ValidPropertyTypes);
        }

        public IPropertyTypes PropertyTypes { get; set; }
        public IPropertyTypesPicklistMaintenance PropertyTypesPicklistMaintenance { get; set; }

        public IValidPropertyTypes ValidPropertyTypes { get; set; }

        public PropertyTypesPicklistController Subject { get; }
    }
}