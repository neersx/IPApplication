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
using InprotechKaizen.Model.Components.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using ServiceStack;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseCategoriesPicklistControllerFacts : FactBase
    {
        public class CaseCategoriesMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseCategoriesContainingSearchStringOrderedByExactMatch()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var p1 = new CaseCategoryListItem {CaseCategoryKey = "A", CaseCategoryDescription = "ABCDEFG", CaseTypeKey = "E", CaseTypeDescription = "E desc", Id = 1};
                var p2 = new CaseCategoryListItem {CaseCategoryKey = "B", CaseCategoryDescription = "DEFGHI", CaseTypeKey = "F", CaseTypeDescription = "F desc", Id = 2};
                var p3 = new CaseCategoryListItem {CaseCategoryKey = "C", CaseCategoryDescription = "GHIJKL", CaseTypeKey = "G", CaseTypeDescription = "G desc", Id = 3};

                f.CaseCategories.GetCaseCategories(null, null, null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.CaseCategories.Get("A", "E").Returns(p1);
                f.CaseCategories.Get("B", "F").Returns(p2);
                f.CaseCategories.Get("C", "G").Returns(p3);

                var r = f.Subject.CaseCategories(null, "B");
                var p = r.Data.OfType<CaseCategory>().ToArray();

                Assert.Equal(p2.CaseCategoryKey, p[0].Code);
                Assert.Equal(p1.CaseCategoryKey, p[1].Code);
                Assert.Null(p.FirstOrDefault(_ => _.Code == p3.CaseCategoryKey));
            }

            [Fact]
            public void ReturnsCaseCategoriesSortedByDescription()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var p1 = new CaseCategoryListItem {CaseCategoryKey = "A", CaseCategoryDescription = "DEFGHI", CaseTypeKey = "E", CaseTypeDescription = "E desc", Id = 1};
                var p2 = new CaseCategoryListItem {CaseCategoryKey = "B", CaseCategoryDescription = "ABCDEFG", CaseTypeKey = "F", CaseTypeDescription = "F desc", Id = 2};
                var p3 = new CaseCategoryListItem {CaseCategoryKey = "C", CaseCategoryDescription = "GHIJKL", CaseTypeKey = "G", CaseTypeDescription = "G desc", Id = 3};

                f.CaseCategories.GetCaseCategories(null, null, null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.CaseCategories.Get("A", "E").Returns(p1);
                f.CaseCategories.Get("B", "F").Returns(p2);
                f.CaseCategories.Get("C", "G").Returns(p3);

                var r = f.Subject.CaseCategories();
                var p = r.Data.OfType<CaseCategory>().ToArray();

                Assert.Equal(p2.CaseCategoryKey, p[0].Code);
                Assert.Equal(p2.CaseCategoryDescription, p[0].Value);
                Assert.Equal(p1.CaseCategoryKey, p[1].Code);
                Assert.Equal(p1.CaseCategoryDescription, p[1].Value);
                Assert.Equal(p3.CaseCategoryKey, p[2].Code);
                Assert.Equal(p3.CaseCategoryDescription, p[2].Value);
            }

            [Fact]
            public void ReturnsCaseCategoriesWithExactMatchFlagOnCodeOrderedByExactMatch()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var p1 = new CaseCategoryListItem {CaseCategoryKey = "A", CaseCategoryDescription = "~Decoy1", CaseTypeKey = "E", CaseTypeDescription = "E desc", Id = 1};
                var p2 = new CaseCategoryListItem {CaseCategoryKey = "!", CaseCategoryDescription = "Decoy2", CaseTypeKey = "F", CaseTypeDescription = "F desc", Id = 2};
                var p3 = new CaseCategoryListItem {CaseCategoryKey = "~", CaseCategoryDescription = "Target", CaseTypeKey = "G", CaseTypeDescription = "G desc", Id = 3};

                f.CaseCategories.GetCaseCategories(null, null, null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.CaseCategories.Get("A", "E").Returns(p1);
                f.CaseCategories.Get("!", "F").Returns(p2);
                f.CaseCategories.Get("~", "G").Returns(p3);

                var r = f.Subject.CaseCategories(null, "~");
                var p = r.Data.OfType<CaseCategory>().ToArray();

                Assert.Equal(2, p.Length);
                Assert.Equal(p3.CaseCategoryKey, p[0].Code);
                Assert.Equal(p1.CaseCategoryKey, p[1].Code);
            }

            [Fact]
            public void ReturnsCaseCategoriesWithExactMatchFlagOnDescription()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var p1 = new CaseCategoryListItem {CaseCategoryKey = "1", CaseCategoryDescription = "A", CaseTypeKey = "E", CaseTypeDescription = "E desc", Id = 1};
                var p2 = new CaseCategoryListItem {CaseCategoryKey = "2", CaseCategoryDescription = "AB", CaseTypeKey = "F", CaseTypeDescription = "F desc", Id = 2};

                f.CaseCategories.GetCaseCategories(null, null, null).ReturnsForAnyArgs(new[] {p1, p2});

                f.CaseCategories.Get("1", "E").Returns(p1);
                f.CaseCategories.Get("2", "F").Returns(p2);

                var r = f.Subject.CaseCategories(null, "A");
                var p = r.Data.OfType<CaseCategory>().ToArray();

                Assert.Equal(2, p.Length);
                Assert.Equal(p1.CaseCategoryDescription, p[0].Value);
                Assert.Equal(p2.CaseCategoryDescription, p[1].Value);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var p1 = new CaseCategoryListItem {CaseCategoryKey = "A", CaseCategoryDescription = "Decoy1", CaseTypeKey = "E", CaseTypeDescription = "E desc", Id = 1};
                var p2 = new CaseCategoryListItem {CaseCategoryKey = "C", CaseCategoryDescription = "Decoy2", CaseTypeKey = "F", CaseTypeDescription = "F desc", Id = 2};
                var p3 = new CaseCategoryListItem {CaseCategoryKey = "B", CaseCategoryDescription = "Target", CaseTypeKey = "G", CaseTypeDescription = "G desc", Id = 3};

                var qParams = new CommonQueryParameters {SortBy = "code", SortDir = "asc", Skip = 1, Take = 1};

                f.CaseCategories.GetCaseCategories(null, null, null).ReturnsForAnyArgs(new[] {p1, p2, p3});

                f.CaseCategories.Get("A", "E").Returns(p1);
                f.CaseCategories.Get("C", "F").Returns(p2);
                f.CaseCategories.Get("B", "G").Returns(p3);

                var r = f.Subject.CaseCategories(qParams);
                var caseCategories = r.Data.OfType<CaseCategory>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(caseCategories);
                Assert.Equal(p3.CaseCategoryKey, caseCategories.Single().Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new CaseCategoriesPicklistControllerFixture().Subject.GetType();
                var picklistAttribute = subjectType.GetMethod("CaseCategories").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("CaseCategory", picklistAttribute.Name);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsPicklistMaintenanceSave()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                var model = new CaseCategory();

                f.CaseCategoriesPicklistMaintenance.Save(Arg.Any<CaseCategory>(), Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var caseCategorySaveData = JObject.FromObject(model);
                Assert.Equal(r, s.Update(1, caseCategorySaveData));
                f.CaseCategoriesPicklistMaintenance.ReceivedWithAnyArgs(1).Save(caseCategorySaveData.ToObject<CaseCategory>(), Operation.Update);
            }

            [Fact]
            public void CallsValidCategoryControllerSave()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var model = new CaseCategorySaveDetails();
                var caseCategorySaveData = JObject.FromObject(model);
                caseCategorySaveData["validDescription"] = Fixture.String("11");
                var saveDetails = caseCategorySaveData.ToObject<CaseCategorySaveDetails>();
                f.ValidCategories.Update(saveDetails).Returns(new object());
                f.Subject.Update(Fixture.Integer(), caseCategorySaveData);

                f.ValidCategories.ReceivedWithAnyArgs(1).Update(saveDetails);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

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
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.CaseCategoriesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new CaseCategory();
                Assert.Equal(r, s.AddOrDuplicate(JObject.FromObject(model)));
                f.CaseCategoriesPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Add);
            }

            [Fact]
            public void CallsValidCategoryControllerSave()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var model = new CaseCategorySaveDetails();
                var caseCategorySaveData = JObject.FromObject(model);
                caseCategorySaveData["validDescription"] = Fixture.String("11");
                var response = new {Result = "Success"};
                f.ValidCategories.Save(Arg.Any<CaseCategorySaveDetails>()).Returns(response);
                var result = f.Subject.AddOrDuplicate(caseCategorySaveData);

                f.ValidCategories.ReceivedWithAnyArgs(1).Save(Arg.Any<CaseCategorySaveDetails>());
                Assert.Equal(response.Result, result.Result);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

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
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.CaseCategoriesPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.CaseCategoriesPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsDeleteForCaseCategoryIfValidCombinationKeysNotProvided()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.CaseCategoriesPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1, string.Empty));
                f.CaseCategoriesPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsValidPropertyTypesDelete()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                f.CaseCategories.Get(1)
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = 1, CaseCategoryKey = "A", CaseTypeKey = "C"});

                f.ValidCategories.Delete(Arg.Any<ValidCategoryIdentifier[]>()).Returns(new DeleteResponseModel<ValidCategoryIdentifier>());

                var response = f.Subject.Delete(1, deleteData.ToString());

                f.ValidCategories.ReceivedWithAnyArgs(1).Delete(Arg.Any<ValidCategoryIdentifier[]>());

                Assert.NotNull(response);
            }

            [Fact]
            public void ThrowsExceptionWhenCallsDeleteWithIncorrectParams()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;

                dynamic data = new {validCombinationKeys = string.Empty, isDefaultJurisdiction = "false"};

                f.CaseCategories.Get(1)
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = 1, CaseCategoryKey = "A", CaseTypeKey = "C"});

                var exception =
                    Record.Exception(() => s.Delete(1, JsonConvert.SerializeObject(data)));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNull()
            {
                var f = new CaseCategoriesPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                f.CaseCategories.Get(1)
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = 1, CaseCategoryKey = "A", CaseTypeKey = "C"});

                f.ValidCategories.Delete(Arg.Any<ValidCategoryIdentifier[]>()).Returns(null as DeleteResponseModel<ValidCategoryIdentifier>);

                var exception = Record.Exception(() => f.Subject.Delete(1, deleteData.ToString()));
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void CallsCaseCategoryGet()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;

                var caseCategory = new CaseCategoryBuilder {CaseTypeId = "A", CaseCategoryId = "C", Name = "Abc"}.Build().In(Db);

                f.CaseCategories.Get(1)
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = caseCategory.Id, CaseCategoryKey = caseCategory.CaseCategoryId, CaseTypeKey = caseCategory.CaseTypeId});

                var response = s.CaseCategory(1);
                f.CaseCategories.Received(1).Get(1);
                Assert.Equal(caseCategory.CaseTypeId, response.CaseTypeId);
                Assert.Equal(caseCategory.CaseCategoryId, response.Code);
            }

            [Fact]
            public void CallsCaseCategoryGetForCaseType()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;

                var caseCategory = new CaseCategoryBuilder {CaseTypeId = "A", CaseCategoryId = "C", Name = "Abc"}.Build().In(Db);

                f.CaseCategories.Get(Arg.Any<string>(), Arg.Any<string>())
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = caseCategory.Id, CaseCategoryKey = caseCategory.CaseCategoryId, CaseTypeKey = caseCategory.CaseTypeId});

                var response = s.CaseCategory("C", "A");
                f.CaseCategories.Received(1).Get("C", "A");
                Assert.Equal(caseCategory.CaseTypeId, response.CaseTypeId);
                Assert.Equal(caseCategory.CaseCategoryId, response.Code);
            }

            [Fact]
            public void CallsGetForCaseCategoryIfValidcCombinationKeysNotProvided()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;
                f.CaseCategories.Get(1)
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = 1, CaseCategoryKey = "A", CaseTypeKey = "C"});

                s.CaseCategory(1, string.Empty, false);

                f.CaseCategories.Received(1).Get(1);
            }

            [Fact]
            public void CallsGetForValidCaseCategory()
            {
                var f = new CaseCategoriesPicklistControllerFixture();
                var s = f.Subject;
                var keys = new ValidCombinationKeys {CaseType = "P", Jurisdiction = "AU", PropertyType = "T"};

                f.CaseCategories.Get(1)
                 .ReturnsForAnyArgs(new CaseCategoryListItem {Id = 1, CaseCategoryKey = "A", CaseTypeKey = "C"});

                var exception =
                    Record.Exception(() => s.CaseCategory(1, JsonConvert.SerializeObject(keys), false));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new CaseCategoriesPicklistControllerFixture().Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("CaseCategories").GetCustomAttribute<PicklistPayloadAttribute>();
                Assert.NotNull(picklistAttribute);
                Assert.Equal("CaseCategory", picklistAttribute.Name);
            }
        }
    }

    public class CaseCategoriesPicklistControllerFixture : IFixture<CaseCategoriesPicklistController>
    {
        public CaseCategoriesPicklistControllerFixture()
        {
            CaseCategories = Substitute.For<ICaseCategories>();
            CaseCategoriesPicklistMaintenance = Substitute.For<ICaseCategoriesPicklistMaintenance>();
            ValidCategories = Substitute.For<IValidCategories>();
            MultipleClassAppCountries = Substitute.For<IMultipleClassApplicationCountries>();

            Subject = new CaseCategoriesPicklistController(CaseCategories, CaseCategoriesPicklistMaintenance, ValidCategories, MultipleClassAppCountries);
        }

        public ICaseCategories CaseCategories { get; set; }
        public ICaseCategoriesPicklistMaintenance CaseCategoriesPicklistMaintenance { get; set; }
        public IMultipleClassApplicationCountries MultipleClassAppCountries { get; set; }

        public IValidCategories ValidCategories { get; set; }

        public CaseCategoriesPicklistController Subject { get; }
    }
}