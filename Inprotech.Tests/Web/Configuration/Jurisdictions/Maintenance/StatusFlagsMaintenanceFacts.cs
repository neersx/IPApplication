using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class MaintenanceFacts
    {
        public const string TopicName = "statusflags";
        const string CountryCode = "AF";
        const string Name1 = "Name";
        const string Name2 = "Name 2";
        const string ProfileName = "Basic Details";

        public class StatusFlagsMaintenanceFixture : IFixture<StatusFlagsMaintenance>
        {
            readonly InMemoryDbContext _db;

            public StatusFlagsMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new StatusFlagsMaintenance(db);
            }

            public StatusFlagsMaintenance Subject { get; set; }

            public void PrepareData()
            {
                var country = new CountryBuilder {Id = CountryCode}.Build().In(_db);
                new CountryFlagBuilder {Country = country, FlagNumber = 1, FlagName = "Designated"}.Build().In(_db);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ShouldGiveDuplicateStatusErrorOnValidate()
            {
                var f = new StatusFlagsMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StatusFlagsMaintenanceModel>();

                delta.Added.Add(new StatusFlagsMaintenanceModel {CountryId = CountryCode, Status = (int) KnownRegistrationStatus.Pending, Name = "Designated"});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Duplicate Designation Stage.");
            }

            [Fact]
            public void ShouldGiveInvalidStatusErrorOnValidate()
            {
                var f = new StatusFlagsMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StatusFlagsMaintenanceModel>();

                delta.Added.Add(new StatusFlagsMaintenanceModel {CountryId = CountryCode, Status = 3, Name = Fixture.String()});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Invalid Status value.");
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryFieldDoesNotProvided()
            {
                var f = new StatusFlagsMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<StatusFlagsMaintenanceModel>();

                delta.Added.Add(new StatusFlagsMaintenanceModel {CountryId = CountryCode, Status = (int) KnownRegistrationStatus.Pending});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field was empty.");
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            [Fact]
            public void ShouldAddStatusFlags()
            {
                var f = new StatusFlagsMaintenanceFixture(Db);
                f.PrepareData();

                var delta = new Delta<StatusFlagsMaintenanceModel>();
                delta.Added.Add(new StatusFlagsMaintenanceModel {CountryId = CountryCode, Status = (int) KnownRegistrationStatus.Pending, Name = Name1, ProfileName = ProfileName});
                delta.Added.Add(new StatusFlagsMaintenanceModel {CountryId = CountryCode, Status = (int) KnownRegistrationStatus.Registered, Name = Name2});
                f.Subject.Save(delta);

                var totalTableStatusFlags = Db.Set<CountryFlag>().Where(_ => _.CountryId == CountryCode).ToList();
                Assert.Equal(3, totalTableStatusFlags.Count);

                var countryStatusFlags = Db.Set<CountryFlag>().First(_ => _.Name == Name1 && _.CountryId == CountryCode && _.ProfileName == ProfileName);

                Assert.Equal(countryStatusFlags.CountryId, CountryCode);
                Assert.Equal(2, countryStatusFlags.FlagNumber);
                Assert.Equal(countryStatusFlags.ProfileName, ProfileName);
                Assert.False(countryStatusFlags.IsNationalPhaseAllowed);
                Assert.False(countryStatusFlags.IsRemovalRestricted);
                Assert.Equal(countryStatusFlags.Status, (int) KnownRegistrationStatus.Pending);

                countryStatusFlags = Db.Set<CountryFlag>().First(_ => _.Name == Name2 && _.CountryId == CountryCode);

                Assert.Equal(4, countryStatusFlags.FlagNumber);
            }

            [Fact]
            public void ShouldDeleteExistingStatusFlags()
            {
                var f = new StatusFlagsMaintenanceFixture(Db);
                f.PrepareData();

                var delta = new Delta<StatusFlagsMaintenanceModel>();
                delta.Deleted.Add(new StatusFlagsMaintenanceModel {Id = 1, CountryId = CountryCode});
                f.Subject.Save(delta);

                var totalTableStatusFlags = Db.Set<CountryFlag>().ToList();
                Assert.Empty(totalTableStatusFlags);
            }

            [Fact]
            public void ShouldUpdateStatusFlags()
            {
                var f = new StatusFlagsMaintenanceFixture(Db);
                f.PrepareData();

                var delta = new Delta<StatusFlagsMaintenanceModel>();
                delta.Updated.Add(new StatusFlagsMaintenanceModel
                {
                    Id = 1,
                    CountryId = CountryCode,
                    Status = (int) KnownRegistrationStatus.Dead,
                    Name = "Updated Name",
                    ProfileName = "Updated Profile",
                    AllowNationalPhase = true,
                    RestrictRemoval = true
                });
                f.Subject.Save(delta);

                var statusFlags = Db.Set<CountryFlag>().First(_ => _.FlagNumber == 1 && _.CountryId == CountryCode);
                Assert.NotNull(statusFlags);
                Assert.Equal(1, statusFlags.FlagNumber);
                Assert.Equal("Updated Name", statusFlags.Name);
                Assert.Equal("Updated Profile", statusFlags.ProfileName);
                Assert.True(statusFlags.IsNationalPhaseAllowed);
                Assert.True(statusFlags.IsRemovalRestricted);
                Assert.Equal(statusFlags.Status, (int) KnownRegistrationStatus.Dead);
            }
        }
    }
}