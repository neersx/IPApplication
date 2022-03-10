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

namespace Inprotech.Tests.Web.Picklists
{
    public class SubTypesPicklistControllerFacts : FactBase
    {
        public class ControllerMethods : FactBase
        {
            public class UpdateMethod : FactBase
            {
                [Fact]
                public void CallsPicklistMaintenanceSave()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    var model = new SubType();

                    f.SubTypesPicklistMaintenance.Save(Arg.Any<SubType>(), Arg.Any<Operation>())
                     .ReturnsForAnyArgs(r);

                    var subTypeSaveData = JObject.FromObject(model);
                    Assert.Equal(r, s.Update(1, subTypeSaveData));
                    f.SubTypesPicklistMaintenance.ReceivedWithAnyArgs(1).Save(subTypeSaveData.ToObject<SubType>(), Operation.Update);
                }

                [Fact]
                public void CallsValidSubTypeControllerSave()
                {
                    var f = new SubTypesPicklistControllerFixture();

                    var model = new SubTypeSaveDetails();
                    var subTypeSaveData = JObject.FromObject(model);
                    subTypeSaveData["validDescription"] = Fixture.String("11");
                    var saveDetails = subTypeSaveData.ToObject<SubTypeSaveDetails>();
                    f.ValidSubTypes.Update(saveDetails).Returns(new object());
                    f.Subject.Update(Fixture.Integer(), subTypeSaveData);

                    f.ValidSubTypes.ReceivedWithAnyArgs(1).Update(saveDetails);
                }

                [Fact]
                public void ReturnExceptionWhenNullIsPassed()
                {
                    var f = new SubTypesPicklistControllerFixture();

                    var exception =
                        Record.Exception(() => f.Subject.Update(1, null));

                    Assert.IsType<ArgumentNullException>(exception);
                }
            }

            public class AddOrDuplicateMethod : FactBase
            {
                [Fact]
                public void CallsSave()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    f.SubTypesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                     .ReturnsForAnyArgs(r);

                    var model = new SubType();
                    Assert.Equal(r, s.AddOrDuplicate(JObject.FromObject(model)));
                    f.SubTypesPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Add);
                }

                [Fact]
                public void CallsValidSubTypeControllerSave()
                {
                    var f = new SubTypesPicklistControllerFixture();

                    var model = new SubTypeSaveDetails();
                    var subTypeSaveData = JObject.FromObject(model);
                    subTypeSaveData["validDescription"] = Fixture.String("11");
                    var response = new {Result = "Success"};
                    f.ValidSubTypes.Save(Arg.Any<SubTypeSaveDetails>()).Returns(response);
                    var result = f.Subject.AddOrDuplicate(subTypeSaveData);

                    f.ValidSubTypes.ReceivedWithAnyArgs(1).Save(Arg.Any<SubTypeSaveDetails>());
                    Assert.Equal(response.Result, result.Result);
                }

                [Fact]
                public void ReturnExceptionWhenNullIsPassed()
                {
                    var f = new SubTypesPicklistControllerFixture();

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
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    f.SubTypesPicklistMaintenance.Delete(1)
                     .ReturnsForAnyArgs(r);

                    Assert.Equal(r, s.Delete(1));
                    f.SubTypesPicklistMaintenance.Received(1).Delete(1);
                }

                [Fact]
                public void CallsDeleteForSubTypeIfValidcCombinationKeysNotProvided()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    f.SubTypesPicklistMaintenance.Delete(1)
                     .ReturnsForAnyArgs(r);

                    Assert.Equal(r, s.Delete(1, string.Empty));
                    f.SubTypesPicklistMaintenance.Received(1).Delete(1);
                }

                [Fact]
                public void CallsValidPropertyTypesDelete()
                {
                    var f = new SubTypesPicklistControllerFixture();

                    var deleteData = new JObject();
                    var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                    deleteData["validCombinationKeys"] = keys.ToJson();
                    deleteData["isDefaultJurisdiction"] = "false";
                    f.SubTypesPicklistMaintenance.Get(1)
                     .ReturnsForAnyArgs(new SubType {Key = 1, Code = "P", Value = "XXX"});

                    f.ValidSubTypes.Delete(Arg.Any<ValidSubTypeIdentifier[]>()).Returns(new DeleteResponseModel<ValidSubTypeIdentifier>());

                    var response = f.Subject.Delete(1, deleteData.ToString());

                    f.ValidSubTypes.ReceivedWithAnyArgs(1).Delete(Arg.Any<ValidSubTypeIdentifier[]>());

                    Assert.NotNull(response);
                }

                [Fact]
                public void ThrowsExceptionWhenCallsDeleteWithIncorrectParams()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;

                    f.SubTypesPicklistMaintenance.Get(1).Returns(new SubType());

                    dynamic data = new {validCombinationKeys = string.Empty, isDefaultJurisdiction = "false"};

                    var exception =
                        Record.Exception(() => s.Delete(1, JsonConvert.SerializeObject(data)));

                    Assert.IsType<HttpResponseException>(exception);
                }

                [Fact]
                public void ThrowsExceptionWhenResponseIsNull()
                {
                    var f = new SubTypesPicklistControllerFixture();

                    var deleteData = new JObject();
                    var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                    deleteData["validCombinationKeys"] = keys.ToJson();
                    deleteData["isDefaultJurisdiction"] = "false";
                    f.SubTypesPicklistMaintenance.Get(1)
                     .ReturnsForAnyArgs(new SubType {Key = 1, Code = "P", Value = "XXX"});

                    f.ValidSubTypes.Delete(Arg.Any<ValidSubTypeIdentifier[]>()).Returns(null as DeleteResponseModel<ValidSubTypeIdentifier>);

                    var exception = Record.Exception(() => f.Subject.Delete(1, deleteData.ToString()));
                    Assert.IsType<HttpResponseException>(exception);
                }
            }

            public class GetMethod : FactBase
            {
                [Fact]
                public void CallsGet()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;

                    var subtype = new SubTypeBuilder {Id = "1", Name = Fixture.String()}.In(Db);

                    f.SubTypesPicklistMaintenance.Get(1)
                     .ReturnsForAnyArgs(new SubType {Code = subtype.Id, Value = subtype.Name});

                    var response = s.Get(1);
                    f.SubTypesPicklistMaintenance.Received(1).Get(1);
                    Assert.Equal(subtype.Id, response.Code);
                    Assert.Equal(subtype.Name, response.Value);
                }

                [Fact]
                public void CallsGetForSubTypeIfValidcCombinationKeysNotProvided()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;

                    f.SubTypesPicklistMaintenance.Get(1)
                     .ReturnsForAnyArgs(new SubType {Code = "1", Value = Fixture.String()});

                    s.Get(1, string.Empty, false);
                    f.SubTypesPicklistMaintenance.Received(2).Get(1);
                }

                [Fact]
                public void CallsGetForValidSubType()
                {
                    var f = new SubTypesPicklistControllerFixture();
                    var s = f.Subject;

                    f.SubTypesPicklistMaintenance.Get(1).Returns(new SubType());

                    var keys = new ValidCombinationKeys {CaseType = "P", Jurisdiction = "AU", PropertyType = "T", CaseCategory = "P"};

                    var exception =
                        Record.Exception(() => s.Get(1, JsonConvert.SerializeObject(keys), false));

                    Assert.IsType<HttpResponseException>(exception);
                }

                [Fact]
                public void ShouldBeDecoratedWithPicklistPayloadAttribute()
                {
                    var subjectType = new SubTypesPicklistControllerFixture().Subject.GetType();
                    var picklistAttribute =
                        subjectType.GetMethod("SubTypes").GetCustomAttribute<PicklistPayloadAttribute>();

                    Assert.NotNull(picklistAttribute);
                    Assert.Equal("SubType", picklistAttribute.Name);
                }
            }

            [Fact]
            public void MarksExactMatchOnCode()
            {
                var f = new SubTypesPicklistControllerFixture();

                var s1 = new SubTypeListItem {SubTypeKey = "A", SubTypeDescription = "B"};
                var s2 = new SubTypeListItem {SubTypeKey = "B", SubTypeDescription = "ADecoy"};
                var s3 = new SubTypeListItem {SubTypeKey = "C", SubTypeDescription = "ADecoy"};

                f.SubTypes.GetSubTypes(null, null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3});

                f.SubTypes.Get(s1.SubTypeKey).Returns(new SubType {Code = s1.SubTypeKey, Value = s1.SubTypeDescription, Key = 1});
                f.SubTypes.Get(s2.SubTypeKey).Returns(new SubType {Code = s2.SubTypeKey, Value = s2.SubTypeDescription, Key = 2});
                f.SubTypes.Get(s3.SubTypeKey).Returns(new SubType {Code = s3.SubTypeKey, Value = s3.SubTypeDescription, Key = 3});

                var r = f.Subject.SubTypes(null, "A");

                var j = r.Data.OfType<SubType>().ToArray();

                Assert.Equal(3, j.Length);
                Assert.Equal(s1.SubTypeKey, j.First().Code);
            }

            [Fact]
            public void MarksExactMatchOnValue()
            {
                var f = new SubTypesPicklistControllerFixture();
                var s1 = new SubTypeListItem {SubTypeKey = "A", SubTypeDescription = "A"};
                var s2 = new SubTypeListItem {SubTypeKey = "B", SubTypeDescription = "AB"};

                f.SubTypes.GetSubTypes(null, null, null, null).ReturnsForAnyArgs(new[] {s1, s2});

                f.SubTypes.Get(s1.SubTypeKey).Returns(new SubType {Code = s1.SubTypeKey, Value = s1.SubTypeDescription, Key = 1});
                f.SubTypes.Get(s2.SubTypeKey).Returns(new SubType {Code = s2.SubTypeKey, Value = s2.SubTypeDescription, Key = 2});

                var r = f.Subject.SubTypes(null, "A");

                var j = r.Data.OfType<SubType>().ToArray();

                Assert.Equal(2, j.Length);
                Assert.Equal(s1.SubTypeDescription, j.First().Value);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new SubTypesPicklistControllerFixture();

                var s1 = new SubTypeListItem {SubTypeKey = "A", SubTypeDescription = "Decoy1"};
                var s2 = new SubTypeListItem {SubTypeKey = "C", SubTypeDescription = "Decoy2"};
                var s3 = new SubTypeListItem {SubTypeKey = "B", SubTypeDescription = "Target"};

                f.SubTypes.GetSubTypes(null, null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3});

                f.SubTypes.Get(s1.SubTypeKey).Returns(new SubType {Code = s1.SubTypeKey, Value = s1.SubTypeDescription, Key = 1});
                f.SubTypes.Get(s2.SubTypeKey).Returns(new SubType {Code = s2.SubTypeKey, Value = s2.SubTypeDescription, Key = 2});
                f.SubTypes.Get(s3.SubTypeKey).Returns(new SubType {Code = s3.SubTypeKey, Value = s3.SubTypeDescription, Key = 3});

                var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.SubTypes(qParams);
                var subTypes = r.Data.OfType<SubType>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(subTypes);
                Assert.Equal(s3.SubTypeKey, subTypes.Single().Code);
            }

            [Fact]
            public void ReturnsSubTypesContainingSearchStringOrderedByExactMatchThenValue()
            {
                var f = new SubTypesPicklistControllerFixture();

                var s1 = new SubTypeListItem {SubTypeKey = "AB", SubTypeDescription = "HIJKL"};
                var s2 = new SubTypeListItem {SubTypeKey = "BA", SubTypeDescription = "ABCDEFG"};
                var s3 = new SubTypeListItem {SubTypeKey = "BC", SubTypeDescription = "MNOPQ"};

                f.SubTypes.GetSubTypes(null, null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3});

                f.SubTypes.Get(s1.SubTypeKey).Returns(new SubType {Code = s1.SubTypeKey, Value = s1.SubTypeDescription, Key = 1});
                f.SubTypes.Get(s2.SubTypeKey).Returns(new SubType {Code = s2.SubTypeKey, Value = s2.SubTypeDescription, Key = 2});
                f.SubTypes.Get(s3.SubTypeKey).Returns(new SubType {Code = s3.SubTypeKey, Value = s3.SubTypeDescription, Key = 3});

                var r = f.Subject.SubTypes(null, "AB");

                var j = r.Data.OfType<SubType>().ToArray();

                Assert.Equal(s1.SubTypeKey, j[0].Code);
                Assert.Equal(s2.SubTypeKey, j[1].Code);
                Assert.Null(j.FirstOrDefault(_ => _.Code == s3.SubTypeKey));
            }

            [Fact]
            public void ReturnsSubTypesSortedByCode()
            {
                var f = new SubTypesPicklistControllerFixture();

                var s1 = new SubTypeListItem {SubTypeKey = "B", SubTypeDescription = "BDESC"};
                var s2 = new SubTypeListItem {SubTypeKey = "A", SubTypeDescription = "ADESC"};
                var s3 = new SubTypeListItem {SubTypeKey = "C", SubTypeDescription = "CDESC"};

                f.SubTypes.GetSubTypes(null, null, null, null).ReturnsForAnyArgs(new[] {s1, s2, s3});

                f.SubTypes.Get(s1.SubTypeKey).Returns(new SubType {Code = s1.SubTypeKey, Value = s1.SubTypeDescription, Key = 1});
                f.SubTypes.Get(s2.SubTypeKey).Returns(new SubType {Code = s2.SubTypeKey, Value = s2.SubTypeDescription, Key = 2});
                f.SubTypes.Get(s3.SubTypeKey).Returns(new SubType {Code = s3.SubTypeKey, Value = s3.SubTypeDescription, Key = 3});

                var j = f.Subject.SubTypes().Data.OfType<SubType>().ToArray();

                Assert.Equal(s2.SubTypeKey, j[0].Code);
                Assert.Equal(s2.SubTypeDescription, j[0].Value);
                Assert.Equal(s1.SubTypeKey, j[1].Code);
                Assert.Equal(s1.SubTypeDescription, j[1].Value);
                Assert.Equal(s3.SubTypeKey, j[2].Code);
                Assert.Equal(s3.SubTypeDescription, j[2].Value);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new SubTypesPicklistControllerFixture().Subject.GetType();
                var picklistAttribute = subjectType.GetMethod("SubTypes").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("SubType", picklistAttribute.Name);
            }
        }
    }

    public class SubTypesPicklistControllerFixture : IFixture<SubTypesPicklistController>
    {
        public SubTypesPicklistControllerFixture()
        {
            SubTypes = Substitute.For<ISubTypes>();
            SubTypesPicklistMaintenance = Substitute.For<ISubTypesPicklistMaintenance>();
            ValidSubTypes = Substitute.For<IValidSubTypes>();
            Subject = new SubTypesPicklistController(SubTypes, SubTypesPicklistMaintenance, ValidSubTypes);
        }

        public ISubTypes SubTypes { get; set; }
        public ISubTypesPicklistMaintenance SubTypesPicklistMaintenance { get; set; }

        public IValidSubTypes ValidSubTypes { get; set; }
        public SubTypesPicklistController Subject { get; }
    }
}