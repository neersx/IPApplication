using System.Linq;
using Inprotech.Web.Maintenance.Topics;
using Inprotech.Web.Names.Maintenance;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Maintenance
{
    public class NameMaintenanceSaveFacts : FactBase
    {
        [Fact]
        public void ShouldSaveRecordForTransaction()
        {
            var fixture = new NameMaintenanceSaveFixture(Db);
            fixture.Subject.Save(null, fixture.DefaultName);

            fixture.TransactionRecordal.Received(1)
                   .RecordTransactionFor(Arg.Any<Name>(),
                                         NameTransactionMessageIdentifier.AmendedName);
        }

        [Fact]
        public void ShouldCallSubmitChanges()
        {
            var fixture = new NameMaintenanceSaveFixture(Db);
            fixture.Subject.Save(null, fixture.DefaultName);

            Db.Received(1).SaveChanges();
        }

        [Fact]
        public void ShouldCallTheUpdater()
        {
            var fixture = new NameMaintenanceSaveFixture(Db);
            fixture.Subject.Save(null, fixture.DefaultName);
            fixture.TopicUpdater.Received(1).Update(null, TopicGroups.Names, Arg.Any<Name>());
        }

        [Fact]
        public void ShouldDoSanityCheckAndReturnSanityResults()
        {
            var fixture = new NameMaintenanceSaveFixture(Db);
            fixture.ExternalDataValidator.Validate(null, Arg.Any<int>(), Arg.Any<int>()).Returns(new[]
            {
                new ValidationResult("there is a huge problem", Severity.Warning).WithDetails(new
                {
                    IsWarning = false, CanOverride = false
                })
            });
            var name = fixture.DefaultName;
            fixture.TransactionRecordal.RecordTransactionFor(Arg.Any<Name>(), Arg.Any<NameTransactionMessageIdentifier>()).Returns(Fixture.Integer());
            var response = fixture.Subject.Save(null, name);

            fixture.ExternalDataValidator.Received(1).Validate(null, name.Id, Arg.Any<int>());
            Assert.Equal(1, response.SanityCheckResults.Count());
            Assert.True(response.SanityCheckResults.Any(v => v.Message == "there is a huge problem"));
        }

        public class NameMaintenanceSaveFixture : IFixture<NameMaintenanceSave>
        {
            public NameMaintenanceSaveFixture(IDbContext db)
            {
                TopicUpdater = Substitute.For<ITopicsUpdater<Name>>();
                TransactionRecordal = Substitute.For<ITransactionRecordal>();
                ExternalDataValidator = Substitute.For<IExternalDataValidator>();
                Subject = new NameMaintenanceSave(db, TransactionRecordal, TopicUpdater, ExternalDataValidator);
            }
            public NameMaintenanceSave Subject { get; }
            public ITopicsUpdater<Name> TopicUpdater { get; set; }
            public ITransactionRecordal TransactionRecordal { get; set; }
            public IExternalDataValidator ExternalDataValidator { get; set; }

            public Name DefaultName
            {
                get
                {
                    var name = new Name(Fixture.Integer());
                    return name;
                }
            }
        }
    }
}
