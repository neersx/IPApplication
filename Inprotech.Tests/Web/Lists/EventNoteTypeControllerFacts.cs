using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Events;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Cases.Validation;
using InprotechKaizen.Model.Configuration.TableMaintenance;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class EventNoteTypeControllerFacts
    {
        public class EventNoteTypeControllerFixture : IFixture<EventNoteTypeController>
        {
            public EventNoteTypeControllerFixture()
            {
                EventNoteTypeValidator = Substitute.For<IEventNoteTypeValidator>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; private set; }
            public IEventNoteTypeValidator EventNoteTypeValidator { get; private set; }
            public ApplicationTask Task { get; set; }

            public dynamic CreateData()
            {
                var eventNoteType1 = new EventNoteType("A Note Type", true).InDb();
                var eventNoteType2 = new EventNoteType("B Note Type", false).InDb();
                var eventNoteType3 = new EventNoteType("C Note Type", true).InDb();

                return new
                {
                    eventNoteType1,
                    eventNoteType2,
                    eventNoteType3
                };
            }

            public EventNoteTypeController Subject
            {
                get
                {
                    return new EventNoteTypeController(
                        InMemoryDbContext.Current,
                        TaskSecurityProvider,
                        EventNoteTypeValidator
                        );
                }
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsEventNoteTypesInAscendingOrderOfDescription()
            {
                var f = new EventNoteTypeControllerFixture();
                var data = f.CreateData();

                var eventNoteType = data.eventNoteType1;
               
                var result = ((IEnumerable<EventNoteType>)f.Subject.GetAll().EntityList).First();

                Assert.Equal(eventNoteType.Description, result.Description);
                Assert.Equal(eventNoteType.IsExternal,  result.IsExternal);
            }

            [Fact]
            public void ReturnsEventNoteTypesWithInsertOnlyPermissionAllowed()
            {
                var f = new EventNoteTypeControllerFixture();
                f.CreateData();

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainEventNoteTypes,
                    ApplicationTaskAccessLevel.Create).Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainEventNoteTypes,
                    ApplicationTaskAccessLevel.Modify).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainEventNoteTypes,
                    ApplicationTaskAccessLevel.Delete).Returns(false);

                var result = f.Subject.GetAll();
                var eventNoteTypes = (IEnumerable<EventNoteType>)result.EntityList;
                var canCreate = result.CanCreate;
                var canUpdate = result.CanUpdate;
                var canDelete = result.CanDelete;

                Assert.True(eventNoteTypes.Any());
                Assert.Equal(true, canCreate);
                Assert.Equal(false, canUpdate);
                Assert.Equal(false, canDelete);
            }
        }

        public class GetByIdMethod : FactBase
        {
            [Fact]
            public void ReturnsEventNoteTypeById()
            {
                var f = new EventNoteTypeControllerFixture();
                var data = f.CreateData();
                var eventNoteType = data.eventNoteType1;

                var result = f.Subject.Get(eventNoteType.Id);

                var t = result.GetType();

                Assert.Equal(eventNoteType.Description, t.GetProperty("Description").GetValue(result, null));
                Assert.Equal(eventNoteType.IsExternal, t.GetProperty("IsExternal").GetValue(result, null));
            }
        }

        public class PutMethod : FactBase
        {
            [Fact]
            public void ThrowsHttpExceptionIfInvalidEventNoteTypeIdIsProvided()
            {
                var f = new EventNoteTypeControllerFixture();

                 var exception =
                    Record.Exception(() => { f.Subject.Put(Fixture.Short(), null); });

                Assert.IsType<HttpException>(exception);
                Assert.Equal("EventNoteType not found.", exception.Message);
            }

            [Fact]
            public void UpdatesExistingEventNoteType()
            {
                var f = new EventNoteTypeControllerFixture();
                var eventNoteType = f.CreateData().eventNoteType2;
                var eventNoteTypeId = (short)eventNoteType.Id;

                eventNoteType.Description = "B Note Type ammend";
                eventNoteType.IsExternal = true;

                var eventNoteTypeOriginal =
                    InMemoryDbContext.Current.Set<EventNoteType>().First(ent => ent.Id == eventNoteTypeId);
                f.EventNoteTypeValidator.ValidateOnPut(eventNoteTypeOriginal, eventNoteTypeOriginal)
                   .Returns(new TableMaintenanceValidationResult { IsValid = true, Status = "success" });

                var result = f.Subject.Put(eventNoteTypeId, eventNoteType);

                Assert.Equal("success", result.Result.Status);
                Assert.Equal("B Note Type ammend", InMemoryDbContext.Current.Set<EventNoteType>().First(ent => ent.Id == eventNoteTypeId).Description);
                Assert.Equal(true, InMemoryDbContext.Current.Set<EventNoteType>().First(ent => ent.Id == eventNoteTypeId).IsExternal);
            }
        }

        public class ValidateOnDeleteMethod : FactBase
        {
            [Fact]
            public void ReturnsTruthyVaidationResultWhenValidateOnDeleteIsInvoked()
            {
                var f = new EventNoteTypeControllerFixture();
                var eventNoteType = f.CreateData().eventNoteType2;
                var eventNoteTypeId = (short)eventNoteType.Id;

                f.EventNoteTypeValidator.ValidateOnDelete(eventNoteTypeId)
                    .Returns(new TableMaintenanceValidationResult {IsValid = true});

                var result = f.Subject.ValidateOnDelete(eventNoteTypeId);

                Assert.Equal(true, result.Result.IsValid);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesExistingEventNoteType()
            {
                var f = new EventNoteTypeControllerFixture();
                var eventNoteType = f.CreateData().eventNoteType2;
                var eventNoteTypeId = (short)eventNoteType.Id;

                f.EventNoteTypeValidator.ValidateOnDelete(eventNoteTypeId)
                    .Returns(new TableMaintenanceValidationResult { IsValid = true });

                var result = f.Subject.Delete(eventNoteTypeId);

                Assert.Equal(true, result.Result.IsValid);
                Assert.False(InMemoryDbContext.Current.Set<EventNoteType>().Any(ent => ent.Id == eventNoteTypeId));
            }
        }

        public class PostMethod : FactBase
        {
            [Fact]
            public void CreatesNewEventNoteType()
            {
                var f = new EventNoteTypeControllerFixture();
                f.CreateData();
                
                var newEventNoteType = new EventNoteType("D Note Type", true) ;

                f.EventNoteTypeValidator.ValidateOnPost(newEventNoteType)
                   .Returns(new TableMaintenanceValidationResult { IsValid = true, Status = "success" });

                var result = f.Subject.Post(newEventNoteType);

                Assert.Equal("success", result.Result.Status);
                Assert.Equal(4, InMemoryDbContext.Current.Set<EventNoteType>().Count());
                Assert.Equal(newEventNoteType.Id, InMemoryDbContext.Current.Set<EventNoteType>().First(ent => ent.Description == newEventNoteType.Description).Id);
            }
        }
        
    }
}
