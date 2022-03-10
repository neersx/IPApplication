using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using CaseListPickListModel = Inprotech.Web.Picklists.CaseList;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseListsPicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseListsContainingMatchingName()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                var caseList1 = new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() };
                var caseLists = new List<CaseList>
                {
                    caseList1,
                    new CaseList() {Key = Fixture.Integer(), Value = Fixture.String()}
                };
                f.CaseListMaintenance.GetCaseLists().Returns(caseLists);
                var r = f.Subject.Get(null, caseList1.Value);
                var result = r.Data.OfType<CaseListPickListModel>().ToArray();

                Assert.Single(result);
                Assert.Equal(caseList1.Key, result.First().Key);
                Assert.Equal(caseList1.Value, result.First().Value);
            }

            [Fact]
            public void ReturnsAllCaseLists()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                var caseListFirst = new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() };
                var caseListLast = new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() };
                var caseLists = new List<CaseList>
                {
                    caseListFirst,
                    new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() },
                    new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() },
                    new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() },
                    new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() },
                    caseListLast,
                };
                f.CaseListMaintenance.GetCaseLists().Returns(caseLists);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute).Returns(true);
                var queryParam = new CommonQueryParameters() { Take = 5 };
                var r = f.Subject.Get(queryParam, null, "maintenance");
                var result = r.Data.OfType<CaseListPickListModel>().ToArray();

                Assert.Equal(6, result.Length);
                Assert.Equal(caseListFirst.Key, result.First().Key);
                Assert.Equal(caseListFirst.Value, result.First().Value);
                Assert.Equal(caseListLast.Key, result.Last().Key);
                Assert.Equal(caseListLast.Value, result.Last().Value);
            }

            [Fact]
            public void ThrowsErrorForUserDoesNotHavingMaintainCaseList()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute).Returns(false);
                Assert.Throws<HttpResponseException>(() => f.Subject.Get(null, null, "maintenance"));
            }

            [Fact]
            public void ThrowsErrorForExternalUsers()
            {
                var f = new CaseListsPicklistControllerFixture(Db, true);
                Assert.Throws<HttpResponseException>(() => f.Subject.Get());
            }
        }

        public class MetadataMethod : FactBase
        {
            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new CaseListsPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Metadata").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("CaseList", picklistAttribute.Name);
            }
        }

        public class CaseListMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseListById()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                var caseList1 = new CaseList() { Key = Fixture.Integer(), Value = Fixture.String() };

                f.CaseListMaintenance.GetCaseList(Arg.Any<int>()).Returns(caseList1);
                var r = f.Subject.CaseList(caseList1.Key);

                Assert.NotNull(r);
                Assert.Equal(caseList1.Key, r.Key);
                Assert.Equal(caseList1.Value, r.Value);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ReturnsSuccessMethod()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                var caseList1 = new CaseList() { Value = Fixture.String() };
                f.CaseListMaintenance.Save(Arg.Any<CaseList>()).Returns(new { Result = "success" });
                var r = f.Subject.Save(caseList1);

                Assert.NotNull(r);
                Assert.Equal("success", r.Result);
            }
        }
        public class ViewDataMethod : FactBase
        {
            [Fact]
            public void GetViewDataMethod()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Create).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Modify).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Delete).Returns(false);
                var r = f.Subject.GetViewData();

                Assert.NotNull(r);
                Assert.True(r.Permissions.CanInsertCaseList);
                Assert.True(r.Permissions.CanUpdateCaseList);
                Assert.False(r.Permissions.CanDeleteCaseList);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ReturnsSuccessMethod()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                var caseList1 = new CaseList() { Value = Fixture.String(), Key = Fixture.Integer() };
                f.CaseListMaintenance.Update(Arg.Any<int>(), Arg.Any<CaseList>()).Returns(new { Result = "success" });
                var r = f.Subject.Update(caseList1.Key, caseList1);

                Assert.NotNull(r);
                Assert.Equal("success", r.Result);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ReturnsSuccess()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                f.CaseListMaintenance.Delete(Arg.Any<int>()).Returns(new { Result = "success" });
                var r = f.Subject.Delete(Fixture.Integer());

                Assert.NotNull(r);
                Assert.Equal("success", r.Result);
            }

            [Fact]
            public void ValidateDeleteListMethod()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                f.CaseListMaintenance.Delete(Arg.Any<List<int>>()).Returns(new { Result = "success" });
                var r = f.Subject.DeleteList(new List<int>() { 2, 5 });

                Assert.NotNull(r);
                Assert.Equal("success", r.Result);
            }
        }

        public class GetCaseListItemsMethod : FactBase
        {
            [Fact]
            public void ReturnsListOfCaseListItems()
            {
                var f = new CaseListsPicklistControllerFixture(Db);
                var caseListItemRequest = new CaseListItemRequest()
                {
                    CaseKeys = new int[2],
                    PrimeCaseKey = Fixture.Integer()
                };
                var caseListItems = new List<CaseListItem>
                {
                    new CaseListItem() {CaseKey = Fixture.Integer(), CaseRef = Fixture.String()},
                    new CaseListItem() {CaseKey = Fixture.Integer(), CaseRef = Fixture.String()}
                };
                f.CaseListMaintenance.GetCases(caseListItemRequest.CaseKeys, caseListItemRequest.PrimeCaseKey, Arg.Any<List<int>>()).Returns(caseListItems);

                var r = f.Subject.GetCaseListItems(caseListItemRequest);
                Assert.NotNull(r);
                Assert.Equal(2, r.Data.Count());
            }

            [Fact]
            public void ThrowsErrorForExternalUsers()
            {
                var f = new CaseListsPicklistControllerFixture(Db, true);
                Assert.Throws<HttpResponseException>(() => f.Subject.GetCaseListItems(null));
            }
        }
    }

    public class CaseListsPicklistControllerFixture : IFixture<CaseListsPicklistController>
    {

        public CaseListsPicklistControllerFixture(InMemoryDbContext db, bool forExternal = false)
        {
            SecurityContext = Substitute.For<ISecurityContext>();

            CaseListMaintenance = Substitute.For<ICaseListMaintenance>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            SecurityContext.User.Returns(new UserBuilder(db) { IsExternalUser = forExternal }.Build());
            Subject = new CaseListsPicklistController(SecurityContext, CaseListMaintenance, TaskSecurityProvider);
        }

        public ICaseListMaintenance CaseListMaintenance { get; set; }

        public ISecurityContext SecurityContext { get; set; }

        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public CaseListsPicklistController Subject { get; }
    }
}