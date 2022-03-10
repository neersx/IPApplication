using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration;
using InprotechKaizen.Model.Components.Configuration.TableMaintenance;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration
{
    public class TableMaintenanceEntity : ITableMaintenanceEntity<short>
    {
        public TableMaintenanceEntity()
        {
        }

        public TableMaintenanceEntity(string description, bool isExternal)
        {
            Description = description;
            IsExternal = isExternal;
        }

        public string Description { get; set; }

        public bool IsExternal { get; set; }

        public short Id { get; set; }
    }

    public class TableMaintenanceControllerFacts
    {
        public class TableMaintenanceControllerFixture : IFixture<TableMaintenanceController<TableMaintenanceEntity, short>>
        {
            readonly InMemoryDbContext _db;

            public TableMaintenanceControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                TableMaintenanceValidator = Substitute.For<ITableMaintenanceValidator<short>>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public ITableMaintenanceValidator<short> TableMaintenanceValidator { get; }
            public ApplicationTask Task { get; set; }

            public TableMaintenanceController<TableMaintenanceEntity, short> Subject => new TableMaintenanceController<TableMaintenanceEntity, short>(
                                                                                                                                                      _db,
                                                                                                                                                      TaskSecurityProvider,
                                                                                                                                                      ApplicationTask.NotDefined,
                                                                                                                                                      TableMaintenanceValidator);

            public dynamic CreateData()
            {
                var tableMaintenance1 = new TableMaintenanceEntity("A Table Maintenance", true).In(_db);
                var tableMaintenance2 = new TableMaintenanceEntity("B Table Maintenance", false).In(_db);

                return new
                {
                    TableMaintenance1 = tableMaintenance1,
                    TableMaintenance2 = tableMaintenance2
                };
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsTableMaintenanceEntities()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                f.CreateData();
                var result = (IEnumerable<TableMaintenanceEntity>) f.Subject.GetAll().EntityList;

                Assert.Equal(2, result.Count());
            }

            [Fact]
            public void ReturnsTableMaintenancesWithInsertOnlyPermissionAllowed()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                f.CreateData();

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.NotDefined,
                                                   ApplicationTaskAccessLevel.Create).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.NotDefined,
                                                   ApplicationTaskAccessLevel.Modify).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.NotDefined,
                                                   ApplicationTaskAccessLevel.Delete).Returns(false);

                var result = f.Subject.GetAll();
                var tableMaintenances = (IEnumerable<TableMaintenanceEntity>) result.EntityList;
                var canCreate = result.CanCreate;
                var canUpdate = result.CanUpdate;
                var canDelete = result.CanDelete;

                Assert.True(tableMaintenances.Any());
                Assert.Equal(true, canCreate);
                Assert.Equal(false, canUpdate);
                Assert.Equal(false, canDelete);
            }
        }

        public class GetByIdMethod : FactBase
        {
            [Fact]
            public void ReturnsTableMaintenanceById()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                var data = f.CreateData();
                var tableMaintenance = data.TableMaintenance1;

                var result = f.Subject.Get(tableMaintenance.Id);

                var t = result.GetType();

                Assert.Equal(tableMaintenance.Description, t.GetProperty("Description").GetValue(result, null));
                Assert.Equal(tableMaintenance.IsExternal, t.GetProperty("IsExternal").GetValue(result, null));
            }
        }

        public class ColumnDefinitionMethod : FactBase
        {
            [Fact]
            public void ReturnsAnEmptyListOfTableMaintenance()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                var result = f.Subject.ColumnDefinitions();
                Assert.Empty(result);
            }
        }

        public class PutMethod : FactBase
        {
            [Fact]
            public void ThrowsHttpExceptionIfInvalidTableMaintenanceIdIsProvided()
            {
                var f = new TableMaintenanceControllerFixture(Db);

                var exception =
                    Record.Exception(() => { f.Subject.Put(Fixture.Short(), null); });

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void UpdatesExistingTableMaintenance()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                var tableMaintenance = f.CreateData().TableMaintenance2;
                var tableMaintenanceId = (short) tableMaintenance.Id;

                tableMaintenance.Description = "B Table Maintenance ammend";
                tableMaintenance.IsExternal = true;

                var tableMaintenanceOriginal =
                    Db.Set<TableMaintenanceEntity>().First(ent => ent.Id == tableMaintenanceId);
                f.TableMaintenanceValidator.ValidateOnPut(tableMaintenanceOriginal, tableMaintenanceOriginal)
                 .Returns(new TableMaintenanceValidationResult {IsValid = true, Status = "success"});

                var result = f.Subject.Put(tableMaintenanceId, tableMaintenance);

                Assert.Equal("success", result.Result.Status);
                Assert.Equal("B Table Maintenance ammend", Db.Set<TableMaintenanceEntity>().First(ent => ent.Id == tableMaintenanceId).Description);
                Assert.True(Db.Set<TableMaintenanceEntity>().First(ent => ent.Id == tableMaintenanceId).IsExternal);
            }
        }

        public class ValidateOnDeleteMethod : FactBase
        {
            [Fact]
            public void ReturnsTruthyVaidationResultWhenValidateOnDeleteIsInvoked()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                var tableMaintenance = f.CreateData().TableMaintenance2;
                var tableMaintenanceId = (short) tableMaintenance.Id;

                f.TableMaintenanceValidator.ValidateOnDelete(tableMaintenanceId)
                 .Returns(new TableMaintenanceValidationResult {IsValid = true});

                var result = f.Subject.ValidateOnDelete(tableMaintenanceId);

                Assert.Equal(true, result.Result.IsValid);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesExistingTableMaintenance()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                var tableMaintenance = f.CreateData().TableMaintenance2;
                var tableMaintenanceId = (short) tableMaintenance.Id;

                f.TableMaintenanceValidator.ValidateOnDelete(tableMaintenanceId)
                 .Returns(new TableMaintenanceValidationResult {IsValid = true});

                var result = f.Subject.Delete(tableMaintenanceId);

                Assert.Equal(true, result.Result.IsValid);
                Assert.False(Db.Set<TableMaintenanceEntity>().Any(ent => ent.Id == tableMaintenanceId));
            }
        }

        public class PostMethod : FactBase
        {
            [Fact]
            public void CreatesNewTableMaintenance()
            {
                var f = new TableMaintenanceControllerFixture(Db);
                f.CreateData();

                var newTableMaintenance = new TableMaintenanceEntity("D Table Maintenance", true);

                f.TableMaintenanceValidator.ValidateOnPost(newTableMaintenance)
                 .Returns(new TableMaintenanceValidationResult {IsValid = true, Status = "success"});

                var result = f.Subject.Post(newTableMaintenance);

                Assert.Equal("success", result.Result.Status);
                Assert.Equal(3, Db.Set<TableMaintenanceEntity>().Count());

                var addedEntity =
                    Db.Set<TableMaintenanceEntity>()
                      .First(ent => ent.Description == newTableMaintenance.Description);
                Assert.Equal(newTableMaintenance.Id, addedEntity.Id);

                var tableMaintenanceEntity = result.Entity as TableMaintenanceEntity;
                if (tableMaintenanceEntity != null)
                {
                    Assert.Equal(addedEntity.Id, tableMaintenanceEntity.Id);
                }
            }
        }
    }
}