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
using Basis = Inprotech.Web.Picklists.Basis;

namespace Inprotech.Tests.Web.Picklists
{
    public class BasisPicklistControllerFacts : FactBase
    {
        public class BasisMethod : FactBase
        {
            [Fact]
            public void ReturnsBasisContainingSearchStringOrderedByExactMatch()
            {
                var f = new BasisPicklistControllerFixture();

                var b1 = new BasisListItem {Convention = 1, ApplicationBasisKey = "A", ApplicationBasisDescription = "ABCDEFG"};
                var b2 = new BasisListItem {Convention = 1, ApplicationBasisKey = "B", ApplicationBasisDescription = "DEFGHI"};
                var b3 = new BasisListItem {Convention = 0, ApplicationBasisKey = "C", ApplicationBasisDescription = "DEFGHI"};

                f.Basis.GetBasis(null, null, null, null).ReturnsForAnyArgs(new[] {b1, b2, b3});
                f.Basis.Get((string[]) null).ReturnsForAnyArgs(new[] {b1, b2, b3});
                var r = f.Subject.Basis(null, "B");
                var p = r.Data.OfType<Basis>().ToArray();

                Assert.Null(p.FirstOrDefault(_ => _.Code == b3.ApplicationBasisKey));
            }

            [Fact]
            public void ReturnsBasisSortedByDescription()
            {
                var f = new BasisPicklistControllerFixture();

                var b1 = new BasisListItem {Convention = 1, ApplicationBasisKey = "A", ApplicationBasisDescription = "DEFGHI"};
                var b2 = new BasisListItem {Convention = 1, ApplicationBasisKey = "B", ApplicationBasisDescription = "ABCDEFG"};
                var b3 = new BasisListItem {Convention = 0, ApplicationBasisKey = "C", ApplicationBasisDescription = "GHIJKL"};

                f.Basis.GetBasis(null, null, null, null).ReturnsForAnyArgs(new[] {b1, b2, b3});
                f.Basis.Get((string[]) null).ReturnsForAnyArgs(new[] {b1, b2, b3});
                var r = f.Subject.Basis();
                var p = r.Data.OfType<Basis>().ToArray();

                Assert.Equal(b2.ApplicationBasisKey, p[0].Code);
                Assert.Equal(b2.ApplicationBasisDescription, p[0].Value);
                Assert.Equal(b1.ApplicationBasisKey, p[1].Code);
                Assert.Equal(b1.ApplicationBasisDescription, p[1].Value);
                Assert.Equal(b3.ApplicationBasisKey, p[2].Code);
                Assert.Equal(b3.ApplicationBasisDescription, p[2].Value);
            }

            [Fact]
            public void ReturnsBasisWithExactMatchFlagOnCodeOrderedByExactMatch()
            {
                var f = new BasisPicklistControllerFixture();

                var b1 = new BasisListItem {Convention = 1, ApplicationBasisKey = "A", ApplicationBasisDescription = "~Decoy1"};
                var b2 = new BasisListItem {Convention = 1, ApplicationBasisKey = "!", ApplicationBasisDescription = "Decoy2"};
                var b3 = new BasisListItem {Convention = 0, ApplicationBasisKey = "~", ApplicationBasisDescription = "Target"};
                f.Basis.Get((string[]) null).ReturnsForAnyArgs(new[] {b1, b2, b3});

                f.Basis.GetBasis(null, null, null, null).ReturnsForAnyArgs(new[] {b1, b2, b3});
                var r = f.Subject.Basis(null, "~");
                var p = r.Data.OfType<Basis>().ToArray();

                Assert.Equal(2, p.Length);
                Assert.Equal(b3.ApplicationBasisKey, p[0].Code);
                Assert.Equal(b1.ApplicationBasisKey, p[1].Code);
            }

            [Fact]
            public void ReturnsBasisWithExactMatchFlagOnDescription()
            {
                var f = new BasisPicklistControllerFixture();

                var b1 = new BasisListItem {Convention = 1, ApplicationBasisKey = "1", ApplicationBasisDescription = "A"};
                var b2 = new BasisListItem {Convention = 1, ApplicationBasisKey = "2", ApplicationBasisDescription = "AB"};
                f.Basis.Get((string[]) null).ReturnsForAnyArgs(new[] {b1, b2});

                f.Basis.GetBasis(null, null, null, null).ReturnsForAnyArgs(new[] {b1, b2});
                var r = f.Subject.Basis(null, "A");
                var p = r.Data.OfType<Basis>().ToArray();

                Assert.Equal(2, p.Length);
                Assert.Equal(b1.ApplicationBasisKey, p[0].Code);
                Assert.Equal(b2.ApplicationBasisKey, p[1].Code);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new BasisPicklistControllerFixture();
                var b1 = new BasisListItem {Convention = 1, ApplicationBasisKey = "A1", ApplicationBasisDescription = "A1 Desc"};
                var b2 = new BasisListItem {Convention = 1, ApplicationBasisKey = "A2", ApplicationBasisDescription = "A2 Desc"};
                var b3 = new BasisListItem {Convention = 0, ApplicationBasisKey = "A3", ApplicationBasisDescription = "A3 Desc"};
                f.Basis.Get((string[]) null).ReturnsForAnyArgs(new[] {b1, b2, b3});

                var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.Basis(qParams);
                var basis = r.Data.OfType<Basis>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(basis);
                Assert.Equal(b2.ApplicationBasisKey, basis.Single().Code);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new BasisPicklistControllerFixture().Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Basis").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("Basis", picklistAttribute.Name);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsPicklistMaintenanceSave()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                var model = new Basis();

                f.BasisPicklistMaintenance.Save(Arg.Any<Basis>(), Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var basisSaveData = JObject.FromObject(model);
                Assert.Equal(r, s.Update("1", basisSaveData));
                f.BasisPicklistMaintenance.ReceivedWithAnyArgs(1).Save(basisSaveData.ToObject<Basis>(), Operation.Update);
            }

            [Fact]
            public void CallsValidBasisControllerSave()
            {
                var f = new BasisPicklistControllerFixture();

                var model = new ValidBasisIdentifier();
                var basisSaveData = JObject.FromObject(model);
                basisSaveData["validDescription"] = Fixture.String("11");
                var saveDetails = basisSaveData.ToObject<BasisSaveDetails>();
                f.ValidBasisImp.Update(saveDetails).Returns(new object());
                f.Subject.Update(Fixture.String(), basisSaveData);

                f.ValidBasisImp.ReceivedWithAnyArgs(1).Update(saveDetails);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new BasisPicklistControllerFixture();

                var exception =
                    Record.Exception(() => f.Subject.Update("1", null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class AddOrDuplicateMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.BasisPicklistMaintenance.Save(null, Arg.Any<Operation>())
                 .ReturnsForAnyArgs(r);

                var model = new Basis();
                Assert.Equal(r, s.AddOrDuplicate(JObject.FromObject(model)));
                f.BasisPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model, Operation.Add);
            }

            [Fact]
            public void CallsValidCategoryControllerSave()
            {
                var f = new BasisPicklistControllerFixture();

                var model = new BasisSaveDetails();
                var saveData = JObject.FromObject(model);
                saveData["validDescription"] = Fixture.String("11");
                var response = new {Result = "Success"};
                f.ValidBasisImp.Save(Arg.Any<BasisSaveDetails>()).Returns(response);
                var result = f.Subject.AddOrDuplicate(saveData);

                f.ValidBasisImp.ReceivedWithAnyArgs(1).Save(Arg.Any<BasisSaveDetails>());
                Assert.Equal(response.Result, result.Result);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.BasisPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1));
                f.BasisPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsDeleteForActionIfValidcCombinationKeysNotProvided()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;
                var r = new object();

                f.BasisPicklistMaintenance.Delete(1)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1, string.Empty));
                f.BasisPicklistMaintenance.Received(1).Delete(1);
            }

            [Fact]
            public void CallsValidPropertyTypesDelete()
            {
                var f = new BasisPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                f.BasisPicklistMaintenance.Get(1)
                 .ReturnsForAnyArgs(new Basis {Key = 1, Code = "A", Value = "C"});

                f.ValidBasisImp.Delete(Arg.Any<ValidBasisIdentifier[]>()).Returns(new DeleteResponseModel<ValidBasisIdentifier>());

                var response = f.Subject.Delete(1, deleteData.ToString());

                f.ValidBasisImp.ReceivedWithAnyArgs(1).Delete(Arg.Any<ValidBasisIdentifier[]>());

                Assert.NotNull(response);
            }

            [Fact]
            public void ThrowsExceptionWhenCallsDeleteWithIncorrectParams()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;

                dynamic data = new {validCombinationKeys = string.Empty, isDefaultJurisdiction = "false"};

                f.BasisPicklistMaintenance.Get(1)
                 .ReturnsForAnyArgs(new Basis {Key = 1, Code = "A", Value = "C"});

                var exception =
                    Record.Exception(() => s.Delete(1, JsonConvert.SerializeObject(data)));

                Assert.IsType<HttpResponseException>(exception);
            }

            [Fact]
            public void ThrowsExceptionWhenResponseIsNull()
            {
                var f = new BasisPicklistControllerFixture();

                var deleteData = new JObject();
                var keys = new ValidCombinationKeys {Jurisdiction = "AU"};
                deleteData["validCombinationKeys"] = keys.ToJson();
                deleteData["isDefaultJurisdiction"] = "false";
                f.BasisPicklistMaintenance.Get(1)
                 .ReturnsForAnyArgs(new Basis {Key = 1, Code = "A", Value = "C"});

                f.ValidBasisImp.Delete(Arg.Any<ValidBasisIdentifier[]>()).Returns(null as DeleteResponseModel<ValidBasisIdentifier>);

                var exception = Record.Exception(() => f.Subject.Delete(1, deleteData.ToString()));
                Assert.IsType<HttpResponseException>(exception);
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void CallsBasisGet()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;

                var basis = new ApplicationBasisBuilder {Id = "1", Name = Fixture.String()}.In(Db);

                f.BasisPicklistMaintenance.Get(1)
                 .ReturnsForAnyArgs(new Basis {Code = basis.Id, Value = basis.Name});

                var response = s.BasisDetail(1);
                Assert.Equal(basis.Id, response.Code);
                Assert.Equal(basis.Name, response.Value);
            }

            [Fact]
            public void CallsGetForBasisIfValidCombinationKeysNotProvided()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;

                f.BasisPicklistMaintenance.Get(1)
                 .ReturnsForAnyArgs(new Basis {Code = "1", Value = "1"});

                s.BasisDetail(1, string.Empty, false);
                f.BasisPicklistMaintenance.Received(2).Get(1);
            }

            [Fact]
            public void CallsGetForValidBasis()
            {
                var f = new BasisPicklistControllerFixture();
                var s = f.Subject;
                var keys = new ValidCombinationKeys {CaseType = "P", Jurisdiction = "AU", PropertyType = "T", CaseCategory = "P"};

                f.BasisPicklistMaintenance.Get(1).Returns(new Basis {Code = Fixture.String()});

                var exception =
                    Record.Exception(() => s.BasisDetail(1, JsonConvert.SerializeObject(keys), false));

                Assert.IsType<HttpResponseException>(exception);
            }
        }
    }

    public class BasisPicklistControllerFixture : IFixture<BasisPicklistController>
    {
        public BasisPicklistControllerFixture()
        {
            Basis = Substitute.For<IBasis>();
            BasisPicklistMaintenance = Substitute.For<IBasisPicklistMaintenance>();
            ValidBasisImp = Substitute.For<IValidBasisImp>();
            Subject = new BasisPicklistController(Basis, BasisPicklistMaintenance, ValidBasisImp);
        }

        public IBasis Basis { get; set; }
        public IBasisPicklistMaintenance BasisPicklistMaintenance { get; set; }
        public IValidBasisImp ValidBasisImp { get; set; }
        public BasisPicklistController Subject { get; }
    }
}