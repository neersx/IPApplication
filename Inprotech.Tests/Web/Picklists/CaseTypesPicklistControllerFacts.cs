using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CasesTypePicklistControllerFacts : FactBase
    {
        public class CaseTypesMethod : FactBase
        {
            public class UpdateMethod : FactBase
            {
                [Fact]
                public void CallsSave()
                {
                    var f = new CaseTypePicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    f.CaseTypesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                     .ReturnsForAnyArgs(r);

                    var model = new CaseType();

                    Assert.Equal(r, s.Update(1, model));
                    f.CaseTypesPicklistMaintenance.Received(1).Save(model, Operation.Update);
                }
            }

            public class AddOrDuplicateMethod : FactBase
            {
                [Fact]
                public void CallsSave()
                {
                    var f = new CaseTypePicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    f.CaseTypesPicklistMaintenance.Save(null, Arg.Any<Operation>())
                     .ReturnsForAnyArgs(r);

                    var model = new CaseType();

                    Assert.Equal(r, s.AddOrDuplicate(model));
                    f.CaseTypesPicklistMaintenance.Received(1).Save(model, Operation.Add);
                }
            }

            public class DeleteMethod : FactBase
            {
                [Fact]
                public void CallsDelete()
                {
                    var f = new CaseTypePicklistControllerFixture();
                    var s = f.Subject;
                    var r = new object();

                    f.CaseTypesPicklistMaintenance.Delete(1)
                     .ReturnsForAnyArgs(r);

                    Assert.Equal(r, s.Delete(1));
                    f.CaseTypesPicklistMaintenance.Received(1).Delete(1);
                }
            }

            public class GetMethod : FactBase
            {
                [Fact]
                public void CallsGet()
                {
                    var f = new CaseTypePicklistControllerFixture();
                    var caseType = new CaseTypeBuilder().Build().In(Db);

                    var s = f.Subject;

                    f.CaseTypes.GetCaseType(caseType.Id).Returns(new CaseType(caseType.Code, caseType.Name));

                    var model = s.Get(caseType.Id);

                    Assert.Equal(caseType.Code, model.Code);
                    Assert.Equal(caseType.Name, model.Value);
                }

                [Fact]
                public void ShouldBeDecoratedWithPicklistPayloadAttribute()
                {
                    var subjectType = new CaseTypePicklistControllerFixture().Subject.GetType();
                    var picklistAttribute = subjectType.GetMethod("CaseTypes").GetCustomAttribute<PicklistPayloadAttribute>();

                    Assert.NotNull(picklistAttribute);
                    Assert.Equal("CaseType", picklistAttribute.Name);
                }
            }

            [Fact]
            public void MarksExactMatchOnDescription()
            {
                var f = new CaseTypePicklistControllerFixture();

                var searchText = "ABC";
                var ct2 = new CaseType("BC", "ABCDEFG");
                var ctTarget = new CaseType("BA", "ABC");

                f.CaseTypes.GetCaseTypesWithDetails().ReturnsForAnyArgs(new[] {ctTarget, ct2});

                var r = f.Subject.CaseTypes(null, searchText);

                var j = r.Data.OfType<CaseType>().ToArray();

                Assert.Equal(2, j.Length);
                Assert.Equal(ctTarget.Key, j[0].Key);
                Assert.Equal(ct2.Key, j[1].Key);

                searchText = "BA";
                f.CaseTypes.GetCaseTypesWithDetails().ReturnsForAnyArgs(new[] {ctTarget, ct2});
                r = f.Subject.CaseTypes(null, searchText);
                j = r.Data.OfType<CaseType>().ToArray();
                Assert.Single(j);
                Assert.Equal(ctTarget.Key, j[0].Key);
            }

            [Fact]
            public void ReturnsCaseTypesSortedByDescription()
            {
                var f = new CaseTypePicklistControllerFixture();

                var ct1 = new CaseType("B", "ADESC");
                var ct2 = new CaseType("C", "BDESC");
                var ct3 = new CaseType("A", "CDESC");

                f.CaseTypes.GetCaseTypesWithDetails().ReturnsForAnyArgs(new[] {ct1, ct3, ct2});
                var r = f.Subject.CaseTypes();

                var j = r.Data.OfType<CaseType>().ToArray();

                Assert.Equal(ct1.Key, j[0].Key);
                Assert.Equal(ct1.Value, j[0].Value);
                Assert.Equal(ct2.Key, j[1].Key);
                Assert.Equal(ct2.Value, j[1].Value);
                Assert.Equal(ct3.Key, j[2].Key);
                Assert.Equal(ct3.Value, j[2].Value);
            }

            [Fact]
            public void ReturnsCaseTypesStartingWithSearchString()
            {
                var f = new CaseTypePicklistControllerFixture();

                var ct1 = new CaseType("AB", "HABKL");
                var ct2 = new CaseType("BC", "MNOAB");
                var ct3 = new CaseType("BA", "ABCDEFG");
                var ct4 = new CaseType("irr", "irrelevant");

                f.CaseTypes.GetCaseTypesWithDetails().ReturnsForAnyArgs(new[] {ct1, ct2, ct3, ct4});

                var r = f.Subject.CaseTypes(null, "AB");

                var j = r.Data.OfType<CaseType>().ToArray();

                Assert.Equal(3, j.Length);
                Assert.DoesNotContain(j, x => x.Code == ct4.Code);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new CaseTypePicklistControllerFixture();

                var ct1 = new CaseType("A", "ADecoy");
                var ct2 = new CaseType("C", "ZDecoy");
                var ctTarget = new CaseType("B", "Target");

                f.CaseTypes.GetCaseTypesWithDetails().ReturnsForAnyArgs(new[] {ct1, ct2, ctTarget});

                var qParams = new CommonQueryParameters {Skip = 1, Take = 1};
                var r = f.Subject.CaseTypes(qParams);
                var caseTypes = r.Data.OfType<CaseType>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(caseTypes);
                Assert.Equal(ctTarget.Key, caseTypes.Single().Key);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new CaseTypePicklistControllerFixture().Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("CaseTypes").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("CaseType", picklistAttribute.Name);
            }
        }
    }

    public class CaseTypePicklistControllerFixture : IFixture<CaseTypesPicklistController>
    {
        public CaseTypePicklistControllerFixture()
        {
            CaseTypes = Substitute.For<ICaseTypes>();
            CaseTypesPicklistMaintenance = Substitute.For<ICaseTypesPicklistMaintenance>();
            Subject = new CaseTypesPicklistController(CaseTypes, CaseTypesPicklistMaintenance);
        }

        public ICaseTypes CaseTypes { get; set; }

        public ICaseTypesPicklistMaintenance CaseTypesPicklistMaintenance { get; }

        public CaseTypesPicklistController Subject { get; }
    }
}