using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class TaskPicklistControllerFacts : FactBase
    {
        TaskPicklistController CreateSubject(InMemoryDbContext db)
        {
            var preferredCulture = Substitute.For<IPreferredCultureResolver>();
            preferredCulture.Resolve().ReturnsForAnyArgs("en-Us");
            return new TaskPicklistController(preferredCulture, db, Fixture.TodayUtc);
        }
        [Fact]
        public void ShouldReturnSearchWithEmptyResult()
        {
            new SecurityTask { Id = 1, Name = "Name1", Description = "Description" }.In(Db);
            new SecurityTask { Id = 2, Name = "Aim2", Description = "Description2" }.In(Db);
            new SecurityTask { Id = 3, Name = "Zack3", Description = "Description3" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "3", InternalUse = true, ExternalUse = true }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0, ObjectIntegerKey = 1,UpdatePermission = 0 }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0,ObjectIntegerKey = 2,UpdatePermission = 0 }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0, ObjectIntegerKey = 3, UpdatePermission = 0 }.In(Db);
            var subject = CreateSubject(Db);
            var result = subject.Search().Data.ToArray();

            Assert.Equal(3, result.Length);
        }

        [Fact]
        public void ReturnsTakListInAscendingOrderOfName()
        {
            new SecurityTask { Id = 1, Name = "Name1", Description = "Description" }.In(Db);
            new SecurityTask { Id = 2, Name = "Aim2", Description = "Description2" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0, ObjectIntegerKey = 1,UpdatePermission = 0 }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0,ObjectIntegerKey = 2,UpdatePermission = 0 }.In(Db);

            var subject = CreateSubject(Db);
            var result = subject.Search().Data.ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal("Aim2", ((TaskList)result[0]).TaskName);
            Assert.Equal("Name1", ((TaskList)result[1]).TaskName);
        }

        [Fact]
        public void ReturnsPagedResults()
        {
            new SecurityTask { Id = 1, Name = "Case Search", Description = "Description" }.In(Db);
            new SecurityTask { Id = 2, Name = "Name Search", Description = "Description2" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0, ObjectIntegerKey = 1,UpdatePermission = 0 }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0,ObjectIntegerKey = 2,UpdatePermission = 0 }.In(Db);

            var subject = CreateSubject(Db);
            var qParams = new CommonQueryParameters { SortBy = "Description", SortDir = "asc", Skip = 1, Take = 1 };
            var result = subject.Search(qParams);
            var queries = result.Data.ToArray();
            Assert.Equal(2, result.Pagination.Total);
            Assert.Single(queries);
            Assert.Equal("Description2", ((TaskList)queries[0]).Description);
        }

        [Fact]
        public void SearchesForDescription()
        {
            new SecurityTask { Id = 1, Name = "Name1", Description = "Description" }.In(Db);
            new SecurityTask { Id = 2, Name = "Aim2", Description = "Description2" }.In(Db);
            new SecurityTask { Id = 3, Name = "Zack3", Description = "Description3" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "3", InternalUse = true, ExternalUse = true }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0, ObjectIntegerKey = 1,UpdatePermission = 0 }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0,ObjectIntegerKey = 2,UpdatePermission = 0 }.In(Db);
            new PermissionsRuleItem{ DeletePermission = 0, ExecutePermission = 0, InsertPermission = 0, ObjectIntegerKey = 3,UpdatePermission = 0 }.In(Db);
            
            var subject = CreateSubject(Db);
            var result = subject.Search(null, "Description3").Data.ToArray();
            Assert.Equal("Description3", ((TaskList)result[0]).Description);
        }
    }
}